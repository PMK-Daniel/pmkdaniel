import EmptyPage from "@/components/emptyState";
import { dummyPengumuman } from "../data/pengumumanData"
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import Image from "next/image";


export default function PengumumanDetailAdmin({ id }: { id: string }) {
    const blog = dummyPengumuman.find((data) => data.id === id);

    if (!blog) return <EmptyPage />

    return (
        <section className="w-full min-h-screen py-[73px] px-[70px]">
            <div className="flex items-center gap-2">
                <Link
                    href={"/limarotiduaikan"}
                    className="flex items-center gap-1.5 text-black transition-colors border-b border-transparent hover:border-current pb-0.5"
                >
                    <ArrowLeft size={20} className="mt-1.5" />
                    <p className="font-plusJakarta font-medium text-base sm:text-xl lg:text-2xl leading-none">
                        Back
                    </p>
                </Link>
            </div>

            <h1 className="mt-6 text-primary text-xl md:text-2xl lg:text-3xl xl:text-[40px] font-plusJakarta font-bold">
                Tampilan Pengumuman
            </h1>

            <h2 className="font-plusJakarta font-extrabold text-xl md:text-2xl lg:text-3xl xl:text-[40px] mt-6">
                Camp Daniel 2026 - Open Registration Peserta
            </h2>

            <h3 className="mt-2 font-plusJakarta font-medium text-xl">
                PENGUMUMAN
            </h3>

            <p className="font-plusJakarta font-normal text-base">
                Diunggah 20 Oktober 2026
            </p>

            <div className="w-full h-[50vh] relative  mt-16">
                <Image src='/images/campdanielpengumuman.webp' alt="campdaniel" fill className="object-cover" />
            </div>

            <p className="font-plusJakarta font-normal text-base mt-5">
                Halo, teman-teman! 👋 <br />
                Pendaftaran peserta Camp Daniel 2026 resmi dibuka!
                <br />
                <br />
                Camp Daniel adalah kegiatan kebersamaan untuk bertumbuh dalam iman, membangun relasi, dan menikmati waktu bersama teman-teman PMK Daniel <br/> <br/>
                📅 Tanggal kegiatan: 18&ndash;20 Juli 2026 <br />
                📍 Lokasi: Villa [Nama Lokasi] <br/>
                💰 Biaya pendaftaran: Rp250.000 <br/>
                🗓 Pendaftaran dibuka: 20&ndash;25 Oktober 2026 <br/>
                <br />

                Jangan lewatkan kesempatan ini untuk ikut seru-seruan, mengikuti sesi rohani, games, dan kebersamaan bersama keluarga PMK Daniel.
                <br />
                <br />
                
                Link pendaftaran: https://registrationcampdaniel2025.com
            </p>
        </section>
    )
}