● Empat pertanyaan bagus — ini hal-hal fundamental yang penting Anda pahami. Saya jawab satu per satu.

  ---
  1. master vs coba-coba — itu branch siapa?

  Keduanya adalah branch di dalam repo Anda sendiri (andrimahasantri/profile.git), bukan punya pemilik open-source
  aslinya.

  Yang perlu dipahami: satu repo bisa punya banyak branch, dan branch yang sama ada di 3 lokasi:

  ┌─────────────────────────┬─────────────────────┐
  │         Lokasi          │     Keterangan      │
  ├─────────────────────────┼─────────────────────┤
  │ Local (Windows/laragon) │ Repo kerja Anda     │
  ├─────────────────────────┼─────────────────────┤
  │ origin (GitHub)         │ Repo pusat di cloud │
  ├─────────────────────────┼─────────────────────┤
  │ Server (/srv/profile)   │ Hasil clone di VPS  │
  └─────────────────────────┴─────────────────────┘

  - master = branch default. Isinya kode template asli StarFunnel apa adanya (commit terakhir caf3766). Tidak ada
  perubahan kita di sini.
  - coba-coba = branch tempat semua pekerjaan kita (rebrand + Docker) ditumpuk.

  Masalah kemarin: working copy di server sedang "berdiri" di branch master. Jadi waktu Anda git pull, yang
  ditarik isi master (kode lama, tanpa Docker/adapter Node) → makanya file tidak cocok. Bukan soal pemilik
  open-source — murni server-nya kebetulan di-checkout ke branch yang salah.

  ▎ Repo open-source aslinya (unfolding-io/StarFunnel) itu remote yang berbeda dan tidak terhubung ke alur deploy
  ▎ Anda. Anda sudah punya fork sendiri.

  Saran: nanti merge coba-coba → master, lalu deploy server dari master saja, supaya tidak ada lagi kebingungan
  branch.

  ---
  2. Kenapa Dockerfile ada di .dockerignore tapi tetap bisa push/pull?

  Karena .dockerignore dan .gitignore itu dua hal yang sama sekali berbeda dan tidak saling memengaruhi:

  ┌───────────────┬─────────────────────────────────────────┬─────────────────────────────────────────────────┐
  │     File      │                Mengatur                 │              Efek pada Dockerfile               │
  ├───────────────┼─────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ .gitignore    │ Apa yang di-track Git (push/pull)       │ Dockerfile TIDAK ada di .gitignore → di-track   │
  │               │                                         │ Git → bisa push & pull normal ✅                │
  ├───────────────┼─────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ .dockerignore │ Apa yang dikirim ke proses build Docker │ Dockerfile ada di .dockerignore → tidak ikut    │
  │               │  (di-COPY ke dalam image)               │ di-COPY ke dalam image                          │
  └───────────────┴─────────────────────────────────────────┴─────────────────────────────────────────────────┘

  Jadi Dockerfile itu:
  - Dikelola Git (versinya ikut commit, push, pull) ✅ — makanya perubahan saya sampai ke server lewat git.
  - Dikecualikan dari build context — karena image hasil jadi tidak butuh Dockerfile di dalamnya (Dockerfile cuma
  "resep", tidak perlu ikut masuk ke "masakan").

  .dockerignore tidak ada hubungannya dengan .git atau dengan push/pull. Anggapan "file di-dockerignore harus
  diubah langsung di server" itu keliru — yang menentukan sinkronisasi server adalah Git (.gitignore), bukan
  .dockerignore.

  ---
  3. Image yang gagal kemarin — jadi sampah menumpuk?

  Ya, dan kekhawatiran Anda benar. Setiap build (apalagi --no-cache) meninggalkan:
  - Dangling images (<none>:<none>) — layer image lama yang sudah tergantikan.
  - Build cache — bisa besar (project ini ~500MB+ per build).
  - Container berhenti, volume/network tak terpakai.

  Cek dulu pemakaiannya:

  docker system df          # ringkasan: images, containers, build cache, volumes
  docker images -f dangling=true   # lihat image <none> yang nyampah

  Bersihkan dengan aman (tidak menyentuh yang sedang dipakai container hidup):

  docker image prune -f         # hapus dangling images
  docker builder prune -f       # hapus build cache lama

  Atau sekaligus (lebih agresif, tetap aman selama profile & caddy berjalan):

  docker system prune -f        # hapus image/container/network tak terpakai

  ▎ ⚠️  Jangan pakai docker system prune -a --volumes sembarangan — flag --volumes bisa menghapus volume caddy_data
  ▎ (berisi sertifikat TLS Anda) kalau suatu saat container caddy mati. Untuk pembersihan rutin, cukup docker
  ▎ image prune -f + docker builder prune -f.

  Saran: jalankan pembersihan ini sesekali setelah beberapa kali redeploy.

  ---
  4. Kalau ubah project profile — build ulang Caddy juga?

  Tidak. Cukup image profile saja. Caddy & profile itu independen.

  cd /srv/profile
  git pull
  docker compose up -d --build      # rebuild + ganti container profile saja

  Caddy tidak perlu disentuh. Caddy merutekan berdasarkan nama service (reverse_proxy profile:4321), bukan IP.
  Saat container profile dibuat ulang, DNS internal Docker otomatis mengarahkan ke container baru — Caddy
  menyambung lagi sendiri. (Ada jeda beberapa detik downtime saat container diganti — wajar.)

  Kapan Caddy perlu di-reload? Hanya kalau Anda mengubah Caddyfile (mis. menambah subdomain app./api. untuk LMS):

  cd /srv/edge
  docker compose up -d              # menerapkan Caddyfile baru (reload tanpa putus)

  Ringkasnya:

  ┌────────────────────────────┬─────────────────────────────┐
  │        Yang diubah         │   Yang di-rebuild/reload    │
  ├────────────────────────────┼─────────────────────────────┤
  │ Kode/konten profile        │ profile saja (/srv/profile) │
  ├────────────────────────────┼─────────────────────────────┤
  │ Kode LMS nanti             │ lms saja (/srv/lms)         │
  ├────────────────────────────┼─────────────────────────────┤
  │ Caddyfile (routing/domain) │ caddy saja (/srv/edge)      │
  └────────────────────────────┴─────────────────────────────┘

  ▎ Catatan kecil: kalau suatu saat setelah redeploy profile Anda lihat 502 Bad Gateway sesaat, jalankan docker
  ▎ compose restart caddy untuk memaksa Caddy resolve ulang DNS. Jarang terjadi, tapi bagus untuk diketahui.

  ---
  Semua pertanyaan Anda mengarah ke pemahaman yang tepat — ini fondasi penting sebelum LMS. Kalau nanti masuk
  tahap LMS (Go + Postgres + Next.js), tinggal kabari, saya bantu susun struktur /srv/lms/-nya. Ada lagi yang
  ingin diperjelas?


  =========================
  🔧 Yang masih perlu Anda lengkapi (belum fungsional penuh)

  1. Secret form kontak/newsletter — cp env.txt .env di /srv/profile, isi SLACK_TOKEN, MAILCHIMP_*, dll, lalu
  docker compose up -d ulang. Sebelum ini, form kontak & newsletter belum berfungsi.
  2. Aset brand — logo (public/logo.svg), favicon, og-image (src/assets/og_image_starfunnel.jpg), dan video/foto
  hero masih bawaan template.
  3. Info kontak asli — email/telepon/sosmed di src/content/config/contact.mdx masih placeholder (+62
  812-0000-0000, dll).
  4. MX record — masih mengarah ke VPS; email ke @influencespeakpro.com akan bounce. Abaikan kalau belum butuh
  email domain.

  ==========================
    📌 Keputusan kecil untuk nanti

  - Branch deploy: sekarang server di coba-coba. Kalau mau rapi ala production, merge coba-coba → master dan
  deploy dari master. Saya bisa bantu siapkan PR/merge-nya.

  🚀 Saat siap garap LMS

  Tinggal ikuti pola yang sama: stack /srv/lms/ (Go + Postgres + Next.js), Postgres di network privat (tanpa edge,
  tanpa publish port), lalu buka komentar blok app. & api. di Caddyfile. Kerangkanya sudah saya catat di
  deploy/README.md dan memori project.