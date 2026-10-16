'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { 
  Trophy, 
  RefreshCw, 
  Maximize2, 
  Minimize2, 
  Vote, 
  Sparkles,
  BarChart2,
  TrendingUp,
  Activity
} from 'lucide-react';
import { CandidateTally } from '@/types/voting';

export default function McLiveScreenPage() {
  const [totalVotes, setTotalVotes] = useState<number>(0);
  const [results, setResults] = useState<CandidateTally[]>([]);
  const [lastUpdated, setLastUpdated] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Ambil data suara langsung secara real-time
  const fetchTally = useCallback(async () => {
    setIsLoading(true);
    try {
      // Ambil data kalkulasi suara
      const res = await fetch('/api/admin/tally');
      if (res.ok) {
        const data = await res.json();
        if (data.success) {
          setTotalVotes(data.total_votes || 0);
          setResults(data.results || []);
          setLastUpdated(data.timestamp || new Date().toISOString());
        }
      } else {
        // Fallback panggil candidates
        const cRes = await fetch('/api/admin/candidates');
        if (cRes.ok) {
          const cData = await cRes.json();
          if (cData.candidates) {
            setResults(cData.candidates.map((c: any) => ({
              candidate_id: c.id,
              name: c.name,
              display_name: c.displayName,
              number: c.number,
              tagline: c.tagline,
              avatar_color: c.avatarColor,
              votes: 0,
              percentage: 0
            })));
          }
        }
      }
    } catch (e) {
      console.error('Fetch tally error:', e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTally();
    const interval = setInterval(fetchTally, 3000); // Sinkronisasi otomatis tiap 3 detik
    return () => clearInterval(interval);
  }, [fetchTally]);

  // Toggle Layar Penuh (Projector Mode)
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().then(() => setIsFullscreen(true)).catch(() => {});
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false)).catch(() => {});
    }
  };

  // Urutkan untuk mendeteksi pemimpin sementara
  const sorted = [...results].sort((a, b) => b.votes - a.votes);
  const leader = sorted.length > 0 && sorted[0].votes > 0 ? sorted[0] : null;

  return (
    <div className="min-h-screen bg-slate-950 text-white flex flex-col justify-between p-4 sm:p-8 lg:p-12 relative overflow-hidden select-none">
      {/* Background Glow Ambient */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-blue-600/15 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-indigo-600/15 rounded-full blur-3xl pointer-events-none" />

      {/* Header Stage MC */}
      <header className="flex flex-col sm:flex-row items-center justify-between gap-4 border-b border-slate-800/80 pb-6 relative z-10">
        <div className="text-center sm:text-left">
          <div className="flex items-center justify-center sm:justify-start gap-2.5 mb-2">
            <span className="inline-flex items-center gap-1.5 bg-red-500/20 text-red-400 border border-red-500/30 text-xs px-3 py-1 rounded-full font-bold uppercase tracking-wider">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
              Live Stage Monitor
            </span>
            <span className="text-xs text-slate-400 font-medium">
              PMK Daniel FILKOM Universitas Brawijaya
            </span>
          </div>
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black tracking-tight text-transparent bg-clip-text bg-gradient-to-r from-white via-slate-100 to-slate-400">
            GRAFIK PERHITUNGAN SUARA
          </h1>
        </div>

        <div className="flex items-center gap-3">
          {/* Total Suara Masuk Pill */}
          <div className="bg-slate-900 border border-slate-800 rounded-2xl px-5 py-2.5 flex items-center gap-3 shadow-lg">
            <div className="w-10 h-10 rounded-xl bg-blue-500/20 text-blue-400 flex items-center justify-center">
              <Vote className="w-5 h-5" />
            </div>
            <div>
              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Total Suara</p>
              <p className="text-2xl font-black text-white tracking-tight">{totalVotes.toLocaleString('id-ID')}</p>
            </div>
          </div>

          {/* Fullscreen Button */}
          <button
            type="button"
            onClick={toggleFullscreen}
            title="Layar Penuh Proyektor"
            className="w-12 h-12 rounded-2xl bg-slate-900 hover:bg-slate-800 border border-slate-800 flex items-center justify-center text-slate-300 hover:text-white transition shadow-lg"
          >
            {isFullscreen ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
          </button>
        </div>
      </header>

      {/* Main Charts Stage (Hanya Grafik Vote) */}
      <main className="my-auto py-8 relative z-10 max-w-7xl mx-auto w-full space-y-6">
        {results.map((cand) => {
          const isLeader = leader && leader.candidate_id === cand.candidate_id;

          return (
            <div
              key={cand.candidate_id}
              className={`rounded-3xl p-5 sm:p-6 transition-all duration-500 border ${
                isLeader
                  ? 'bg-gradient-to-r from-slate-900 via-slate-900/90 to-blue-950/40 border-amber-500/50 shadow-xl shadow-amber-500/5 ring-1 ring-amber-500/30'
                  : 'bg-slate-900/80 border-slate-800/80 hover:border-slate-700'
              }`}
            >
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
                <div className="flex items-center gap-4">
                  {/* Nomor Urut */}
                  <span
                    className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl font-black text-xl sm:text-2xl flex items-center justify-center text-white shadow-lg shrink-0"
                    style={{ backgroundColor: cand.avatar_color }}
                  >
                    0{cand.number}
                  </span>

                  <div>
                    <div className="flex items-center gap-3">
                      <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                        {cand.display_name}
                      </h2>
                      {isLeader && (
                        <span className="bg-amber-500/20 text-amber-300 border border-amber-500/40 text-xs px-3 py-0.5 rounded-full font-bold flex items-center gap-1.5">
                          <Trophy className="w-3.5 h-3.5 text-amber-400" />
                          Memimpin
                        </span>
                      )}
                    </div>
                    <p className="text-xs sm:text-sm text-slate-400 italic line-clamp-1 mt-0.5">
                      &ldquo;{cand.tagline}&rdquo;
                    </p>
                  </div>
                </div>

                {/* Angka Suara & Persentase Raksasa */}
                <div className="flex items-center justify-between sm:justify-end gap-6 text-right">
                  <div>
                    <span className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight">
                      {cand.votes}
                    </span>
                    <span className="text-xs font-semibold text-slate-400 ml-1.5 uppercase">Suara</span>
                  </div>

                  <div 
                    className="text-2xl sm:text-3xl lg:text-4xl font-black px-4 py-1.5 rounded-2xl border shadow-inner min-w-[110px] text-center"
                    style={{ 
                      color: cand.avatar_color,
                      backgroundColor: `${cand.avatar_color}15`,
                      borderColor: `${cand.avatar_color}40`
                    }}
                  >
                    {cand.percentage}%
                  </div>
                </div>
              </div>

              {/* Progress Bar Grafik Raksasa */}
              <div className="w-full bg-slate-950 rounded-2xl h-6 sm:h-8 p-1.5 border border-slate-800/80 overflow-hidden shadow-inner">
                <div
                  className="h-full rounded-xl transition-all duration-1000 ease-out relative shadow-lg"
                  style={{
                    width: `${Math.max(cand.percentage, 1)}%`,
                    backgroundColor: cand.avatar_color,
                  }}
                >
                  {/* Animasi Shimmer Efek Berkilau pada Grafik */}
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent animate-[shimmer_2s_infinite]" />
                </div>
              </div>
            </div>
          );
        })}
      </main>

      {/* Footer Stage MC */}
      <footer className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-6 border-t border-slate-800/80 text-xs text-slate-400 relative z-10">
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-emerald-400 animate-pulse" />
          <span>Sinkronisasi Otomatis Setiap 3 Detik</span>
        </div>

        <div className="flex items-center gap-4">
          <Link href="/" className="hover:text-white transition">
            Bilik Suara Mahasiswa
          </Link>
          <span>•</span>
          <Link href="/admin" className="hover:text-white transition">
            Dashboard Manajemen Admin
          </Link>
        </div>
      </footer>
    </div>
  );
}
