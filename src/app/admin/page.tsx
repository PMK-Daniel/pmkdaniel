'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { 
  BarChart3, 
  Lock, 
  ShieldAlert, 
  RefreshCw, 
  Vote, 
  Trophy, 
  LogOut, 
  Printer, 
  CheckCircle2, 
  Clock, 
  ShieldCheck,
  TrendingUp,
  AlertCircle
} from 'lucide-react';
import { CandidateTally } from '@/types/voting';

export default function AdminDashboardPage() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);
  const [adminPassword, setAdminPassword] = useState('');
  const [loginError, setLoginError] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  // Dashboard Data
  const [totalVotes, setTotalVotes] = useState<number>(0);
  const [results, setResults] = useState<CandidateTally[]>([]);
  const [lastUpdated, setLastUpdated] = useState<string | null>(null);
  const [isLoadingData, setIsLoadingData] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // 1. Ambil Data Perhitungan Suara
  const fetchTally = useCallback(async () => {
    setIsLoadingData(true);
    try {
      const res = await fetch('/api/admin/tally');
      if (res.status === 401) {
        setIsAuthenticated(false);
        return;
      }
      const data = await res.json();
      if (data.success) {
        setIsAuthenticated(true);
        setTotalVotes(data.total_votes);
        setResults(data.results || []);
        setLastUpdated(data.timestamp || new Date().toISOString());
      }
    } catch (e) {
      console.error('Fetch tally error:', e);
    } finally {
      setIsLoadingData(false);
    }
  }, []);

  useEffect(() => {
    fetchTally();
  }, [fetchTally]);

  // Interval Auto-refresh tiap 5 detik
  useEffect(() => {
    if (!isAuthenticated || !autoRefresh) return;
    const interval = setInterval(() => {
      fetchTally();
    }, 5000);
    return () => clearInterval(interval);
  }, [isAuthenticated, autoRefresh, fetchTally]);

  // 2. Login Admin
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError(null);
    setIsLoggingIn(true);

    try {
      const res = await fetch('/api/admin/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password: adminPassword }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || 'Kunci sandi admin salah.');
      }

      setIsAuthenticated(true);
      setAdminPassword('');
      fetchTally();
    } catch (err: unknown) {
      setLoginError(err instanceof Error ? err.message : 'Login gagal');
    } finally {
      setIsLoggingIn(false);
    }
  };

  // 3. Logout Admin
  const handleLogout = async () => {
    try {
      await fetch('/api/admin/logout', { method: 'POST' });
      setIsAuthenticated(false);
    } catch (e) {
      console.error('Logout error:', e);
    }
  };

  // Hitung Kandidat Unggul
  const sortedResults = [...results].sort((a, b) => b.votes - a.votes);
  const leadingCandidate = sortedResults.length > 0 && sortedResults[0].votes > 0 ? sortedResults[0] : null;

  // Tampilan Login Jika Belum Terotentikasi
  if (isAuthenticated === false) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-slate-800 border border-slate-700 rounded-3xl p-6 sm:p-8 text-white shadow-2xl">
          <div className="w-12 h-12 bg-indigo-500/20 text-indigo-400 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-indigo-500/30">
            <Lock className="w-6 h-6" />
          </div>

          <h2 className="text-2xl font-bold text-center mb-1">Otentikasi Administrator</h2>
          <p className="text-xs text-center text-slate-400 mb-6">
            Dashboard perhitungan suara hanya dapat diakses oleh Panitia / Admin Pemilihan PMK Daniel.
          </p>

          {loginError && (
            <div className="mb-4 bg-red-500/10 border border-red-500/30 text-red-300 text-xs p-3 rounded-xl flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{loginError}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-300 uppercase mb-1">
                Kunci Sandi Admin (Secret Key)
              </label>
              <input
                type="password"
                required
                value={adminPassword}
                onChange={(e) => setAdminPassword(e.target.value)}
                placeholder="Masukkan kata sandi admin..."
                className="w-full px-4 py-2.5 rounded-xl bg-slate-900 border border-slate-700 text-white placeholder-slate-500 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-sm"
              />
              <p className="text-[11px] text-slate-500 mt-1">
                Default pengujian: <code className="text-indigo-300 font-mono">pmkdaniel2026admin</code>
              </p>
            </div>

            <button
              type="submit"
              disabled={isLoggingIn}
              className="w-full bg-indigo-600 hover:bg-indigo-500 disabled:bg-indigo-800 text-white font-semibold py-2.5 px-4 rounded-xl text-sm transition flex items-center justify-center gap-2 shadow-md shadow-indigo-600/30"
            >
              {isLoggingIn ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  Mengotentikasi...
                </>
              ) : (
                <>
                  Buka Dashboard Perhitungan
                </>
              )}
            </button>
          </form>

          <div className="mt-6 pt-4 border-t border-slate-700/60 text-center">
            <Link href="/" className="text-xs text-slate-400 hover:text-white transition">
              ← Kembali ke Bilik Suara
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 pb-16">
      {/* Top Admin Header */}
      <div className="bg-slate-900 text-white border-b border-slate-800 px-4 sm:px-8 py-6">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 text-xs px-2.5 py-0.5 rounded-full font-semibold uppercase">
                Panel Rekapitulasi Suara
              </span>
              <span className="text-slate-400 text-xs">• Live Sync</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              Dashboard Perhitungan Suara Pemilihan
            </h1>
            <p className="text-xs sm:text-sm text-slate-400 mt-0.5">
              Pemilihan Ketua PMK Daniel FILKOM Universitas Brawijaya
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 sm:gap-3">
            {/* Auto Refresh Toggle */}
            <button
              type="button"
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 border transition ${
                autoRefresh
                  ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40'
                  : 'bg-slate-800 text-slate-400 border-slate-700'
              }`}
            >
              <span className={`w-2 h-2 rounded-full ${autoRefresh ? 'bg-emerald-400 animate-pulse' : 'bg-slate-500'}`} />
              Auto-Sync 5s: {autoRefresh ? 'ON' : 'OFF'}
            </button>

            {/* Refresh Button */}
            <button
              type="button"
              onClick={fetchTally}
              disabled={isLoadingData}
              className="bg-slate-800 hover:bg-slate-700 text-white px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 border border-slate-700 transition"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isLoadingData ? 'animate-spin text-indigo-400' : ''}`} />
              Segarkan
            </button>

            {/* Print Report */}
            <button
              type="button"
              onClick={() => window.print()}
              className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 border border-slate-700 transition"
            >
              <Printer className="w-3.5 h-3.5" />
              Cetak Rekap
            </button>

            {/* Logout */}
            <button
              type="button"
              onClick={handleLogout}
              className="bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-500/30 px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition"
            >
              <LogOut className="w-3.5 h-3.5" />
              Keluar
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-8">
        {/* MANDATORY PRIVACY ASSURANCE BANNER (Sesuai Aturan Ketat Pengguna) */}
        <div className="bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 text-white p-5 rounded-2xl shadow-sm border border-indigo-800/60 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-blue-500/20 border border-blue-400/30 text-blue-300 flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5 text-amber-300" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-bold text-sm sm:text-base text-white">
                  Kepatuhan Privasi & Kerahasiaan Suara (Zero-Knowledge Architecture)
                </h3>
                <span className="bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 text-[10px] font-bold px-2 py-0.5 rounded-md">
                  ENFORCED
                </span>
              </div>
              <p className="text-xs text-slate-300 mt-1 max-w-3xl leading-relaxed">
                Sesuai asas kerahasiaan pemilihan umum dan regulasi privasi sistem, <strong>sisi admin tidak memiliki akses dan sama sekali tidak dapat melihat identitas, nama, maupun email pemilih</strong>. Database kotak suara (ballots) terpisah secara kriptografis tanpa relasi pemilih, sehingga pilihan masing-masing mahasiswa terjamin 100% anonim.
              </p>
            </div>
          </div>
          <div className="text-xs text-slate-300 flex items-center gap-1.5 bg-white/5 border border-white/10 px-3 py-1.5 rounded-lg shrink-0">
            <Lock className="w-3.5 h-3.5 text-emerald-400" />
            <span>Blind Ballot Vault Active</span>
          </div>
        </div>

        {/* Metric Summary Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Card 1: Total Suara Masuk */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Total Suara Masuk</span>
              <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
                <Vote className="w-4 h-4" />
              </div>
            </div>
            <div className="text-3xl font-black text-slate-900 tracking-tight">
              {totalVotes.toLocaleString('id-ID')}
            </div>
            <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
              Surat suara terverifikasi sah
            </p>
          </div>

          {/* Card 2: Kandidat Suara Terbanyak */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Perolehan Tertinggi</span>
              <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
                <Trophy className="w-4 h-4" />
              </div>
            </div>
            <div className="text-2xl font-black text-slate-900 tracking-tight truncate">
              {leadingCandidate ? leadingCandidate.name : 'Belum Ada Suara'}
            </div>
            <p className="text-[11px] text-slate-500 mt-1">
              {leadingCandidate ? `${leadingCandidate.votes} suara (${leadingCandidate.percentage}%)` : 'Menunggu pemilih pertama'}
            </p>
          </div>

          {/* Card 3: Jumlah Kandidat */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Kandidat Terdaftar</span>
              <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
                <BarChart3 className="w-4 h-4" />
              </div>
            </div>
            <div className="text-3xl font-black text-slate-900 tracking-tight">
              5 Calon
            </div>
            <p className="text-[11px] text-slate-500 mt-1">
              Joseph, Zoe, Anna, Nata, Chelsea
            </p>
          </div>

          {/* Card 4: Waktu Sinkronisasi Terakhir */}
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Pembaruan Terakhir</span>
              <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <Clock className="w-4 h-4" />
              </div>
            </div>
            <div className="text-sm font-bold text-slate-800 tracking-tight mt-1">
              {lastUpdated ? new Date(lastUpdated).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : '-'} WIB
            </div>
            <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
              <RefreshCw className="w-3 h-3 text-slate-400" />
              Sinkronisasi aktif real-time
            </p>
          </div>
        </div>

        {/* Hasil Perhitungan Rinci (Visual Bar Progress & Tally) */}
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6 pb-4 border-b border-slate-100">
            <div>
              <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-indigo-600" />
                Rekapitulasi Perolehan Suara Kandidat
              </h2>
              <p className="text-xs text-slate-500">
                Data dihitung otomatis dari tabel kotak suara digital.
              </p>
            </div>
            <div className="text-xs text-slate-500 bg-slate-50 px-3 py-1.5 rounded-lg border border-slate-200">
              Total Akumulasi: <strong className="text-slate-800">{totalVotes} Suara</strong>
            </div>
          </div>

          {/* List Progress per Kandidat */}
          <div className="space-y-6">
            {results.map((cand, index) => {
              const isWinner = leadingCandidate && leadingCandidate.candidate_id === cand.candidate_id;

              return (
                <div
                  key={cand.candidate_id}
                  className={`p-4 sm:p-5 rounded-2xl border transition ${
                    isWinner 
                      ? 'bg-blue-50/40 border-blue-200 shadow-xs' 
                      : 'bg-slate-50/60 border-slate-200'
                  }`}
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-3">
                    <div className="flex items-center gap-3">
                      <span
                        className="w-9 h-9 rounded-xl text-white font-black flex items-center justify-center text-sm shadow-xs"
                        style={{ backgroundColor: cand.avatar_color }}
                      >
                        0{cand.number}
                      </span>
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="font-extrabold text-base sm:text-lg text-slate-900">
                            {cand.display_name}
                          </h4>
                          {isWinner && (
                            <span className="bg-amber-100 text-amber-800 border border-amber-300 text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                              <Trophy className="w-3 h-3 text-amber-600" />
                              Memimpin
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-slate-500 italic">
                          &ldquo;{cand.tagline}&rdquo;
                        </p>
                      </div>
                    </div>

                    <div className="text-right flex sm:flex-col items-center sm:items-end justify-between sm:justify-center">
                      <div className="text-xl sm:text-2xl font-black text-slate-900">
                        {cand.votes} <span className="text-xs font-normal text-slate-500">suara</span>
                      </div>
                      <div className="text-xs font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded-md">
                        {cand.percentage}%
                      </div>
                    </div>
                  </div>

                  {/* Progress Bar */}
                  <div className="w-full bg-slate-200 rounded-full h-3.5 overflow-hidden p-0.5">
                    <div
                      className="h-full rounded-full transition-all duration-700 ease-out shadow-xs"
                      style={{
                        width: `${Math.max(cand.percentage, 0.5)}%`,
                        backgroundColor: cand.avatar_color,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Tabel Rekapitulasi Resmi (Printable & Export Ready) */}
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="p-6 pb-4 border-b border-slate-100">
            <h3 className="font-bold text-base text-slate-900">Tabel Rekapitulasi Berita Acara</h3>
            <p className="text-xs text-slate-500">Format rekapitulasi standar untuk berita acara pemilihan umum PMK Daniel.</p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-600">
              <thead className="bg-slate-50 text-[11px] font-bold uppercase text-slate-500 border-b border-slate-200">
                <tr>
                  <th className="py-3 px-4">No. Urut</th>
                  <th className="py-3 px-4">Nama Calon</th>
                  <th className="py-3 px-4 text-center">Jumlah Perolehan Suara</th>
                  <th className="py-3 px-4 text-center">Persentase (%)</th>
                  <th className="py-3 px-4 text-center">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {results.map((c) => (
                  <tr key={c.candidate_id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3.5 px-4 font-mono font-bold text-slate-900">0{c.number}</td>
                    <td className="py-3.5 px-4 font-bold text-slate-900">{c.display_name}</td>
                    <td className="py-3.5 px-4 text-center font-bold text-slate-800">{c.votes} suara</td>
                    <td className="py-3.5 px-4 text-center font-bold text-indigo-700">{c.percentage}%</td>
                    <td className="py-3.5 px-4 text-center">
                      {leadingCandidate?.candidate_id === c.candidate_id ? (
                        <span className="bg-amber-100 text-amber-800 text-[11px] px-2.5 py-0.5 rounded-full font-bold">
                          Unggul
                        </span>
                      ) : (
                        <span className="text-slate-400 text-xs">-</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-slate-50 font-bold text-slate-900 border-t border-slate-200">
                <tr>
                  <td colSpan={2} className="py-3 px-4 text-left uppercase text-xs">Total Seluruh Suara Sah</td>
                  <td className="py-3 px-4 text-center text-sm">{totalVotes} suara</td>
                  <td className="py-3 px-4 text-center text-sm">100.00%</td>
                  <td className="py-3 px-4 text-center text-xs text-emerald-600">Sah</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        {/* Security Disclaimers Box */}
        <div className="bg-slate-100 rounded-2xl p-4 border border-slate-200 text-xs text-slate-500 flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>Sistem dilindungi arsitektur Anti-Tampering & Secret Ballot Supabase.</span>
          </div>
          <div>
            Terhubung ke Database: <span className="font-mono text-slate-700">xnbiaaxwltofdiklxhnw.supabase.co</span>
          </div>
        </div>
      </div>
    </div>
  );
}
