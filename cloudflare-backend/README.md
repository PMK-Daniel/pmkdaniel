# Backend PMK Daniel FILKOM UB (Cloudflare Workers + D1 + R2) ⚡☁️

Backend REST API 100% serverless yang berjalan di atas **Cloudflare Edge Infrastructure**. Bebas biaya, aktif 24 jam nonstop tanpa perlu laptop menyala, dan tidak membutuhkan server Python terpisah.

---

## 🛠️ Arsitektur & Teknologi

* **Runtime:** Cloudflare Workers (V8 Edge Runtime)
* **Framework:** [Hono.js](https://hono.dev/) (Fast, lightweight, native Web Standards)
* **Database:** Cloudflare D1 (Serverless SQLite global)
* **Storage:** Cloudflare R2 (S3-compatible Object Storage)
* **Auth:** JSON Web Token (JWT) + Web Crypto SHA-256

---

## 🚀 Panduan Deploy ke Cloudflare (Hanya Sekali)

### 1. Login ke Cloudflare
Buka terminal di folder `cloudflare-backend` dan jalankan:
```bash
cd cloudflare-backend
npx wrangler login
```
*(Browser akan terbuka untuk konfirmasi login ke akun Cloudflare Anda).*

### 2. Buat Database D1 di Cloudflare
Jalankan perintah:
```bash
npx wrangler d1 create pmkdaniel-db
```
Salin `database_id` yang muncul di terminal, lalu buka file `wrangler.jsonc` dan masukkan `database_id` tersebut ke bagian:
```jsonc
"d1_databases": [
  {
    "binding": "DB",
    "database_name": "pmkdaniel-db",
    "database_id": "MASUKKAN_DATABASE_ID_DISINI"
  }
]
```

### 3. Jalankan Migrasi Skema & Seed Data ke Cloudflare D1
Jalankan:
```bash
npx wrangler d1 execute pmkdaniel-db --remote --file=./schema.sql
npx wrangler d1 execute pmkdaniel-db --remote --file=./seed.sql
```

### 4. Deploy Worker ke Cloudflare
Jalankan:
```bash
npx wrangler deploy
```
Setelah proses deploy selesai, Anda akan mendapatkan URL publik, contohnya:
`https://pmkdaniel-api.<subdomain-anda>.workers.dev`

---

## 🔗 Menghubungkan ke Frontend (Next.js)

Setelah Worker berhasil di-deploy:
1. Buka file `.env.local` di folder `pmkdaniel`:
```env
NEXT_PUBLIC_API_URL=https://pmkdaniel-api.<subdomain-anda>.workers.dev/api
NEXT_PUBLIC_BACKEND_URL=https://pmkdaniel-api.<subdomain-anda>.workers.dev
```
2. Jika frontend Anda di-deploy di **Cloudflare Pages / Vercel**, tambahkan Environment Variable `NEXT_PUBLIC_API_URL` dengan nilai URL Worker di atas pada dashboard Cloudflare Pages / Vercel, lalu re-deploy frontend.

---

## 🔑 Kredensial Admin Default

* **Username:** `admin`
* **Password:** `admin123`

---

## 💻 Menjalankan Secara Lokal (Development)

Untuk pengembangan lokal:
```bash
# Inisialisasi database lokal
npm run d1:init

# Jalankan server lokal di port 8787 atau 8000
npm run dev
```
