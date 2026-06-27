# Landing Page Iklan — `/landing-page`

Landing page **statis, mobile-first** untuk kebutuhan iklan (paid traffic) tim
marketing. Berdiri sendiri, terpisah dari tema/CMS situs utama.

- **URL:** `http://localhost:4321/landing-page` (dev) → `/landing-page` (produksi)
- **Tidak ada di menu/navigasi** (sengaja — khusus tujuan iklan).
- **Tidak diedit lewat CMS/admin** — konten di-hardcode di file (cepat & independen).

## File terkait

| File | Peran |
|------|-------|
| `src/pages/landing-page.astro` | Halaman landing (konten + section + style scoped) |
| `src/layouts/LandingLayout.astro` | Layout terisolasi (head, frame mobile, palet warna) |
| `assets/` | Sumber gambar (di-import oleh halaman; silakan diganti) |

## Keputusan arsitektur

1. **Route + layout terisolasi.** Tidak memakai `BaseLayout` (yang membawa
   Header/nav, Footer, dialog, dependensi CMS). `LandingLayout` hanya berisi
   `<head>` minimal + frame. → independen dari tema, otomatis tak masuk menu,
   aman saat situs/CMS berubah.
2. **Statis (`export const prerender = true`).** Di-render jadi HTML murni saat
   build → tercepat untuk iklan, mudah di-CDN/cache.
3. **Styling self-contained.** Palet hijau-teal didefinisikan sendiri di
   `LandingLayout` + utilitas Tailwind; **tidak** mengimpor `src/styles/global.css`
   tema. → bisa direstyle per kampanye tanpa mengganggu situs.
4. **Mobile-first terkunci.** Konten dibungkus frame `max-width: 480px` di tengah
   (`.landing-frame`). Di desktop tampil seperti mobile (kolom sempit, latar gelap
   di sisinya).
5. **`<meta name="robots" content="noindex, nofollow">`.** Khusus iklan, tidak
   diindeks mesin pencari / tidak bersaing dengan situs utama.
6. **Gambar via `import`** dari `assets/` → mudah diganti (timpa file nama sama).

## Struktur section (urut atas → bawah)

Hero → Masalah → Benefit (checklist) → Meet Our Coach → Our Clients →
Webinar Info → Pricing (Basic & Premium) → **FAQ** (accordion) → Form pendaftaran
+ tombol WhatsApp → Footer (teks copyright).

## Cara kustomisasi

### Teks, harga, tanggal, benefit, FAQ
Edit langsung di **frontmatter** `src/pages/landing-page.astro`:
- `benefits`, `basic`, `premium`, `clients`, `faqs` (array).
- Tanggal di Hero (`SABTU, 5 JULI · 19.00 WIB`), harga (`Rp149.000` / `Rp349.000`),
  nama coach (`Nama Coach`) → edit di markup.

### Gambar (akan diganti tim)
Gambar di-`import` lalu dipakai via `<Image src={...}>`. Saat ini memakai
`assets/mark1.jpeg` & `assets/mark2.jpeg` sebagai placeholder.
- **Ganti cepat:** timpa file di `assets/` dengan nama sama.
- **Ganti ke file baru:** tambahkan import lalu pakai variabelnya.

> ⚠️ **ATURAN PENTING — komponen `<Image>`:** `src` HARUS gambar hasil `import`
> (objek `ImageMetadata`), **bukan string path**.
>
> ```astro
> // ✅ BENAR
> import hero from "../../assets/hero.jpg";
> <Image src={hero} alt="..." widths={[480]} sizes="480px" />
>
> // ❌ SALAH → error "LocalImageUsedWrongly"
> <Image src="../../assets/hero.jpg" ... />
> ```
> Untuk logo/PNG transparan, pakai `object-contain` (bukan `object-cover`) agar
> tidak terpotong.

### Logo "Our Clients"
Saat ini grid **teks** placeholder (`clients = ["Brand A", ...]`). Untuk memakai
logo gambar:
```astro
// frontmatter
import logoX from "../../assets/X.png";
const clientLogos = [{ src: logoX, alt: "X" }];
```
```astro
// markup section Our Clients
{clientLogos.map((logo) => (
  <div class="grid h-14 place-items-center rounded-lg bg-white/90 p-2">
    <Image src={logo.src} alt={logo.alt} widths={[120]} sizes="120px"
           class="max-h-full w-auto object-contain" />
  </div>
))}
```

### WhatsApp & form pendaftaran
- Nomor WA: ubah konstанta `WA` di frontmatter (`https://wa.me/62...`).
- Form saat ini **statis** (`action="#"`). Untuk menangkap lead, arahkan `action`
  ke endpoint CRM / Google Apps Script / form service, atau andalkan tombol
  "Daftar via WhatsApp".

## Menjalankan & build

```bash
npm run dev      # http://localhost:4321/landing-page
npm run build    # render statis → output adapter (Vercel/Netlify/Node)
```

## Riwayat perubahan

- **2026-06-27**
  - Halaman `/landing-page` + `LandingLayout` dibuat (arsitektur terisolasi,
    mobile-first, prerender statis, noindex).
  - Section: Hero, Masalah, Benefit, Coach, Our Clients, Webinar Info, Pricing,
    Form + WhatsApp, Footer.
  - Ditambah section **FAQ** (accordion `<details>` native, tanpa JS).
  - Sempat uji logo `VISA-logo.png` → **di-rollback** (desain teks lebih rapi).
  - **Logo footer dihapus** → footer hanya teks copyright.
