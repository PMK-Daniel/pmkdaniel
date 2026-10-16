import { NextRequest, NextResponse } from 'next/server';
import { isValidUbStudentEmail, hashVoterEmail } from '@/lib/security';
import { getSupabaseServerClient } from '@/lib/supabase';
import { globalStore } from '@/lib/store';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { email } = body;

    if (!email) {
      return NextResponse.json(
        { success: false, message: 'Alamat email wajib diisi.' },
        { status: 400 }
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    // 1. Validasi Domain Resmi Mahasiswa UB
    if (!isValidUbStudentEmail(normalizedEmail)) {
      return NextResponse.json(
        {
          success: false,
          message:
            'Akses ditolak: Hanya email resmi mahasiswa Universitas Brawijaya (@student.ub.ac.id) yang berhak memberikan suara.',
        },
        { status: 403 }
      );
    }

    const emailHash = hashVoterEmail(normalizedEmail);
    const supabase = getSupabaseServerClient();

    // 2. Cek apakah email sudah pernah memberikan suara
    let hasAlreadyVoted = false;
    try {
      const { data: voterData, error: voterCheckError } = await supabase
        .from('voter_registry')
        .select('has_voted')
        .eq('email_hash', emailHash)
        .maybeSingle();

      if (!voterCheckError && voterData?.has_voted) {
        hasAlreadyVoted = true;
      } else if (voterCheckError) {
        hasAlreadyVoted = globalStore.mockVoterRegistry?.has(emailHash) || false;
      }
    } catch {
      hasAlreadyVoted = globalStore.mockVoterRegistry?.has(emailHash) || false;
    }

    if (hasAlreadyVoted) {
      return NextResponse.json(
        {
          success: false,
          message:
            'Email mahasiswa ini sudah pernah digunakan untuk voting. Setiap mahasiswa hanya memiliki 1 (satu) hak suara.',
        },
        { status: 400 }
      );
    }

    // 3. Kirim OTP via Supabase Auth
    let otpSentViaSupabase = false;
    let fallbackCode: string | null = null;

    try {
      const { error: otpError } = await supabase.auth.signInWithOtp({
        email: normalizedEmail,
        options: {
          shouldCreateUser: true,
        },
      });

      if (!otpError) {
        otpSentViaSupabase = true;
      } else {
        console.warn('Supabase signInWithOtp notice:', otpError.message);
      }
    } catch (e) {
      console.warn('Supabase auth network notice:', e);
    }

    // Sediakan fallback kode 6 digit jika Supabase email rate limit tercapai saat pengujian
    const generatedCode = Math.floor(100000 + Math.random() * 900000).toString();
    globalStore.mockOtpStore!.set(normalizedEmail, {
      code: generatedCode,
      expires: Date.now() + 10 * 60 * 1000, // 10 menit
    });

    // Tampilkan fallbackCode jika Supabase gagal kirim ATAU sedang dalam mode development lokal
    if (!otpSentViaSupabase || process.env.NODE_ENV !== 'production') {
      fallbackCode = generatedCode;
    }

    return NextResponse.json({
      success: true,
      message: `Kode verifikasi telah dikirimkan ke ${normalizedEmail}. Silakan periksa kotak masuk atau spam email Anda.`,
      fallbackCode: fallbackCode,
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
