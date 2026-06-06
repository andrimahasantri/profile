# Deployment (Docker + Caddy)

Arsitektur: satu reverse proxy **Caddy** (auto-HTTPS) di depan, tiap project jadi
container di belakang, dirouting berdasarkan domain. Database/komunikasi internal
tidak pernah terekspos ke internet.

```
Internet :80/:443 ──> Caddy ──┬─ influencespeakpro.com      -> profile  (Astro SSR :4321)
                              ├─ app.influencespeakpro.com  -> lms-frontend (Next.js :3000)  [nanti]
                              └─ api.influencespeakpro.com  -> lms-backend  (Go :8080)        [nanti]
```

## Struktur di VPS

```
/srv/
├── edge/        # isi dari deploy/edge/ (Caddyfile + docker-compose.yml)
├── profile/     # repo ini
└── lms/         # nanti
```

## Prasyarat (sekali saja)

```bash
# Docker + plugin compose harus terpasang
docker --version && docker compose version

# Network bersama untuk komunikasi Caddy <-> app
docker network create edge

# Firewall: hanya SSH + HTTP + HTTPS
sudo ufw allow 22 && sudo ufw allow 80 && sudo ufw allow 443 && sudo ufw enable
```

## DNS (pastikan benar sebelum deploy Caddy)

| Host | Tipe | Nilai |
|------|------|-------|
| influencespeakpro.com     | A     | 103.55.38.219 |
| www.influencespeakpro.com | CNAME | influencespeakpro.com |

> Pastikan TIDAK ada A record `@` ganda. Domain ini sempat punya record bawaan
> `103.15.226.115` (server parkir cloudhost) yang membuat certbot gagal — hapus.

> Pakai Cloudflare? Set **DNS only (abu-abu)** sampai cert terbit, atau mode **Full (strict)**. Jangan "Flexible".

## Deploy web profile

```bash
cd /srv/profile
cp env.txt .env        # lalu isi secret asli (SLACK_TOKEN, MAILCHIMP_*, dll)
docker compose up -d --build
```

## Deploy edge proxy (Caddy)

```bash
cd /srv/edge
docker compose up -d
docker compose logs -f caddy   # tunggu Caddy ambil sertifikat otomatis
```

Selesai. `https://influencespeakpro.com` aktif dengan TLS valid, perpanjang otomatis.

## Update / redeploy

```bash
cd /srv/profile && git pull && docker compose up -d --build
```

## Catatan env

- **Secret** (SLACK_TOKEN, MAILCHIMP_*, POSTMARK/MAILGUN, dll) dibaca **saat runtime**
  oleh API routes — taruh di `.env` (lihat `env.txt` sebagai contoh). `.env` di-ignore git.
- **Variabel konfigurasi build** (WEBSITE_LANGUAGE, CURRENCY, BLOG_SLUG,
  NEWSLETTER_PROVIDER) punya default wajar; set hanya jika ingin override (saat build).
