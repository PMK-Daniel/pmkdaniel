import PengumumanDetailAdmin from "@/features/admin/pages/pengumuman/section/pengumumanDetail";

interface LimarotiduaikanDetailPageProps {
    params: Promise<{ id: string }>;
}

export default async function LimarotiduaikanDetailPage({ params }: LimarotiduaikanDetailPageProps) {
    const { id } = await params;
    return <PengumumanDetailAdmin id={id} />
}
