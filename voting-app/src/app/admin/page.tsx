'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { 
  BarChart3, 
  Lock, 
  Users, 
  Edit3, 
  Trash2, 
  Plus, 
  Minus, 
  RefreshCw, 
  Vote, 
  Trophy, 
  LogOut, 
  Printer, 
  CheckCircle2, 
  Clock, 
  Tv, 
  Save, 
  AlertCircle,
  FileSpreadsheet
} from 'lucide-react';
import { CandidateTally, Candidate } from '@/types/voting';

type AdminTab = 'TALLY' | 'VOTERS' | 'EDIT_CANDIDATES' | 'MANAGE_VOTES';

export default function AdminDashboardPage() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);
  const [adminPassword, setAdminPassword] = useState('');
  const [loginError, setLoginError] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  // Active Tab
  const [activeTab, setActiveTab] = useState<AdminTab>('TALLY');

  // Dashboard Data
  const [totalVotes, setTotalVotes] = useState<number>(0);
  const [results, setResults] = useState<CandidateTally[]>([]);
  const [voters, setVoters] = useState<any[]>([]);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [lastUpdated, setLastUpdated] = useState<string | null>(null);
  const [isLoadingData, setIsLoadingData] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  // Edit Candidate State
  const [editingCandidate, setEditingCandidate] = useState<Candidate | null>(null);
  const [isSavingCandidate, setIsSavingCandidate] = useState(false);

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

  // 2. Ambil Semua Informasi Pemilih (All Info)
  const fetchVoters = useCallback(async () => {
    try {
      const res = await fetch('/api/admin/voters');
      const data = await res.json();
      if (data.success) {
        setVoters(data.voters || []);
      }
    } catch (e) {
      console.error('Fetch voters error:', e);
    }
  }, []);

  // 3. Ambil Daftar Kandidat untuk Diedit
  const fetchCandidates = useCallback(async () => {
    try {
      const res = await fetch('/api/admin/candidates');
      const data = await res.json();
      if (data.success) {
        setCandidates(data.candidates || []);
      }
    } catch (e) {
      console.error('Fetch candidates error:', e);
    }
  }, []);

  useEffect(() => {
    fetchTally();
  }, [fetchTally]);

  useEffect(() => {
    if (isAuthenticated) {
      fetchVoters();
      fetchCandidates();
    }
  }, [isAuthenticated, fetchVoters, fetchCandidates]);

  // 4. Login Admin
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
      fetchVoters();
      fetchCandidates();
    } catch (err: unknown) {
      setLoginError(err instanceof Error ? err.message : 'Login gagal');
    } finally {
      setIsLoggingIn(false);
    }
  };

  // 5. Logout Admin
  const handleLogout = async () => {
    try {
      await fetch('/api/admin/logout', { method: 'POST' });
      setIsAuthenticated(false);
    } catch (e) {
      console.error('Logout error:', e);
    }
  };

  // 6. Simpan Perubahan Kandidat
  const handleSaveCandidate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingCandidate) return;

    setIsSavingCandidate(true);
    setStatusMessage(null);
    try {
      const res = await fetch('/api/admin/candidates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editingCandidate),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || 'Gagal menyimpan perubahan');
      }

      setStatusMessage(data.message);
      setEditingCandidate(null);
      fetchCandidates();
      fetchTally();
    } catch (err: unknown) {
      setStatusMessage(err instanceof Error ? err.message : 'Gagal menyimpan');
    } finally {
      setIsSavingCandidate(false);
    }
  };

  // 7. Koreksi / Edit Suara (Tambah / Kurang)
  const handleAdjustVote = async (candidateId: string, countChange: number) => {
    if (!confirm(`Konfirmasi: Ubah suara kandidat ${candidateId} sebesar ${countChange > 0 ? '+' + countChange : countChange}?`)) return;

    try {
      const res = await fetch('/api/admin/votes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'adjust_count',
          candidateId,
          countChange,
        }),
      });

      const data = await res.json();
      if (data.success) {
        fetchTally();
        setStatusMessage(data.message);
      }
    } catch (e) {
      console.error('Adjust vote error:', e);
    }
  };

  // 8. Reset Seluruh Suara
  const handleResetAllVotes = async () => {
    if (!confirm('PERINGATAN: Apakah Anda yakin ingin mereset SELURUH data suara dan pemilih menjadi 0? Tindakan ini tidak dapat dibatalkan!')) return;

    try {
      const res = await fetch('/api/admin/votes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'reset_all' }),
      });

      const data = await res.json();
      if (data.success) {
        fetchTally();
        fetchVoters();
        setStatusMessage(data.message);
      }
    } catch (e) {
      console.error('Reset votes error:', e);
    }
  };

  // Hitung Kandidat Unggul
  const sortedResults = [...results].sort((a, b) => b.votes - a.votes);
  const leadingCandidate = sortedResults.length > 0 && sortedResults[0].votes > 0 ? sortedResults[0] : null;

  // Layar Login Jika Belum Login
  if (isAuthenticated === false) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-slate-800 border border-slate-700 rounded-3xl p-6 sm:p-8 text-white shadow-2xl">
          <div className="w-12 h-12 bg-indigo-500/20 text-indigo-400 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-indigo-500/30">
            <Lock className="w-6 h-6" />
          </div>

          <h2 className="text-2xl font-bold text-center mb-1">Otentikasi Administrator</h2>
          <p className="text-xs text-center text-slate-400 mb-6">
            Akses penuh pengelolaan suara, kandidat, dan audit pemilihan PMK Daniel.
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
                Default: <code className="text-indigo-300 font-mono">pmkdaniel2026admin</code>
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
                'Buka Dashboard Admin'
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
                Panel Kontrol Admin Penuh
              </span>
              <span className="text-slate-400 text-xs">• Live Sync</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              Dashboard Manajemen Pemilihan
            </h1>
            <p className="text-xs sm:text-sm text-slate-400 mt-0.5">
              Pemilihan Ketua PMK Daniel FILKOM Universitas Brawijaya
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 sm:gap-3">
            {/* Tombol Buka Layar MC */}
            <Link
              href="/mc"
              target="_blank"
              className="bg-red-600 hover:bg-red-500 text-white px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition shadow-sm"
            >
              <Tv className="w-3.5 h-3.5" />
              Buka Layar MC (Panggung)
            </Link>

            {/* Refresh Button */}
            <button
              type="button"
              onClick={() => { fetchTally(); fetchVoters(); fetchCandidates(); }}
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
              Cetak
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

        {/* Tab Navigation */}
        <div className="max-w-7xl mx-auto mt-6 flex flex-wrap gap-2 border-t border-slate-800 pt-4">
          <button
            type="button"
            onClick={() => setActiveTab('TALLY')}
            className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeTab === 'TALLY'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-800'
            }`}
          >
            <BarChart3 className="w-4 h-4" />
            Rekapitulasi Suara
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('VOTERS')}
            className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeTab === 'VOTERS'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-800'
            }`}
          >
            <Users className="w-4 h-4" />
            Data Lengkap Pemilih ({voters.length})
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('EDIT_CANDIDATES')}
            className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeTab === 'EDIT_CANDIDATES'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-800'
            }`}
          >
            <Edit3 className="w-4 h-4" />
            Kelola & Edit Kandidat
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('MANAGE_VOTES')}
            className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeTab === 'MANAGE_VOTES'
                ? 'bg-red-600 text-white shadow-sm'
                : 'bg-slate-800/80 text-slate-300 hover:bg-slate-800'
            }`}
          >
            <Vote className="w-4 h-4" />
            Koreksi & Reset Suara
          </button>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-6 space-y-6">
        {/* Status Notification Message */}
        {statusMessage && (
          <div className="bg-emerald-50 border border-emerald-300 text-emerald-800 px-4 py-3 rounded-2xl flex items-center justify-between text-xs sm:text-sm shadow-xs">
            <div className="flex items-center gap-2 font-medium">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>{statusMessage}</span>
            </div>
            <button
              type="button"
              onClick={() => setStatusMessage(null)}
              className="text-emerald-700 hover:underline font-bold"
            >
              Tutup
            </button>
          </div>
        )}

        {/* TAB 1: REKAPITULASI SUARA */}
        {activeTab === 'TALLY' && (
          <div className="space-y-6">
            {/* Metric Summary Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Total Suara Masuk</span>
                <div className="text-3xl font-black text-slate-900 tracking-tight mt-1">
                  {totalVotes.toLocaleString('id-ID')}
                </div>
                <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  Surat suara sah terhitung
                </p>
              </div>

              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Perolehan Tertinggi</span>
                <div className="text-2xl font-black text-slate-900 tracking-tight mt-1 truncate">
                  {leadingCandidate ? leadingCandidate.name : 'Belum Ada Suara'}
                </div>
                <p className="text-[11px] text-slate-500 mt-1">
                  {leadingCandidate ? `${leadingCandidate.votes} suara (${leadingCandidate.percentage}%)` : 'Menunggu suara'}
                </p>
              </div>

              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Total Mahasiswa Memilih</span>
                <div className="text-3xl font-black text-slate-900 tracking-tight mt-1">
                  {voters.length} Mahasiswa
                </div>
                <p className="text-[11px] text-slate-500 mt-1">
                  Terverifikasi @student.ub.ac.id
                </p>
              </div>

              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <span className="text-xs font-bold uppercase text-slate-400 tracking-wider">Pembaruan Terakhir</span>
                <div className="text-sm font-bold text-slate-800 tracking-tight mt-2">
                  {lastUpdated ? new Date(lastUpdated).toLocaleTimeString('id-ID') : '-'} WIB
                </div>
                <p className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-slate-400" />
                  Live Sync Aktif
                </p>
              </div>
            </div>

            {/* List Progress per Kandidat */}
            <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-6">
              <h2 className="text-xl font-bold text-slate-900">Perolehan Suara Kandidat</h2>
              <div className="space-y-5">
                {results.map((cand) => {
                  const isWinner = leadingCandidate && leadingCandidate.candidate_id === cand.candidate_id;

                  return (
                    <div
                      key={cand.candidate_id}
                      className={`p-5 rounded-2xl border transition ${
                        isWinner ? 'bg-blue-50/40 border-blue-200' : 'bg-slate-50 border-slate-200'
                      }`}
                    >
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-3">
                        <div className="flex items-center gap-3">
                          <span
                            className="w-10 h-10 rounded-xl text-white font-black flex items-center justify-center text-sm"
                            style={{ backgroundColor: cand.avatar_color }}
                          >
                            0{cand.number}
                          </span>
                          <div>
                            <div className="flex items-center gap-2">
                              <h4 className="font-extrabold text-lg text-slate-900">
                                {cand.display_name}
                              </h4>
                              {isWinner && (
                                <span className="bg-amber-100 text-amber-800 text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                                  <Trophy className="w-3 h-3 text-amber-600" /> Memimpin
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-slate-500 italic">&ldquo;{cand.tagline}&rdquo;</p>
                          </div>
                        </div>

                        <div className="text-right flex sm:flex-col items-center sm:items-end justify-between">
                          <div className="text-2xl font-black text-slate-900">
                            {cand.votes} <span className="text-xs font-normal text-slate-500">suara</span>
                          </div>
                          <div className="text-xs font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded-md">
                            {cand.percentage}%
                          </div>
                        </div>
                      </div>

                      <div className="w-full bg-slate-200 rounded-full h-3.5 overflow-hidden p-0.5">
                        <div
                          className="h-full rounded-full transition-all duration-700 ease-out"
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
          </div>
        )}

        {/* TAB 2: DATA LENGKAP PEMILIH (SEMUA INFORMASI) */}
        {activeTab === 'VOTERS' && (
          <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <h3 className="font-bold text-lg text-slate-900">Data Lengkap Informasi Pemilih</h3>
                <p className="text-xs text-slate-500">
                  Daftar seluruh mahasiswa UB yang telah melakukan voting berserta pilihan dan waktu vote.
                </p>
              </div>
              <span className="text-xs font-semibold bg-blue-50 text-blue-700 px-3 py-1 rounded-full self-start">
                Total: {voters.length} Pemilih
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-slate-600">
                <thead className="bg-slate-50 text-[11px] font-bold uppercase text-slate-500 border-b border-slate-200">
                  <tr>
                    <th className="py-3 px-4">No.</th>
                    <th className="py-3 px-4">Email Mahasiswa UB</th>
                    <th className="py-3 px-4">Pilihan Kandidat</th>
                    <th className="py-3 px-4">Waktu Voting</th>
                    <th className="py-3 px-4">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {voters.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-8 text-center text-slate-400 text-xs">
                        Belum ada mahasiswa yang melakukan voting.
                      </td>
                    </tr>
                  ) : (
                    voters.map((v, i) => (
                      <tr key={i} className="hover:bg-slate-50/80 transition">
                        <td className="py-3.5 px-4 font-mono text-xs">{i + 1}</td>
                        <td className="py-3.5 px-4 font-bold text-slate-900 font-mono text-xs">
                          {v.email}
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="bg-indigo-50 text-indigo-700 px-2.5 py-1 rounded-lg text-xs font-bold capitalize">
                            {v.candidate_name || v.candidate_id}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-xs text-slate-500">
                          {new Date(v.voted_at).toLocaleString('id-ID')}
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="text-emerald-700 bg-emerald-50 text-[11px] px-2.5 py-0.5 rounded-full font-bold">
                            Terekam Sah
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 3: KELOLA & EDIT KANDIDAT */}
        {activeTab === 'EDIT_CANDIDATES' && (
          <div className="space-y-6">
            <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6">
              <h3 className="font-bold text-lg text-slate-900 mb-1">Daftar Kandidat (Klik untuk Edit)</h3>
              <p className="text-xs text-slate-500 mb-6">
                Admin dapat mengubah nama, nomor urut, tagline, visi, misi, serta warna kartu kandidat.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {candidates.map((cand) => (
                  <div
                    key={cand.id}
                    className="p-5 rounded-2xl border border-slate-200 bg-slate-50 hover:bg-white hover:shadow-md transition flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-center justify-between mb-3">
                        <span
                          className="w-8 h-8 rounded-lg text-white font-black text-xs flex items-center justify-center shadow-xs"
                          style={{ backgroundColor: cand.avatarColor }}
                        >
                          0{cand.number}
                        </span>
                        <span className="text-[10px] font-bold text-slate-400 uppercase">
                          ID: {cand.id}
                        </span>
                      </div>
                      <h4 className="font-extrabold text-base text-slate-900">{cand.displayName}</h4>
                      <p className="text-xs text-slate-500 italic mt-1 line-clamp-2">&ldquo;{cand.tagline}&rdquo;</p>
                    </div>

                    <button
                      type="button"
                      onClick={() => setEditingCandidate({ ...cand })}
                      className="mt-4 w-full py-2 px-3 rounded-xl bg-white hover:bg-indigo-50 text-indigo-700 border border-slate-200 text-xs font-bold transition flex items-center justify-center gap-1.5"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                      Edit Informasi Kandidat
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Modal / Form Edit Kandidat */}
            {editingCandidate && (
              <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
                <div className="bg-white rounded-3xl max-w-xl w-full p-6 sm:p-8 shadow-2xl border border-slate-200 text-left animate-in fade-in zoom-in-95 max-h-[90vh] overflow-y-auto">
                  <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-6">
                    <div>
                      <h3 className="text-lg font-bold text-slate-900">
                        Edit Informasi Kandidat #{editingCandidate.number}
                      </h3>
                      <p className="text-xs text-slate-500">Perubahan akan langsung tampil di bilik suara pemilih.</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => setEditingCandidate(null)}
                      className="text-slate-400 hover:text-slate-600 font-bold"
                    >
                      ✕
                    </button>
                  </div>

                  <form onSubmit={handleSaveCandidate} className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                        Nama Tampilan
                      </label>
                      <input
                        type="text"
                        required
                        value={editingCandidate.displayName}
                        onChange={(e) => setEditingCandidate({ ...editingCandidate, displayName: e.target.value })}
                        className="w-full px-4 py-2 text-sm rounded-xl border border-slate-300 focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                        Tagline / Slogan
                      </label>
                      <input
                        type="text"
                        value={editingCandidate.tagline}
                        onChange={(e) => setEditingCandidate({ ...editingCandidate, tagline: e.target.value })}
                        className="w-full px-4 py-2 text-sm rounded-xl border border-slate-300 focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                        Visi
                      </label>
                      <textarea
                        rows={3}
                        value={editingCandidate.vision}
                        onChange={(e) => setEditingCandidate({ ...editingCandidate, vision: e.target.value })}
                        className="w-full px-4 py-2 text-sm rounded-xl border border-slate-300 focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                        Warna Aksen Kartu
                      </label>
                      <input
                        type="color"
                        value={editingCandidate.avatarColor}
                        onChange={(e) => setEditingCandidate({ ...editingCandidate, avatarColor: e.target.value })}
                        className="h-10 w-24 rounded-lg cursor-pointer"
                      />
                    </div>

                    <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
                      <button
                        type="button"
                        onClick={() => setEditingCandidate(null)}
                        className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
                      >
                        Batal
                      </button>
                      <button
                        type="submit"
                        disabled={isSavingCandidate}
                        className="px-5 py-2 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl flex items-center gap-1.5 shadow-sm"
                      >
                        <Save className="w-3.5 h-3.5" />
                        {isSavingCandidate ? 'Menyimpan...' : 'Simpan Perubahan'}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 4: KOREKSI & RESET SUARA */}
        {activeTab === 'MANAGE_VOTES' && (
          <div className="space-y-6">
            <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8">
              <h3 className="font-bold text-lg text-slate-900 mb-1">Koreksi Suara Manual</h3>
              <p className="text-xs text-slate-500 mb-6">
                Admin dapat menambah atau mengurangi perolehan suara kandidat tertentu secara langsung.
              </p>

              <div className="space-y-4">
                {results.map((c) => (
                  <div key={c.candidate_id} className="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-200">
                    <div className="flex items-center gap-3">
                      <span className="w-8 h-8 rounded-lg text-white font-bold text-xs flex items-center justify-center" style={{ backgroundColor: c.avatar_color }}>
                        0{c.number}
                      </span>
                      <span className="font-bold text-slate-900">{c.display_name}</span>
                      <span className="text-xs text-slate-500">({c.votes} suara saat ini)</span>
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => handleAdjustVote(c.candidate_id, -1)}
                        className="w-8 h-8 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 flex items-center justify-center transition"
                        title="Kurangi 1 suara"
                      >
                        <Minus className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleAdjustVote(c.candidate_id, 1)}
                        className="w-8 h-8 rounded-lg bg-emerald-100 hover:bg-emerald-200 text-emerald-700 flex items-center justify-center transition"
                        title="Tambah 1 suara"
                      >
                        <Plus className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Reset All Votes Danger Zone */}
            <div className="bg-red-50 rounded-3xl border border-red-200 p-6 sm:p-8">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-xl bg-red-100 text-red-600 flex items-center justify-center shrink-0">
                  <Trash2 className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-base text-red-900">Reset Seluruh Data Pemilihan</h4>
                  <p className="text-xs text-red-700 mt-0.5 leading-relaxed">
                    Menghapus seluruh perolehan suara di kotak suara dan mereset status pemilih kembali ke 0. Gunakan hanya saat gladi bersih atau memulai pemilihan baru.
                  </p>
                  <button
                    type="button"
                    onClick={handleResetAllVotes}
                    className="mt-4 px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl shadow-sm transition"
                  >
                    Reset Seluruh Suara & Pemilih
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
