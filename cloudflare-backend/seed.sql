-- Seed Admin User (admin / admin123)
INSERT OR IGNORE INTO users (id, username, password_hash, role)
VALUES ('usr_admin_01', 'admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin');

-- Seed Divisi PMK Daniel
INSERT OR IGNORE INTO divisi (id, name, komisi, icon_name, description, group_photo_url, order_priority) VALUES
('ketua_umum', 'Ketua Umum', 'BPH', 'crown', 'Bertanggung jawab penuh atas arah kepemimpinan, visi misi rohani, serta koordinasi seluruh badan pelayanan PMK Daniel FILKOM UB.', '/images/bastian.webp', 1),
('sekretaris', 'Sekretaris', 'BPH', 'pen', 'Mengelola tata kelola administrasi surat-menyurat, persuratan resmi, proposal, arsip notulensi, dan inventaris berkas PMK Daniel.', '/images/persekutuan.webp', 2),
('wakil_ketua_umum', 'Wakil Ketua Umum', 'BPH', 'shield', 'Mendampingi Ketua Umum dalam koordinasi internal komisi-komisi dan pengawasan jalannya program kerja persekutuan.', '/images/christo.webp', 3),
('bendahara', 'Bendahara', 'BPH', 'wallet', 'Mengatur perputaran sirkulasi keuangan, pembukuan kas persekutuan, transparansi anggaran, serta alokasi dana persepuluhan dan persembahan.', '/images/persekutuan.webp', 4),
('pembinaan', 'Pembinaan', 'Komisi 1', 'book', 'Merancang kurikulum pembinaan rohani mahasiswa Kristen FILKOM, kelompok kecil (KTB), pendalaman Alkitab, dan mentoring rohani.', '/images/campdaniel.webp', 5),
('pemerhati', 'Pemerhati', 'Komisi 2', 'heart', 'Melayani doa syafaat, kepedulian jemaat, sambutan mahasiswa baru, ucapan ulang tahun, serta konseling dan kunjungan kasih.', '/images/persekutuan.webp', 6),
('acara', 'Acara', 'Komisi 3', 'sparkles', 'Merancang konsep dan alur liturgi persekutuan mingguan, Welcoming Party, Retreat, Natal, Paskah, dan ibadah tematik.', '/images/campdaniel.webp', 7),
('media_relasi', 'Media & Relasi', 'Komisi 4', 'video', 'Pusat media kreatif publikasi, dokumentasi, siaran visual, serta membangun kemitraan relasi eksternal dengan lembaga Kristen.', '/images/joshua.webp', 8),
('teknis_inventaris', 'Teknis & Inventaris', 'Sub Komisi 3 (Acara)', 'settings', 'Mengelola sarana perlengkapan sound system, instrumen musik, proyektor, logistik ruangan, dan tata letak teknis persekutuan.', '/images/persekutuan.webp', 9),
('acara_sub', 'Acara', 'Sub Komisi 3 (Acara)', 'calendar', 'Pelaksana teknis jalannya rundown persekutuan, koordinasi worship leader, singer, dan pembicara hamba Tuhan.', '/images/campdaniel.webp', 10),
('minat_bakat', 'Minat Bakat & Misi Pelayanan', 'Sub Komisi 3 (Acara)', 'music', 'Wadah pengembangan talenta musik, vokal, tari/drama, serta pengutusan misi sosial pelayanan kasih ke panti asuhan.', '/images/persekutuan.webp', 11),
('media', 'Media', 'Sub Komisi 4 (Medrel)', 'camera', 'Bertanggung jawab atas fotografi, videografi recap, desain feed Instagram, live streaming, dan maintenance website.', '/images/joshua.webp', 12),
('relasi', 'Relasi', 'Sub Komisi 4 (Medrel)', 'users', 'Menjalin hubungan persaudaraan dengan PMK fakultas lain di UB, gereja lokal, alumni PMK Daniel, dan lembaga pelayanan kampus.', '/images/persekutuan.webp', 13);

-- Seed Pengurus
INSERT OR IGNORE INTO pengurus (id, divisi_id, name, role, photo_url, period, order_priority) VALUES
('png_01', 'ketua_umum', 'Bastian Nevan Baruch', 'Ketua Umum', '/images/bastian.webp', '2025/2026', 1),
('png_02', 'wakil_ketua_umum', 'Christo Emmanuel', 'Wakil Ketua Umum', '/images/christo.webp', '2025/2026', 1),
('png_03', 'sekretaris', 'Gracia Stephanie', 'Sekretaris 1', '/images/persekutuan.webp', '2025/2026', 1),
('png_04', 'sekretaris', 'Patricia Putri', 'Sekretaris 2', '/images/persekutuan.webp', '2025/2026', 2),
('png_05', 'bendahara', 'Nathania Michelle', 'Bendahara 1', '/images/persekutuan.webp', '2025/2026', 1),
('png_06', 'bendahara', 'Samuel Timothy', 'Bendahara 2', '/images/persekutuan.webp', '2025/2026', 2),
('png_07', 'pembinaan', 'Jonathan Kevin', 'Ketua Pembinaan', '/images/campdaniel.webp', '2025/2026', 1),
('png_08', 'pembinaan', 'Debora Angeline', 'Wakil Ketua Pembinaan', '/images/campdaniel.webp', '2025/2026', 2),
('png_09', 'pembinaan', 'Daniel Ezra', 'Anggota Pembinaan', '/images/campdaniel.webp', '2025/2026', 3),
('png_10', 'pembinaan', 'Ruth Valerie', 'Anggota Pembinaan', '/images/campdaniel.webp', '2025/2026', 4),
('png_11', 'pemerhati', 'Joshua Alexander', 'Ketua Pemerhati', '/images/joshua.webp', '2025/2026', 1),
('png_12', 'pemerhati', 'Ester Naomi', 'Wakil Ketua Pemerhati', '/images/persekutuan.webp', '2025/2026', 2),
('png_13', 'pemerhati', 'Grace Febiola', 'Anggota Pemerhati', '/images/persekutuan.webp', '2025/2026', 3),
('png_14', 'acara', 'Timothy Aaron', 'Koordinator Komisi Acara', '/images/campdaniel.webp', '2025/2026', 1),
('png_15', 'acara', 'Rachel Jovita', 'Wakil Koordinator Acara', '/images/campdaniel.webp', '2025/2026', 2),
('png_16', 'media_relasi', 'Dave Christian', 'Koordinator Komisi Medrel', '/images/joshua.webp', '2025/2026', 1),
('png_17', 'media_relasi', 'Hanna Pricilla', 'Wakil Koordinator Medrel', '/images/persekutuan.webp', '2025/2026', 2),
('png_18', 'teknis_inventaris', 'Michael Ryan', 'Ketua Divisi Teknis', '/images/persekutuan.webp', '2025/2026', 1),
('png_19', 'acara_sub', 'Sarah Clarissa', 'Ketua Divisi Acara Pelaksana', '/images/campdaniel.webp', '2025/2026', 1),
('png_20', 'minat_bakat', 'David Christian', 'Ketua Divisi Minat Bakat', '/images/persekutuan.webp', '2025/2026', 1),
('png_21', 'media', 'Jeremy Matthew', 'Ketua Divisi Media Visual', '/images/joshua.webp', '2025/2026', 1),
('png_22', 'relasi', 'Rebeca Amanda', 'Ketua Divisi Relasi Eksternal', '/images/persekutuan.webp', '2025/2026', 1);

-- Seed Form Links
INSERT OR IGNORE INTO form_links (key, title, google_form_url, is_active) VALUES
('maba', 'Form Pendataan Mahasiswa Baru', 'https://forms.gle/maba-pmk-daniel', 1),
('alumni', 'Form Pendataan Alumni PMK Daniel', 'https://forms.gle/alumni-pmk-daniel', 1),
('kepanitiaan', 'Form Pendaftaran Kepanitiaan', 'https://forms.gle/kepanitiaan-pmk-daniel', 1);

-- Seed Default Dynamic Form (Pendataan Maba 2026)
INSERT OR IGNORE INTO dynamic_forms (id, title, slug, description, fields_schema, is_active) VALUES
('form_maba_2026', 'Form Pendataan Mahasiswa Baru PMK Daniel 2026', 'pendataan-maba-2026', 'Shalom Mahasiswa Baru FILKOM UB! Selamat datang di keluarga besar PMK Daniel. Silakan isi form ini untuk mempermudah komunikasi dan pendampingan kakak tingkat.', '[{"id":"nama_lengkap","label":"Nama Lengkap","type":"text","placeholder":"Contoh: Jonathan Christopher","required":true},{"id":"nim","label":"NIM (Nomor Induk Mahasiswa)","type":"text","placeholder":"Contoh: 265150200111001","required":true},{"id":"program_studi","label":"Program Studi / Jurusan","type":"select","options":["Teknik Informatika","Sistem Informasi","Teknologi Informasi","Pendidikan Teknologi Informasi","Teknik Komputer"],"required":true},{"id":"no_whatsapp","label":"Nomor WhatsApp Aktif","type":"text","placeholder":"081234567890","required":true},{"id":"pilihan_divisi","label":"Minat Pelayanan Utama (Pilih 1)","type":"radio","options":["Divisi Acara & Ibadah","Divisi Musik & Pujian","Divisi Multimedia & Publikasi","Divisi Doa & Pemerhati","Divisi Perlengkapan & Logistik"],"required":true},{"id":"talenta_minat","label":"Talenta & Keahlian Tambahan (Boleh lebih dari 1)","type":"checkbox","options":["Main Musik (Gitar / Keyboard / Drum / Bass)","Vocal / Singer / WL","Desain Grafis / Canva / Photoshop","Fotografi / Videografi","Operating Sound System / OBS Live Streaming"],"required":false},{"id":"alasan_motivasi","label":"Ceritakan Motivasi / Harapan Anda di PMK Daniel","type":"textarea","placeholder":"Tuliskan cerita singkat atau harapan Anda...","required":false},{"id":"foto_ktm","label":"Upload Foto Diri / KTM / Bukti Penerimaan","type":"file","helpText":"Format file: JPG, PNG, atau PDF (Maksimal 10MB)","required":false}]', 1);
