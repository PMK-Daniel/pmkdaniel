'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import confetti from 'canvas-confetti';
import { 
  ShieldCheck, 
  Mail, 
  KeyRound, 
  Vote, 
  CheckCircle2, 
  AlertCircle, 
  Lock, 
  ArrowRight, 
  FileText, 
  Info,
  ChevronRight,
  RefreshCw,
  Sparkles,
  X
} from 'lucide-react';
import { CANDIDATES } from '@/lib/candidates';
import { Candidate, CandidateId } from '@/types/voting';

type VotingStep = 'EMAIL_INPUT' | 'OTP_INPUT' | 'SELECT_CANDIDATE' | 'CONFIRMATION' | 'SUCCESS';

export default function VotingPage() {
  const [step, setStep] = useState<VotingStep>('EMAIL_INPUT');
  const [email, setEmail] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [voterToken, setVoterToken] = useState<string | null>(null);
  const [selectedCandidate, setSelectedCandidate] = useState<Candidate | null>(null);
  const [detailCandidate, setDetailCandidate] = useState<Candidate | null>(null);
  
  // Status states
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [infoMessage, setInfoMessage] = useState<string | null>(null);
  const [testOtpHint, setTestOtpHint] = useState<string | null>(null);
  const [receiptHash, setReceiptHash] = useState<string | null>(null);

  // 1. Kirim OTP ke email student.ub.ac.id
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setInfoMessage(null);
    setTestOtpHint(null);

    const cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.endsWith('@student.ub.ac.id')) {
      setErrorMessage('Alamat email wajib menggunakan domain resmi mahasiswa Universitas Brawijaya (@student.ub.ac.id)');
      return;
    }

    setIsLoading(true);
    try {
      const res = await fetch('/api/auth/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: cleanEmail }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || 'Gagal mengirim kode verifikasi.');
      }

      setInfoMessage(data.message);
      if (data.fallbackCode) {
        setTestOtpHint(data.fallbackCode);
      }
      setStep('OTP_INPUT');
    } catch (err: unknown) {
      setErrorMessage(err instanceof Error ? err.message : 'Terjadi kesalahan');
    } finally {
      setIsLoading(false);
    }
  };

  // 2. Verifikasi OTP
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setInfoMessage(null);

    if (!otpCode || otpCode.trim().length < 4) {
      setErrorMessage('Masukkan kode verifikasi OTP yang valid.');
      return;
    }

    setIsLoading(true);
    try {
      const res = await fetch('/api/auth/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          email: email.trim().toLowerCase(), 
          code: otpCode.trim() 
        }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || 'Verifikasi kode gagal.');
      }

      setVoterToken(data.token);
      setInfoMessage('Identitas Anda berhasil diverifikasi. Silakan tentukan pilihan Anda secara rahasia.');
      setStep('SELECT_CANDIDATE');
    } catch (err: unknown) {
      setErrorMessage(err instanceof Error ? err.message : 'Terjadi kesalahan saat memverifikasi.');
    } finally {
      setIsLoading(false);
    }
  };

  // 3. Konfirmasi Suara
  const handleInitiateConfirm = (candidate: Candidate) => {
    setSelectedCandidate(candidate);
    setStep('CONFIRMATION');
  };

  // 4. Kirim Suara Final (Zero-Knowledge Submission)
  const handleFinalVote = async () => {
    if (!voterToken || !selectedCandidate) return;

    setErrorMessage(null);
    setIsLoading(true);
    try {
      const res = await fetch('/api/vote/cast', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: voterToken,
          candidateId: selectedCandidate.id,
        }),
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.message || 'Gagal merekam suara.');
      }

      setReceiptHash(data.receiptHash);
      setStep('SUCCESS');

      // Efek konfeti selebrasi voting berhasil
      try {
        confetti({
          particleCount: 120,
          spread: 70,
          origin: { y: 0.6 },
        });
      } catch {
        // Fallback jika visual confetti gagal
      }
    } catch (err: unknown) {
      setErrorMessage(err instanceof Error ? err.message : 'Gagal mengirim suara.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 flex flex-col">
      {/* Hero Header */}
      <section className="bg-gradient-to-b from-blue-900 via-indigo-900 to-slate-900 text-white py-12 px-4 sm:px-6 lg:px-8 border-b border-indigo-950/60 shadow-lg relative overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(#3b82f6_1px,transparent_1px)] [background-size:16px_16px] opacity-20 pointer-events-none" />
        <div className="max-w-4xl mx-auto text-center relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/20 border border-blue-400/30 text-blue-200 text-xs font-semibold uppercase tracking-wider mb-4">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Sistem Pemilihan Resmi Universitas Brawijaya</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight mb-4 text-balance">
            E-Voting Pemilihan Ketua <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-300 via-indigo-200 to-amber-200">
              PMK Daniel FILKOM UB
            </span>
          </h1>
          <p className="text-slate-300 text-sm sm:text-base max-w-2xl mx-auto leading-relaxed">
            Gunakan hak suara Anda secara demokratis, aman, dan berintegritas. Sistem dirancang dengan arsitektur kerahasiaan suara mutlak (Secret Ballot) dan verifikasi email resmi mahasiswa UB.
          </p>

          {/* Security Features Badges */}
          <div className="mt-6 flex flex-wrap items-center justify-center gap-3 text-xs text-slate-300">
            <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-lg border border-white/10">
              <Lock className="w-3.5 h-3.5 text-amber-300" />
              Anonimitas Terjamin
            </span>
            <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-lg border border-white/10">
              <Mail className="w-3.5 h-3.5 text-blue-300" />
              1 Mahasiswa 1 Suara (@student.ub.ac.id)
            </span>
            <span className="flex items-center gap-1.5 bg-white/10 px-3 py-1 rounded-lg border border-white/10">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-300" />
              Perlindungan Double Voting
            </span>
          </div>
        </div>
      </section>

      {/* Main Body Content */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full flex-1">
        {/* Alerts Banner */}
        {errorMessage && (
          <div className="mb-6 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl flex items-start gap-3 shadow-xs">
            <AlertCircle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
            <div className="text-sm">
              <p className="font-semibold">Peringatan</p>
              <p>{errorMessage}</p>
            </div>
          </div>
        )}

        {infoMessage && (
          <div className="mb-6 bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded-xl flex items-start gap-3 shadow-xs">
            <Info className="w-5 h-5 text-blue-500 shrink-0 mt-0.5" />
            <div className="text-sm">
              <p className="font-semibold">Informasi Sistem</p>
              <p>{infoMessage}</p>
            </div>
          </div>
        )}

        {testOtpHint && (
          <div className="mb-6 bg-amber-50 border border-amber-300 text-amber-900 px-4 py-3 rounded-xl flex items-center justify-between shadow-xs">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-amber-600" />
              <span className="text-xs sm:text-sm font-medium">
                Mode Simulasi/Dev: Kode OTP Pengujian Anda adalah: <strong className="text-base tracking-widest font-mono text-amber-800">{testOtpHint}</strong>
              </span>
            </div>
            <button
              type="button"
              onClick={() => setOtpCode(testOtpHint)}
              className="text-xs bg-amber-200 hover:bg-amber-300 text-amber-900 px-2.5 py-1 rounded font-semibold transition"
            >
              Tempel Kode
            </button>
          </div>
        )}

        {/* STEP 1: Input Email UB */}
        {step === 'EMAIL_INPUT' && (
          <div className="max-w-md mx-auto bg-white rounded-2xl shadow-sm border border-slate-200 p-6 sm:p-8">
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center text-blue-600 mb-4 mx-auto">
              <Mail className="w-6 h-6" />
            </div>
            <h2 className="text-xl font-bold text-center text-slate-900 mb-1">Verifikasi Mahasiswa UB</h2>
            <p className="text-xs text-center text-slate-500 mb-6">
              Masukkan email universitas resmi Anda untuk menerima kode OTP verifikasi suara.
            </p>

            <form onSubmit={handleSendOtp} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                  Email Student Universitas Brawijaya
                </label>
                <div className="relative">
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="nama_mhs@student.ub.ac.id"
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-300 focus:outline-hidden focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                  />
                </div>
                <p className="text-[11px] text-slate-500 mt-1">
                  Format wajib berakhiran: <span className="font-mono font-medium text-slate-700">@student.ub.ac.id</span>
                </p>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-2.5 px-4 rounded-xl text-sm transition flex items-center justify-center gap-2 shadow-sm"
              >
                {isLoading ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Memverifikasi email...
                  </>
                ) : (
                  <>
                    Kirim Kode OTP Verifikasi
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </form>

            <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-center gap-2 text-xs text-slate-500">
              <Lock className="w-3.5 h-3.5 text-slate-400" />
              <span>Email Anda hanya digunakan untuk autentikasi 1-suara.</span>
            </div>
          </div>
        )}

        {/* STEP 2: Input OTP */}
        {step === 'OTP_INPUT' && (
          <div className="max-w-md mx-auto bg-white rounded-2xl shadow-sm border border-slate-200 p-6 sm:p-8">
            <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center text-indigo-600 mb-4 mx-auto">
              <KeyRound className="w-6 h-6" />
            </div>
            <h2 className="text-xl font-bold text-center text-slate-900 mb-1">Masukkan Kode OTP</h2>
            <p className="text-xs text-center text-slate-500 mb-6">
              Kode verifikasi telah dikirimkan ke <strong className="text-slate-800">{email}</strong>
            </p>

            <form onSubmit={handleVerifyOtp} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase mb-1 text-center">
                  6 Digit Kode Verifikasi
                </label>
                <input
                  type="text"
                  required
                  maxLength={6}
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  placeholder="123456"
                  className="w-full text-center tracking-widest text-2xl font-mono py-2.5 rounded-xl border border-slate-300 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white font-medium py-2.5 px-4 rounded-xl text-sm transition flex items-center justify-center gap-2 shadow-sm"
              >
                {isLoading ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Memvalidasi Kode...
                  </>
                ) : (
                  <>
                    Verifikasi & Buka Bilik Suara
                    <ChevronRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <div className="flex items-center justify-between text-xs text-slate-500 pt-2">
                <button
                  type="button"
                  onClick={() => setStep('EMAIL_INPUT')}
                  className="hover:text-slate-800 underline"
                >
                  Ganti Alamat Email
                </button>
                <button
                  type="button"
                  onClick={handleSendOtp}
                  disabled={isLoading}
                  className="text-indigo-600 hover:text-indigo-800 font-medium"
                >
                  Kirim Ulang Kode
                </button>
              </div>
            </form>
          </div>
        )}

        {/* STEP 3: Bilik Suara (Daftar Kandidat: Joseph, Zoe, Anna, Nata, Chelsea) */}
        {step === 'SELECT_CANDIDATE' && (
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 bg-white p-4 rounded-2xl border border-slate-200">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 text-sm sm:text-base">Bilik Suara Terbuka</h3>
                  <p className="text-xs text-slate-500">
                    Pemilih: <span className="font-mono text-slate-700">{email}</span> (Terverifikasi UB)
                  </p>
                </div>
              </div>
              <div className="text-xs text-slate-500 bg-slate-100 px-3 py-1.5 rounded-lg flex items-center gap-1.5">
                <Lock className="w-3.5 h-3.5 text-amber-600" />
                <span>Pilihan Anda dienkripsi anonim</span>
              </div>
            </div>

            <div className="text-center mb-6">
              <h2 className="text-2xl font-bold text-slate-900">Daftar Calon Ketua PMK Daniel</h2>
              <p className="text-xs sm:text-sm text-slate-500">
                Pilih salah satu dari 5 kandidat resmi di bawah ini dengan menekan tombol &ldquo;PILIH SUARA&rdquo;.
              </p>
            </div>

            {/* Grid 5 Kandidat */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {CANDIDATES.map((cand) => (
                <div
                  key={cand.id}
                  className="bg-white rounded-2xl border border-slate-200 shadow-xs hover:shadow-md transition-all flex flex-col justify-between overflow-hidden relative group"
                >
                  {/* Nomor Urut Banner */}
                  <div
                    className="h-2 w-full"
                    style={{ backgroundColor: cand.avatarColor }}
                  />

                  <div className="p-6">
                    <div className="flex items-center justify-between mb-4">
                      <span
                        className="w-10 h-10 rounded-xl text-white font-bold flex items-center justify-center text-lg shadow-sm"
                        style={{ backgroundColor: cand.avatarColor }}
                      >
                        0{cand.number}
                      </span>
                      <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">
                        Kandidat #{cand.number}
                      </span>
                    </div>

                    <h3 className="text-2xl font-black text-slate-900 tracking-tight mb-1">
                      {cand.displayName}
                    </h3>
                    <p className="text-xs text-slate-600 italic mb-4 min-h-[36px] line-clamp-2">
                      &ldquo;{cand.tagline}&rdquo;
                    </p>

                    <div className="bg-slate-50 rounded-xl p-3 border border-slate-100 mb-4">
                      <p className="text-[11px] font-semibold text-slate-700 uppercase tracking-wide mb-1">
                        Fokus Visi
                      </p>
                      <p className="text-xs text-slate-600 line-clamp-3 leading-relaxed">
                        {cand.vision}
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={() => setDetailCandidate(cand)}
                      className="text-xs text-blue-600 hover:text-blue-800 font-semibold flex items-center gap-1 mb-4"
                    >
                      <FileText className="w-3.5 h-3.5" />
                      Baca Visi & Misi Lengkap →
                    </button>
                  </div>

                  <div className="p-6 pt-0">
                    <button
                      type="button"
                      onClick={() => handleInitiateConfirm(cand)}
                      className="w-full py-2.5 px-4 rounded-xl text-white font-bold text-sm shadow-sm transition hover:opacity-95 flex items-center justify-center gap-2 group-hover:scale-[1.02]"
                      style={{ backgroundColor: cand.avatarColor }}
                    >
                      <Vote className="w-4 h-4" />
                      PILIH {cand.displayName.toUpperCase()}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* STEP 4: Modal Konfirmasi Suara */}
        {step === 'CONFIRMATION' && selectedCandidate && (
          <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-lg w-full p-6 sm:p-8 shadow-2xl border border-slate-100 text-center animate-in fade-in zoom-in-95 duration-200">
              <div 
                className="w-16 h-16 rounded-2xl mx-auto flex items-center justify-center text-white text-2xl font-black shadow-lg mb-4"
                style={{ backgroundColor: selectedCandidate.avatarColor }}
              >
                0{selectedCandidate.number}
              </div>

              <h3 className="text-2xl font-extrabold text-slate-900 mb-1">
                Konfirmasi Pilihan Suara
              </h3>
              <p className="text-sm text-slate-500 mb-4">
                Anda akan memberikan suara kepada:
              </p>

              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 mb-6">
                <p className="text-2xl font-black text-slate-900">{selectedCandidate.displayName}</p>
                <p className="text-xs text-slate-500 italic mt-1">&ldquo;{selectedCandidate.tagline}&rdquo;</p>
              </div>

              <div className="bg-amber-50 border border-amber-200 text-amber-900 text-xs text-left p-3.5 rounded-xl mb-6 flex items-start gap-2.5">
                <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <p className="leading-relaxed">
                  <strong>Penting:</strong> Hak suara Anda bersifat permanen dan rahasia. Setelah dikirim, sistem akan mengunci akun email Anda dan suara tidak dapat diubah kembali.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setStep('SELECT_CANDIDATE')}
                  disabled={isLoading}
                  className="py-3 px-4 rounded-xl border border-slate-300 font-semibold text-slate-700 text-sm hover:bg-slate-100 transition"
                >
                  Kembali
                </button>
                <button
                  type="button"
                  onClick={handleFinalVote}
                  disabled={isLoading}
                  className="py-3 px-4 rounded-xl text-white font-bold text-sm shadow-md transition flex items-center justify-center gap-2"
                  style={{ backgroundColor: selectedCandidate.avatarColor }}
                >
                  {isLoading ? (
                    <>
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      Merekam Suara...
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="w-4 h-4" />
                      Kirim Suara Final
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* STEP 5: Layar Sukses & Bukti Suara Masuk */}
        {step === 'SUCCESS' && (
          <div className="max-w-lg mx-auto bg-white rounded-3xl shadow-sm border border-slate-200 p-8 text-center">
            <div className="w-16 h-16 bg-emerald-100 rounded-2xl flex items-center justify-center text-emerald-600 mx-auto mb-4">
              <CheckCircle2 className="w-10 h-10" />
            </div>

            <span className="bg-emerald-50 text-emerald-700 text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider">
              Suara Berhasil Direkam
            </span>

            <h2 className="text-2xl font-black text-slate-900 mt-2 mb-2">
              Terima Kasih Atas Partisipasi Anda!
            </h2>
            <p className="text-xs sm:text-sm text-slate-500 mb-6 leading-relaxed">
              Hak suara Anda telah sukses dimasukkan ke dalam kotak suara digital secara anonim. Pilihan Anda tidak dapat dilacak oleh siapapun termasuk administrator sistem.
            </p>

            {receiptHash && (
              <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 mb-6 text-left">
                <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wide">
                  Tanda Terima Kriptografi (Proof of Vote)
                </p>
                <p className="font-mono text-sm font-bold text-slate-800 break-all mt-1">
                  {receiptHash}
                </p>
                <p className="text-[10px] text-slate-400 mt-2">
                  Kode ini membuktikan suara Anda terhitung tanpa mengungkap kandidat yang Anda pilih.
                </p>
              </div>
            )}

            <div className="flex flex-col sm:flex-row gap-3">
              <Link
                href="/admin"
                className="flex-1 bg-slate-900 hover:bg-slate-800 text-white font-semibold py-2.5 px-4 rounded-xl text-sm transition flex items-center justify-center gap-2"
              >
                Lihat Perhitungan Suara Admin
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        )}

        {/* Modal Detail Visi & Misi */}
        {detailCandidate && (
          <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-xl w-full p-6 sm:p-8 shadow-2xl border border-slate-100 text-left animate-in fade-in zoom-in-95 duration-200 max-h-[90vh] overflow-y-auto">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-6">
                <div className="flex items-center gap-3">
                  <span
                    className="w-10 h-10 rounded-xl text-white font-bold flex items-center justify-center text-lg"
                    style={{ backgroundColor: detailCandidate.avatarColor }}
                  >
                    0{detailCandidate.number}
                  </span>
                  <div>
                    <h3 className="text-xl font-bold text-slate-900">
                      {detailCandidate.displayName}
                    </h3>
                    <p className="text-xs text-slate-500">Kandidat Ketua PMK Daniel</p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setDetailCandidate(null)}
                  className="w-8 h-8 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center text-slate-500 transition"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="space-y-6">
                <div>
                  <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Visi</h4>
                  <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 text-sm text-slate-700 leading-relaxed">
                    {detailCandidate.vision}
                  </div>
                </div>

                <div>
                  <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Misi</h4>
                  <ul className="space-y-2">
                    {detailCandidate.mission.map((item, idx) => (
                      <li key={idx} className="flex items-start gap-2.5 text-sm text-slate-700 bg-slate-50 p-3 rounded-xl border border-slate-100">
                        <span className="w-5 h-5 rounded-full bg-blue-100 text-blue-700 text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">
                          {idx + 1}
                        </span>
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              <div className="mt-6 pt-4 border-t border-slate-100 flex justify-end">
                <button
                  type="button"
                  onClick={() => setDetailCandidate(null)}
                  className="bg-slate-900 text-white font-semibold text-xs py-2 px-5 rounded-xl hover:bg-slate-800 transition"
                >
                  Tutup
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
