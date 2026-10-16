import { NextRequest, NextResponse } from 'next/server';
import { isValidUbStudentEmail, hashVoterEmail, generateVoterToken } from '@/lib/security';
import { getSupabaseServerClient } from '@/lib/supabase';
import { globalStore } from '@/lib/store';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email, code } = body;

    if (!email || !code) {
      return NextResponse.json(
        { success: false, message: 'Email dan kode verifikasi wajib diisi.' },
        { status: 400 }
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    if (!isValidUbStudentEmail(normalizedEmail)) {
      return NextResponse.json(
        { success: false, message: 'Format email tidak valid untuk mahasiswa Universitas Brawijaya.' },
        { status: 400 }
      );
    }

    const supabase = getSupabaseServerClient();
    const emailHash = hashVoterEmail(normalizedEmail);

    // 1. Cek apakah sudah pernah memilih
    let alreadyVoted = false;
    try {
      const { data: voterData, error: vErr } = await supabase
        .from('voter_registry')
        .select('has_voted')
        .eq('email_hash', emailHash)
        .maybeSingle();

      if (!vErr && voterData?.has_voted) {
        alreadyVoted = true;
      } else if (vErr) {
        alreadyVoted = globalStore.mockVoterRegistry?.has(emailHash) || false;
      }
    } catch {
      alreadyVoted = globalStore.mockVoterRegistry?.has(emailHash) || false;
    }

    if (alreadyVoted) {
      return NextResponse.json(
        {
          success: false,
          message: 'Email mahasiswa ini sudah pernah memberikan suara.',
          hasVoted: true,
        },
        { status: 400 }
      );
    }

    // 2. Verifikasi kode OTP
    let isCodeValid = false;

    // Coba via Supabase Auth verifyOtp
    try {
      const { data: authData, error: authErr } = await supabase.auth.verifyOtp({
        email: normalizedEmail,
        token: code.trim(),
        type: 'email',
      });

      if (!authErr && authData?.session) {
        isCodeValid = true;
      }
    } catch (e) {
      console.warn('Supabase verifyOtp notice:', e);
    }

    // Coba via fallback OTP store
    if (!isCodeValid) {
      const stored = globalStore.mockOtpStore?.get(normalizedEmail);
      if (stored && stored.code === code.trim() && stored.expires > Date.now()) {
        isCodeValid = true;
        globalStore.mockOtpStore?.delete(normalizedEmail);
      }
    }

    if (!isCodeValid) {
      return NextResponse.json(
        { success: false, message: 'Kode OTP yang Anda masukkan salah atau sudah kadaluarsa.' },
        { status: 400 }
      );
    }

    // 3. Buat token voting bertanda tangan kriptografi
    const voterToken = generateVoterToken(normalizedEmail);

    return NextResponse.json({
      success: true,
      message: 'Email berhasil diverifikasi sebagai mahasiswa resmi Universitas Brawijaya.',
      token: voterToken,
      email: normalizedEmail,
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
