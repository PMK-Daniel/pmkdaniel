import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminToken } from '../auth/route';
import { getSupabaseServerClient } from '@/lib/supabase';
import { CANDIDATES } from '@/lib/candidates';
import { globalStore, BallotEntry } from '@/lib/store';
import { CandidateTally, CandidateId } from '@/types/voting';

export async function GET(req: NextRequest) {
  try {
    // 1. Verifikasi Autorisasi Admin
    const adminSession = req.cookies.get('admin_session')?.value;
    if (!verifyAdminToken(adminSession)) {
      return NextResponse.json(
        { success: false, message: 'Akses ditolak: Anda harus login sebagai admin.' },
        { status: 401 }
      );
    }

    const supabase = getSupabaseServerClient();
    let totalVotes = 0;
    let results: CandidateTally[] = [];
    let fetchedFromSupabase = false;

    // 2. Ambil data perhitungan agregat via RPC get_vote_summary (Zero-Knowledge)
    try {
      const { data: summaryData, error: rpcErr } = await supabase.rpc('get_vote_summary');
      if (!rpcErr && summaryData && typeof summaryData.total_votes === 'number') {
        totalVotes = summaryData.total_votes;
        results = summaryData.results;
        fetchedFromSupabase = true;
      }
    } catch (e) {
      console.warn('Supabase get_vote_summary RPC call notice:', e);
    }

    // 3. Fallback jika Supabase RPC belum diaktifkan: hitung dari ballots atau memory
    if (!fetchedFromSupabase) {
      const countMap: Record<CandidateId, number> = {
        joseph: 0,
        zoe: 0,
        anna: 0,
        nata: 0,
        chelsea: 0,
      };

      try {
        const { data: ballotsData } = await supabase.from('ballots').select('candidate_id');
        if (ballotsData && Array.isArray(ballotsData)) {
          totalVotes += ballotsData.length;
          ballotsData.forEach((b: { candidate_id: string }) => {
            if (b.candidate_id in countMap) {
              countMap[b.candidate_id as CandidateId]++;
            }
          });
        }
      } catch {
        // Abaikan
      }

      // Gabungkan dengan memory store jika ada
      if (globalStore.mockBallots && globalStore.mockBallots.length > 0) {
        if (totalVotes === 0) {
          totalVotes = globalStore.mockBallots.length;
          globalStore.mockBallots.forEach((b: BallotEntry) => {
            if (b.candidate_id in countMap) {
              countMap[b.candidate_id as CandidateId]++;
            }
          });
        }
      }

      results = CANDIDATES.map((cand) => {
        const count = countMap[cand.id] || 0;
        const percentage = totalVotes > 0 ? Number(((count / totalVotes) * 100).toFixed(2)) : 0;
        return {
          candidate_id: cand.id,
          name: cand.name,
          display_name: cand.displayName,
          number: cand.number,
          tagline: cand.tagline,
          avatar_color: cand.avatarColor,
          votes: count,
          percentage: percentage,
        };
      });
    }

    // 4. Return data murni perhitungan statistik
    // PENTING: Response sama sekali tidak memuat data individual pemilih!
    return NextResponse.json({
      success: true,
      total_votes: totalVotes,
      results: results,
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
