import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminToken } from '../auth/route';
import { globalStore } from '@/lib/store';
import { getSupabaseServerClient } from '@/lib/supabase';

export async function GET(req: NextRequest) {
  try {
    const adminSession = req.cookies.get('admin_session')?.value;
    if (!verifyAdminToken(adminSession)) {
      return NextResponse.json(
        { success: false, message: 'Akses ditolak: Hanya admin yang dapat melihat data ini.' },
        { status: 401 }
      );
    }

    // Ambil daftar detail pemilih dari database dan memori
    const voters = [...(globalStore.mockVoterDetails || [])];

    // Coba ambil dari Supabase jika ada data tersimpan
    try {
      const supabase = getSupabaseServerClient();
      const { data: dbVoters } = await supabase
        .from('voter_registry')
        .select('*')
        .order('voted_at', { ascending: false });

      if (dbVoters && Array.isArray(dbVoters) && dbVoters.length > 0) {
        // Jika ada di Supabase, gabungkan jika belum ada
        dbVoters.forEach((dv) => {
          if (!voters.some((v) => v.email_hash === dv.email_hash)) {
            voters.push({
              email: dv.email || `[Hash] ${dv.email_hash.substring(0, 10)}...`,
              email_hash: dv.email_hash,
              candidate_id: dv.candidate_id || '-',
              candidate_name: dv.candidate_name || 'Tercatat',
              voted_at: dv.voted_at || dv.verified_at || new Date().toISOString(),
            });
          }
        });
      }
    } catch {
      // Supabase table not created yet, fallback memory used
    }

    return NextResponse.json({
      success: true,
      total_voters: voters.length,
      voters: voters,
      timestamp: new Date().toISOString(),
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
