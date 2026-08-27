-- PMK Daniel FILKOM UB D1 Schema

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'admin' NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pengumuman (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    date_published TEXT NOT NULL,
    author TEXT DEFAULT 'Pengurus PMK' NOT NULL,
    views INTEGER DEFAULT 0 NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS divisi (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    komisi TEXT,
    icon_name TEXT,
    description TEXT,
    group_photo_url TEXT,
    order_priority INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS pengurus (
    id TEXT PRIMARY KEY,
    divisi_id TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    photo_url TEXT,
    period TEXT NOT NULL,
    order_priority INTEGER DEFAULT 0,
    FOREIGN KEY (divisi_id) REFERENCES divisi(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS form_links (
    key TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    google_form_url TEXT NOT NULL,
    is_active INTEGER DEFAULT 1 NOT NULL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dynamic_forms (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    fields_schema TEXT DEFAULT '[]' NOT NULL,
    is_active INTEGER DEFAULT 1 NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS form_submissions (
    id TEXT PRIMARY KEY,
    form_id TEXT NOT NULL,
    answers_json TEXT DEFAULT '{}' NOT NULL,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (form_id) REFERENCES dynamic_forms(id) ON DELETE CASCADE
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_pengumuman_category ON pengumuman(category);
CREATE INDEX IF NOT EXISTS idx_pengumuman_slug ON pengumuman(slug);
CREATE INDEX IF NOT EXISTS idx_pengurus_divisi_id ON pengurus(divisi_id);
CREATE INDEX IF NOT EXISTS idx_dynamic_forms_slug ON dynamic_forms(slug);
CREATE INDEX IF NOT EXISTS idx_form_submissions_form_id ON form_submissions(form_id);
