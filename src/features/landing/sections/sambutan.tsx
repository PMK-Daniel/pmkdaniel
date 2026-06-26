import { cn } from "@/lib/utils";
import Image from "next/image";

const dataKetua = [
    {
        nama: "Bastian Nevan Baruch",
        jabatan: "Ketua Umum PMK Daniel 2026",
        imgUrl: "/images/bastian.webp",
        quote: "Shalom teman-teman semua, selamat datang di keluarga besar PMK Daniel FILKOM UB. Kita sangat bersyukur atas penyertaan Tuhan sehingga kita bisa berkumpul dan melayani bersama di kampus ini. PMK Daniel bukan sekadar komunitas biasa, tapi rumah rohani tempat kita bisa bertumbuh, berbagi beban, dan saling menguatkan. Mari melangkah bersama membawa terang kasih Kristus. Tuhan Yesus memberkati."
    },
    {
        nama: "Christo Alfredo Sitorus",
        jabatan: "Wakil Ketua Umum PMK Daniel 2026",
        imgUrl: "/images/christo.webp",
        quote: "Shalom dan selamat bergabung bersama kita di PMK Daniel FILKOM UB. Masa perkuliahan pasti punya banyak tantangan, makanya kita hadir sebagai keluarga yang siap mendukung satu sama lain. Semoga teman-teman merasa nyaman di sini dan rindu untuk ikut ambil bagian dalam berbagai pelayanan. Tetap semangat kuliahnya dan biarlah hidup kita terus menjadi berkat buat sesama mahasiswa."
    }
]

export default function Sambutan() {
    return (
        <section className={cn(
            "w-full",
            "py-16 sm:py-24 md:py-32 lg:py-38",
            "px-4 sm:px-8 md:px-12 lg:px-16"
        )}>
            <h1 className={cn(
                "font-plusJakarta font-bold text-primary",
                "text-2xl sm:text-3xl md:text-4xl xl:text-[64px]"
            )}>
                Kata Sambutan
            </h1>
            <h2 className={cn(
                "font-plusJakarta font-normal mt-2",
                "text-base sm:text-lg xl:text-2xl"
            )}>
                Ketua dan Wakil Ketua Umum PMK Daniel 2026
            </h2>

            <div className={cn(
                "grid grid-cols-1 lg:grid-cols-2 w-full",
                "gap-4 sm:gap-6 lg:gap-8",
                "relative mt-8 sm:mt-12 lg:mt-14"
            )}>
                {dataKetua.map((data) => (
                    <div key={data.nama} className={cn(
                        "w-full relative overflow-hidden group",
                        "h-100 sm:h-112.5 lg:h-125", 
                        "rounded-[32px] sm:rounded-[48px] lg:rounded-[64px]",
                        "border border-black/5 bg-white shadow-sm" 
                    )}>
                        <div className="absolute inset-0 z-10 transition-opacity duration-500 ease-in-out group-hover:opacity-0 group-hover:pointer-events-none">
                            <Image 
                                src={data.imgUrl} 
                                alt={data.nama} 
                                fill 
                                className="object-cover" 
                            />
                            <div className="absolute inset-0 bg-linear-to-t from-black/70 via-black/20 to-transparent" />
                            
                            <h3 className={cn(
                                "absolute bottom-14 sm:bottom-16 lg:bottom-20",
                                "left-4 sm:left-6 lg:left-10 right-4",
                                "font-plusJakarta font-bold text-white",
                                "text-lg sm:text-xl lg:text-2xl xl:text-[32px] leading-tight"
                            )}>
                                {data.nama}
                            </h3>
                            <p className={cn(
                                "absolute bottom-6 sm:bottom-8 lg:bottom-10",
                                "left-4 sm:left-6 lg:left-10 right-4",
                                "font-plusJakarta font-normal text-white/90",
                                "text-sm sm:text-base lg:text-lg"
                            )}>
                                {data.jabatan}
                            </p>
                        </div>

                        <div className="absolute inset-0 p-6 sm:p-8 lg:p-10 flex flex-col justify-between transition-opacity duration-500 ease-in-out group-hover:opacity-100 bg-white">
                            <Image src="/images/quote.svg" alt="Quote" width={40} height={40} />
                            
                            <p className="font-plusJakarta text-sm sm:text-base lg:text-lg xl:text-2xl text-neutral-700 leading-relaxed mt-10 grow overflow-y-hidden">
                                {data.quote}
                            </p>
                            <div className="mt-4 pt-4 border-t border-neutral-100 text-right">
                                <h4 className="font-plusJakarta font-bold text-black text-base sm:text-lg lg:text-xl xl:text-2xl">
                                    {data.nama}
                                </h4>
                                <p className="font-plusJakarta font-normal text-xs sm:text-base text-neutral-500">
                                    {data.jabatan}
                                </p>
                            </div>
                        </div>

                    </div>
                ))}
            </div>

        </section>
    );
}