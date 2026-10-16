import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminToken } from '../auth/route';
import { globalStore } from '@/lib/store';
import { getSupabaseServerClient } from '@/lib/supabase';
import { isCandidateValid } from '@/lib/security';

export async function POST(req: NextRequest) {
  try {
    const adminSession = req.cookies.get('admin_session')?.value;
    if (!verifyAdminToken(adminSession)) {
      return NextResponse.json(
        { success: false, message: 'Akses ditolak: Hanya admin yang dapat mengedit suara.' },
        { status: 401 }
      );
    }

    const body = await req.json();
    const { action, candidateId, countChange } = body;

    // Action 1: Reset Seluruh Suara (Kotak Suara & Registry)
    if (action === 'reset_all') {
      if (globalStore.mockBallots) globalStore.mockBallots = [];
      if (globalStore.mockVoterRegistry) globalStore.mockVoterRegistry.clear();
      if (globalStore.mockVoterDetails) globalStore.mockVoterDetails = [];
      if (globalStore.mockOtpStore) globalStore.mockOtpStore.clear();

      try {
        const supabase = getSupabaseServerClient();
        await supabase.from('ballots').delete().neq('id', '00000000-0000-0000-0000-000000000000');
        await supabase.from('voter_registry').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch {
        // Abaikan
      }

      return NextResponse.json({
        success: true,
        message: 'Seluruh data suara dan registrasi pemilih berhasil direset.',
      });
    }

    // Action 2: Tambah/Kurang Suara Manual untuk Kandidat Tertentu
    if (action === 'adjust_count') {
      if (!isCandidateValid(candidateId)) {
        return NextResponse.json(
          { success: false, message: 'Kandidat tidak valid.' },
          { status: 400 }
        );
      }

      const diff = parseInt(countChange, 10);
      if (isNaN(diff)) {
        return NextResponse.json(
          { success: false, message: 'Perubahan jumlah suara tidak valid.' },
          { status: 400 }
        );
      }

      if (diff > 0) {
        // Tambahkan suara
        for (let i = 0; i < diff; i++) {
          globalStore.mockBallots?.push({
            candidate_id: candidateId,
            created_at: new Date().toISOString(),
          });
        }
      } else if (diff < 0) {
        // Kurangi suara (hapus sebanyak abs(diff))
        let toRemove = Math.abs(diff);
        if (globalStore.mockBallots) {
          globalStore.mockBallots = globalStore.mockBallots.filter((b) => {
            if (b.candidate_id === candidateId && toRemove > 0) {
              toRemove--;
              return false;
            }
            return true;
          });
        }
      }

      return NextResponse.json({
        success: true,
        message: `Jumlah suara untuk ${candidateId} berhasil diubah sebanyak ${diff > 0 ? '+' + diff : diff}.`,
      });
    }

    return NextResponse.json(
      { success: false, message: 'Aksi tidak dikenali.' },
      { status: 400 }
    );
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
