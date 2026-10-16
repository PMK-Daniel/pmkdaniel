import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://xnbiaaxwltofdiklxhnw.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhuYmlhYXh3bHRvZmRpa2x4aG53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzcwODMsImV4cCI6MjEwMDY1MzA4M30.aRd99tpBGriOaIMeb0-5jQ3icTqxwg0flIfbi-W4u7U';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Client-side & general Supabase client
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  }
});

// Server-side admin client (with service role key if available, otherwise anon)
export const getSupabaseServerClient = () => {
  if (supabaseServiceKey) {
    return createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      }
    });
  }
  return supabase;
};
