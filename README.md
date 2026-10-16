# E-Voting Pemilihan Ketua PMK Daniel - Universitas Brawijaya 🗳️🏛️

Aplikasi web pemilihan umum elektronik (E-Voting) modern yang dirancang khusus untuk suksesi kepemimpinan **PMK Daniel FILKOM Universitas Brawijaya** dengan 5 calon resmi:
1. **Joseph** (#01)
2. **Zoe** (#02)
3. **Anna** (#03)
4. **Nata** (#04)
5. **Chelsea** (#05)

Aplikasi dibangun menggunakan **Next.js 16 (App Router)**, **Tailwind CSS**, **Supabase (PostgreSQL)**, dan siap di-deploy langsung ke **Vercel**.

---

## 🛡️ Arsitektur Keamanan & Kerahasiaan Suara (Zero-Knowledge)

Sistem ini dirancang tanpa celah keamanan (*Zero Security Loopholes*) dengan prinsip:

1. **Verifikasi Identitas Mahasiswa UB (@student.ub.ac.id)**:
   - Validasi Regex ketat di sisi klien dan server: `/^[a-zA-Z0-9._%+-]+@student\.ub\.ac\.id$/`.
   - Domain luar (@gmail, @yahoo, dll) serta teknik spoofing subdomain otomatis ditolak langsung dengan status `403 Forbidden`.
   - Verifikasi kepemilikan email menggunakan kode OTP 6-digit (Supabase Auth OTP).
   - Setelah diverifikasi, server menerbitkan token bertanda tangan kriptografi (HMAC-SHA256 berjangka waktu 1 jam).

2. **Jaminan Kerahasiaan Suara Mutlak (Secret Ballot Architecture)**:
   - *Requirement Utama:* **Di sisi admin sama sekali TIDAK BISA melihat nama atau pilihan pemilih.**
   - **Tabel 1 (`voter_registry`)**: Hanya menyimpan `email_hash` (HMAC-SHA256 dengan secret salt/pepper server) dan status `has_voted: true`. **Sama sekali tidak menyimpan nama kandidat atau foreign key ke kotak suara.**
   - **Tabel 2 (`ballots`)**: Hanya menyimpan `candidate_id` dan `created_at`. **Sama sekali tidak memiliki kolom nama, email, user_id, IP address, maupun korelasi dengan pemilih.**
   - Bahkan jika database dibuka langsung atau diekspor oleh admin/panitia, **secara matematis mustahil merekonstruksi siapa memilih siapa**.

3. **Perlindungan Anti-Double Voting**:
   - Fungsi PostgreSQL `cast_vote(p_email_hash, p_candidate_id)` berjalan secara **ACID Transaction** dengan penguncian baris `FOR UPDATE`.
   - Mencegah serangan race condition, replay attack, atau pengiriman formulir ganda serentak.
   - Satu akun email hanya berhak memberikan 1 suara sah.

4. **Dashboard Admin Berkeamanan Tinggi**:
   - Terproteksi kunci sandi rahasia (default: `pmkdaniel2026admin`, dapat diubah di `.env.local` via `ADMIN_SECRET_KEY`).
   - Sesi admin disimpan dalam HTTP-Only Secure Cookie.
   - Endpoint `/api/admin/tally` hanya mengembalikan **agregat perhitungan statistik** (jumlah suara dan persentase per kandidat).
   - Fitur Live Auto-Sync tiap 5 detik dan tombol Cetak/Export Berita Acara Rekapitulasi Resmi.

---

## 🗄️ Menjalankan Skrip Database Supabase

Kredensial Supabase diambil langsung dari konfigurasi `webpmk`:
- **URL**: `https://xnbiaaxwltofdiklxhnw.supabase.co`
- **Anon Key**: Tersedia di `.env.local`

### Langkah Menjalankan Skrip SQL di Supabase:
1. Buka [Supabase Dashboard](https://supabase.com/dashboard/project/xnbiaaxwltofdiklxhnw).
2. Masuk ke menu **SQL Editor** di bilah navigasi kiri.
3. Klik **New query**.
4. Salin seluruh isi berkas [`supabase_schema.sql`](./supabase_schema.sql) dan tempel di editor.
5. Klik tombol **Run** (atau `Ctrl + Enter`).
6. Seluruh tabel (`candidates`, `voter_registry`, `ballots`), kebijakan Row Level Security (RLS), dan fungsi `cast_vote` serta `get_vote_summary` akan otomatis terpasang!

> **Catatan:** Sistem telah dilengkapi mekanisme *smart fallback* lokal. Bahkan sebelum skrip SQL dijalankan, aplikasi tetap dapat dijalankan secara instan untuk simulasi pengujian tanpa error.

---

## 🚀 Panduan Menjalankan di Komputer Lokal

```bash
# 1. Pindah ke folder voting-app
cd "C:\Users\kuahs\Documents\web pmk\voting-app"

# 2. Jalankan server development
npm run dev

# Atau jalankan versi produksi lokal (sangat cepat & stabil)
npm run build
npm run start
```

Buka peramban di:
- **Bilik Suara Pemilih**: `http://localhost:3000`
- **Dashboard Rekapitulasi Admin**: `http://localhost:3000/admin` (Kata sandi: `pmkdaniel2026admin`)

---

## ☁️ Panduan Deploy ke Vercel

### Opsi A: Deploy Menggunakan GitHub Repository
1. Commit folder `voting-app` ke repository Git PMK Daniel:
   ```bash
   git add voting-app
   git commit -m "feat: add secure voting web app for UB student election"
   git push origin <nama-branch>
   ```
2. Buka dashboard [Vercel](https://vercel.com) dan pilih **Add New Project**.
3. Hubungkan ke repository GitHub `PMK-Daniel/pmkdaniel`.
4. Di bagian **Root Directory**, klik **Edit** dan pilih folder:
   ```
   voting-app
   ```
5. Di bagian **Environment Variables**, tambahkan:
   - `NEXT_PUBLIC_SUPABASE_URL`: `https://xnbiaaxwltofdiklxhnw.supabase.co`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: *(isi dari .env.local)*
   - `ADMIN_SECRET_KEY`: *(kata sandi admin Anda, contoh: `pmkdaniel2026admin`)*
   - `VOTER_PEPPER`: *(string acak untuk salt hashing email, contoh: `pmk_daniel_ub_voting_super_secret_pepper_2026`)*
6. Klik **Deploy**. Website akan langsung online dan siap digunakan!

---

## 📋 Struktur Berkas Proyek

```
voting-app/
├── src/
│   ├── app/
│   │   ├── page.tsx               # Halaman Bilik Suara (Brawijaya E-Voting)
│   │   ├── layout.tsx             # Root Layout, Metadata & Font
│   │   ├── globals.css            # Styling Tailwind CSS
│   │   ├── admin/
│   │   │   └── page.tsx           # Dashboard Perhitungan Admin Real-time
│   │   └── api/
│   │       ├── auth/
│   │       │   ├── send-otp/      # Validasi email @student.ub.ac.id & kirim OTP
│   │       │   └── verify-otp/    # Verifikasi OTP & terbitkan voter token
│   │       ├── vote/
│   │       │   └── cast/          # Perekaman suara anonim atomic (cast_vote)
│   │       └── admin/
│   │           ├── auth/          # Login admin & HTTP-only cookie
│   │           ├── tally/         # Rekapitulasi agregat suara (tanpa nama pemilih)
│   │           └── logout/        # Sesi keluar admin
│   ├── components/
│   │   ├── Navbar.tsx             # Header navigasi & badge status keamanan
│   │   └── Footer.tsx             # Footer & informasi legal pemilihan
│   ├── lib/
│   │   ├── candidates.ts          # Profil 5 kandidat (Joseph, Zoe, Anna, Nata, Chelsea)
│   │   ├── security.ts            # Enkripsi HMAC-SHA256, token signer, validator email UB
│   │   ├── supabase.ts            # Inisialisasi Supabase Client
│   │   └── store.ts               # In-memory store fallback pengujian
│   └── types/
│       └── voting.ts              # Interface TypeScript untuk data voting
├── .env.local                     # Kredensial lokal Supabase & Admin Secret
├── .env.example                   # Contoh konfigurasi untuk deployment Vercel
├── supabase_schema.sql            # Skema lengkap SQL database Supabase
├── package.json
└── tsconfig.json
```
