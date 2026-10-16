import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminToken } from '../auth/route';
import { globalStore } from '@/lib/store';
import { CANDIDATES } from '@/lib/candidates';
import { Candidate, CandidateId } from '@/types/voting';

export async function GET() {
  const candidates = globalStore.customCandidates || CANDIDATES;
  return NextResponse.json({
    success: true,
    candidates,
  });
}

export async function POST(req: NextRequest) {
  try {
    const adminSession = req.cookies.get('admin_session')?.value;
    if (!verifyAdminToken(adminSession)) {
      return NextResponse.json(
        { success: false, message: 'Akses ditolak: Hanya admin yang dapat mengedit kandidat.' },
        { status: 401 }
      );
    }

    const body = await req.json();
    const { id, displayName, tagline, vision, mission, avatarColor } = body;

    if (!id) {
      return NextResponse.json(
        { success: false, message: 'ID Kandidat wajib diisi.' },
        { status: 400 }
      );
    }

    if (!globalStore.customCandidates) {
      globalStore.customCandidates = [...CANDIDATES];
    }

    const index = globalStore.customCandidates.findIndex((c) => c.id === id);
    if (index === -1) {
      return NextResponse.json(
        { success: false, message: 'Kandidat tidak ditemukan.' },
        { status: 404 }
      );
    }

    // Update field kandidat
    globalStore.customCandidates[index] = {
      ...globalStore.customCandidates[index],
      displayName: displayName || globalStore.customCandidates[index].displayName,
      name: displayName || globalStore.customCandidates[index].name,
      tagline: tagline !== undefined ? tagline : globalStore.customCandidates[index].tagline,
      vision: vision !== undefined ? vision : globalStore.customCandidates[index].vision,
      mission: Array.isArray(mission) ? mission : globalStore.customCandidates[index].mission,
      avatarColor: avatarColor || globalStore.customCandidates[index].avatarColor,
    };

    return NextResponse.json({
      success: true,
      message: `Data kandidat ${globalStore.customCandidates[index].displayName} berhasil diperbarui.`,
      candidate: globalStore.customCandidates[index],
    });
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan saat mengupdate data';
    return NextResponse.json(
      { success: false, message: errorMsg },
      { status: 500 }
    );
  }
}
