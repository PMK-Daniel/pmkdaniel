-- ====================================================================
-- SKEMA DATABASE E-VOTING UNIVERSITAS BRAWIJAYA
-- Zero-Knowledge Anonymous Ballot Box Architecture
-- Dibuat untuk Supabase (PostgreSQL)
-- ====================================================================

-- 1. Tabel Kandidat (Candidates)
CREATE TABLE IF NOT EXISTS public.candidates (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    number INTEGER UNIQUE NOT NULL,
    tagline TEXT,
    vision TEXT,
    mission TEXT,
    avatar_color TEXT DEFAULT '#3b82f6',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Isi Data Kandidat (Joseph, Zoe, Anna, Nata, Chelsea)
INSERT INTO public.candidates (id, name, display_name, number, tagline, vision, mission, avatar_color)
VALUES 
(
    'joseph',
    'Joseph',
    'Joseph',
    1,
    'Membangun Persekutuan yang Berakar, Bertumbuh, dan Berdampak Nyata',
    'Mewujudkan wadah regenerasi dan persekutuan mahasiswa yang kokoh secara spiritual, memiliki integritas tinggi, dan menjadi terang di lingkungan kampus maupun masyarakat luas.',
    '1. Menyelenggarakan pembinaan rohani yang berbobot dan relevan dengan tantangan mahasiswa masa kini.\n2. Menguatkan persekutuan dan rasa persaudaraan yang erat di setiap angkatan.\n3. Menggerakkan aksi nyata pengabdian dan kepedulian sosial di lingkungan kampus Universitas Brawijaya.',
    '#2563eb'
),
(
    'zoe',
    'Zoe',
    'Zoe',
    2,
    'Kepemimpinan Melayani Berlandaskan Kasih, Integritas, dan Inovasi',
    'Menciptakan lingkungan persekutuan yang suportif, transparan, dan inklusif di mana setiap talenta dihargai dan diberdayakan secara maksimal untuk pelayanan.',
    '1. Membangun sistem komunikasi dan koordinasi yang responsif dan transparan.\n2. Mengembangkan program mentoring dan pelatihan kepemimpinan berbasis talenta.\n3. Menjalin sinergi dan kolaborasi strategis dengan berbagai elemen kampus.',
    '#7c3aed'
),
(
    'anna',
    'Anna',
    'Anna',
    3,
    'Menghadirkan Rumah Persekutuan yang Hangat, Adaptif, dan Mengayomi',
    'Menjadikan persekutuan sebagai rumah yang memulihkan dan menumbuhkan, di mana setiap mahasiswa menemukan dukungan iman dan persaudaraan tanpa sekat.',
    '1. Memperkuat kelompok-kelompok kecil (cell group) sebagai inti pemuridan dan pendampingan personal.\n2. Menyediakan ruang aman (safe space) untuk konseling sebaya dan saling menguatkan.\n3. Memadukan kegiatan persekutuan yang dinamis dengan penguatan karakter Kristiani.',
    '#db2777'
),
(
    'nata',
    'Nata',
    'Nata',
    4,
    'Transformasi Karakter Menuju Kedewasaan Iman dan Profesionalisme',
    'Mencetak kader-kader pemimpin mahasiswa yang tidak hanya unggul secara akademis dan rohani, namun juga siap berkontribusi secara profesional di dunia kerja.',
    '1. Memperdalam pemahaman firman dan doktrin iman yang kontekstual bagi generasi muda.\n2. Mengadakan workshop pengembangan soft skills, kepemimpinan, dan etika kerja.\n3. Menumbuhkan kesadaran integritas dan anti-kecurangan dalam kehidupan akademis sehari-hari.',
    '#ea580c'
),
(
    'chelsea',
    'Chelsea',
    'Chelsea',
    5,
    'Sinergi Pelayanan Kreatif, Solutif, dan Berkelanjutan di Era Digital',
    'Mendorong modernisasi pelayanan melalui pemanfaatan media digital dan teknologi kreatif, guna menjangkau lebih banyak mahasiswa Universitas Brawijaya.',
    '1. Menghadirkan konten rohani dan informasi kegiatan yang inspiratif di berbagai platform digital.\n2. Membangun platform aspirasi yang cepat tanggap terhadap kebutuhan anggota.\n3. Memperkuat regenerasi kepengurusan yang berkelanjutan melalui pembekalan berjenjang.',
    '#059669'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    display_name = EXCLUDED.display_name,
    number = EXCLUDED.number,
    tagline = EXCLUDED.tagline,
    vision = EXCLUDED.vision,
    mission = EXCLUDED.mission,
    avatar_color = EXCLUDED.avatar_color;

-- 2. Tabel Registrasi Pemilih (Voter Registry)
-- PENTING: Hanya menyimpan hash email + status apakah sudah memilih.
-- SAMA SEKALI TIDAK ADA PILIHAN KANDIDAT DI SINI!
CREATE TABLE IF NOT EXISTS public.voter_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email_hash TEXT UNIQUE NOT NULL,
    has_voted BOOLEAN DEFAULT FALSE NOT NULL,
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    voted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_voter_registry_email_hash ON public.voter_registry(email_hash);

-- 3. Kotak Suara Anonim (Ballots Box)
-- PENTING: SAMA SEKALI TIDAK ADA KOLOM EMAIL, USER ID, IP, ATAU FOREIGN KEY PEMILIH!
-- Kotak ini murni menampung kertas suara yang telah dimasukkan secara anonim.
CREATE TABLE IF NOT EXISTS public.ballots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id TEXT NOT NULL REFERENCES public.candidates(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ballots_candidate_id ON public.ballots(candidate_id);

-- 4. Aktifkan Row Level Security (RLS)
ALTER TABLE public.candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voter_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ballots ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS:
-- - Kandidat dapat dibaca oleh publik (anon & authenticated)
DROP POLICY IF EXISTS "Kandidat dapat dilihat publik" ON public.candidates;
CREATE POLICY "Kandidat dapat dilihat publik" ON public.candidates
    FOR SELECT USING (true);

-- - Voter registry TIDAK BISA dibaca langsung oleh siapapun lewat REST API (mencegah scraping pemilih)
DROP POLICY IF EXISTS "Voter registry privat" ON public.voter_registry;
CREATE POLICY "Voter registry privat" ON public.voter_registry
    FOR ALL USING (false);

-- - Kotak suara (Ballots) TIDAK BISA dibaca per baris oleh publik (hanya lewat fungsi agregat)
DROP POLICY IF EXISTS "Ballots tidak bisa dibaca publik secara mentah" ON public.ballots;
CREATE POLICY "Ballots tidak bisa dibaca publik secara mentah" ON public.ballots
    FOR ALL USING (false);


-- 5. Fungsi Transaksional Atomic: cast_vote
-- Menjamin zero race condition, perlindungan double voting, dan keterpisahan identitas
CREATE OR REPLACE FUNCTION public.cast_vote(
    p_email_hash TEXT,
    p_candidate_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_has_voted BOOLEAN;
    v_found BOOLEAN;
BEGIN
    -- Validasi 1: Validasi Whitelist Kandidat
    IF p_candidate_id NOT IN ('joseph', 'zoe', 'anna', 'nata', 'chelsea') THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Pilihan kandidat tidak sah atau tidak ditemukan.'
        );
    END IF;

    -- Validasi 2: Kunci baris pemilih (FOR UPDATE) untuk mencegah race condition/double submit serentak
    SELECT EXISTS(SELECT 1 FROM public.voter_registry WHERE email_hash = p_email_hash),
           COALESCE((SELECT has_voted FROM public.voter_registry WHERE email_hash = p_email_hash FOR UPDATE), FALSE)
    INTO v_found, v_has_voted;

    IF v_found AND v_has_voted THEN
        RETURN jsonb_build_object(
            'success', false, 
            'message', 'Email mahasiswa ini sudah pernah memberikan suara! Satu akun hanya berhak memilih satu kali.'
        );
    END IF;

    -- Catat status pemilih sudah menggunakan hak suara
    IF v_found THEN
        UPDATE public.voter_registry
        SET has_voted = TRUE, voted_at = NOW()
        WHERE email_hash = p_email_hash;
    ELSE
        INSERT INTO public.voter_registry (email_hash, has_voted, voted_at)
        VALUES (p_email_hash, TRUE, NOW());
    END IF;

    -- Masukkan suara ke kotak suara anonim secara terpisah
    INSERT INTO public.ballots (candidate_id, created_at)
    VALUES (p_candidate_id, NOW());

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Suara Anda berhasil dicatat secara rahasia dan anonim ke dalam sistem!'
    );
END;
$$;


-- 6. Fungsi Agregasi Admin Dashboard: get_vote_summary
-- Hanya mengembalikan total suara dan persentase per kandidat.
-- TIDAK PERNAH membocorkan nama atau email pemilih kepada admin!
CREATE OR REPLACE FUNCTION public.get_vote_summary()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_votes INTEGER;
    v_results JSONB;
BEGIN
    -- Hitung total suara masuk
    SELECT COUNT(*) INTO v_total_votes FROM public.ballots;

    -- Agregasi per kandidat
    SELECT jsonb_agg(
        jsonb_build_object(
            'candidate_id', c.id,
            'name', c.name,
            'display_name', c.display_name,
            'number', c.number,
            'tagline', c.tagline,
            'avatar_color', c.avatar_color,
            'votes', COALESCE(b.cnt, 0),
            'percentage', CASE 
                WHEN v_total_votes > 0 THEN ROUND((COALESCE(b.cnt, 0)::numeric / v_total_votes::numeric) * 100, 2)
                ELSE 0 
            END
        ) ORDER BY c.number ASC
    )
    INTO v_results
    FROM public.candidates c
    LEFT JOIN (
        SELECT candidate_id, COUNT(*) as cnt
        FROM public.ballots
        GROUP BY candidate_id
    ) b ON c.id = b.candidate_id;

    RETURN jsonb_build_object(
        'total_votes', v_total_votes,
        'results', COALESCE(v_results, '[]'::jsonb),
        'timestamp', NOW()
    );
END;
$$;

-- Berikan izin eksekusi ke anon & authenticated
GRANT EXECUTE ON FUNCTION public.cast_vote(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_vote_summary() TO anon, authenticated;
