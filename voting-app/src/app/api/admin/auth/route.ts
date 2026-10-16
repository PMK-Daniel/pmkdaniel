import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

const ADMIN_SECRET = process.env.ADMIN_SECRET_KEY || 'pmkdaniel2026admin';
const COOKIE_SECRET = process.env.VOTER_PEPPER || 'pmk_admin_secret_key_2026';

export function createAdminToken(): string {
  const payload = `admin_logged_in:${Date.now()}`;
  const signature = crypto.createHmac('sha256', COOKIE_SECRET).update(payload).digest('hex');
  return Buffer.from(`${payload}:${signature}`).toString('base64url');
}

export function verifyAdminToken(token: string | undefined): boolean {
  if (!token) return false;
  try {
    const decoded = Buffer.from(token, 'base64url').toString('utf-8');
    const [payload, signature] = [decoded.substring(0, decoded.lastIndexOf(':')), decoded.substring(decoded.lastIndexOf(':') + 1)];
    const expected = crypto.createHmac('sha256', COOKIE_SECRET).update(payload).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
  } catch {
    return false;
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { password } = body;

    if (!password) {
      return NextResponse.json(
        { success: false, message: 'Kunci sandi admin wajib diisi.' },
        { status: 400 }
      );
    }

    // Perbandingan waktu konstan untuk mencegah timing attack
    const inputBuf = Buffer.from(password);
    const secretBuf = Buffer.from(ADMIN_SECRET);

    const isMatch = inputBuf.length === secretBuf.length && crypto.timingSafeEqual(inputBuf, secretBuf);

    if (!isMatch) {
      return NextResponse.json(
        { success: false, message: 'Kunci sandi admin tidak valid.' },
        { status: 401 }
      );
    }

    const sessionToken = createAdminToken();

    const response = NextResponse.json({
      success: true,
      message: 'Otentikasi admin berhasil.',
    });

    response.cookies.set('admin_session', sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24, // 24 jam
    });

    return response;
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
