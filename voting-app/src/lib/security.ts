import crypto from 'crypto';
import { CandidateId } from '@/types/voting';

const PEPPER = process.env.VOTER_PEPPER || 'pmk_daniel_ub_voting_super_secret_pepper_2026';
const TOKEN_SECRET = process.env.VOTER_PEPPER || 'pmk_token_secret_key_2026';

/**
 * Validasi ketat format email Mahasiswa Universitas Brawijaya
 * Format resmi: username@student.ub.ac.id atau nim@student.ub.ac.id
 */
export function isValidUbStudentEmail(email: string): boolean {
  if (!email || typeof email !== 'string') return false;
  const cleanEmail = email.trim().toLowerCase();
  
  // Format regex: hanya mengizinkan karakter alfanumerik standar sebelum @student.ub.ac.id
  const ubEmailRegex = /^[a-zA-Z0-9._%+-]+@student\.ub\.ac\.id$/;
  return ubEmailRegex.test(cleanEmail);
}

/**
 * Blind / Hash email pemilih dengan HMAC-SHA256 dan pepper rahasia.
 * Menghasilkan hash satu arah yang aman dari serangan rainbow table.
 */
export function hashVoterEmail(email: string): string {
  const normalizedEmail = email.trim().toLowerCase();
  return crypto.createHmac('sha256', PEPPER).update(normalizedEmail).digest('hex');
}

/**
 * Verifikasi apakah kandidat yang dipilih ada dalam whitelist
 */
export function isCandidateValid(candidateId: string): candidateId is CandidateId {
  const allowed: CandidateId[] = ['joseph', 'zoe', 'anna', 'nata', 'chelsea'];
  return allowed.includes(candidateId as CandidateId);
}

/**
 * Buat token voting berjangka waktu (signed voter token) setelah verifikasi email berhasil
 */
export function generateVoterToken(email: string): string {
  const normalizedEmail = email.trim().toLowerCase();
  const timestamp = Date.now();
  const payload = `${normalizedEmail}:${timestamp}`;
  const signature = crypto.createHmac('sha256', TOKEN_SECRET).update(payload).digest('hex');
  return Buffer.from(`${payload}:${signature}`).toString('base64url');
}

/**
 * Validasi token voting
 */
export function verifyVoterToken(token: string): { valid: boolean; email?: string; error?: string } {
  try {
    const decoded = Buffer.from(token, 'base64url').toString('utf-8');
    const parts = decoded.split(':');
    if (parts.length !== 3) {
      return { valid: false, error: 'Format token tidak valid' };
    }

    const [email, timestampStr, signature] = parts;
    const timestamp = parseInt(timestampStr, 10);

    // Cek kadaluarsa token (berlaku 1 jam)
    const ONE_HOUR = 60 * 60 * 1000;
    if (Date.now() - timestamp > ONE_HOUR) {
      return { valid: false, error: 'Sesi verifikasi voting telah kadaluarsa. Silakan verifikasi ulang.' };
    }

    // Cek keaslian tanda tangan kriptografi
    const expectedPayload = `${email}:${timestampStr}`;
    const expectedSignature = crypto.createHmac('sha256', TOKEN_SECRET).update(expectedPayload).digest('hex');

    if (crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature))) {
      return { valid: true, email };
    }

    return { valid: false, error: 'Integritas token tidak valid' };
  } catch {
    return { valid: false, error: 'Gagal memproses token verifikasi' };
  }
}
