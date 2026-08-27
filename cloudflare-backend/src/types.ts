export interface Env {
  DB: D1Database;
  R2_BUCKET?: R2Bucket;
  JWT_SECRET: string;
  R2_PUBLIC_DOMAIN?: string;
}

export interface User {
  id: string;
  username: string;
  password_hash: string;
  role: string;
  created_at?: string;
}

export interface Pengumuman {
  id: string;
  title: string;
  slug: string;
  category: string;
  content: string;
  image_url: string | null;
  date_published: string;
  author: string;
  views: number;
  created_at?: string;
  updated_at?: string;
}

export interface Divisi {
  id: string;
  name: string;
  komisi: string | null;
  icon_name: string | null;
  description: string | null;
  group_photo_url: string | null;
  order_priority: number;
  members?: Pengurus[];
}

export interface Pengurus {
  id: string;
  divisi_id: string;
  name: string;
  role: string;
  photo_url: string | null;
  period: string;
  order_priority: number;
}

export interface FormLink {
  key: string;
  title: string;
  google_form_url: string;
  is_active: number;
  updated_at?: string;
}

export interface DynamicForm {
  id: string;
  title: string;
  slug: string;
  description: string | null;
  fields_schema: string;
  is_active: number;
  created_at?: string;
  updated_at?: string;
}

export interface FormSubmission {
  id: string;
  form_id: string;
  answers_json: string;
  submitted_at?: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  detail?: string;
}
