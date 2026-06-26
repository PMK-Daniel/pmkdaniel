import { dataPengumuman } from "@/dataDummy/pengumuman";
import { truncateByWords } from "@/utils/truncate";
import Image from "next/image";
import Link from "next/link";


export default function Pengumuman() {
    const previewPengumuman = dataPengumuman.slice(0, 3);
    return (
        <section className="py-38 px-4 sm:px-8 md:px-12 lg:px-16 w-full ">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="font-plusJakarta font-bold text-primary text-2xl sm:text-3xl md:text-4xl xl:text-[64px]">
                        Pengumuman
                    </h1>
                    <h2 className="font-plusJakarta font-normal text-base sm:text-lg xl:text-2xl mt-2">
                        Simak informasi terbaru dari PMK Daniel!
                    </h2>
                </div>
                <Link href='/pengumuman' className="font-plusJakarta hover:underline font-normal text-[14px] md:text-base lg:text-[16px]">
                    Lihat lebih banyak &rarr;
                </Link>
            </div>

            <div className="w-full grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6 lg:gap-8 mt-6 md:mt-8 lg:mt-10 xl:mt-14 ">
                {previewPengumuman.map((data) => (
                    <div key={data.id} className="flex flex-col items-center border border-black/10 p-6 rounded-[12px] md:rounded-[24px] lg:rounded-[30px] xl:rounded-[32px] w-full">
                        <div className="w-full">
                            <div className="rounded-2xl overflow-hidden aspect-2/3 w-full relative">
                                <Image
                                    src={data.imageUrl}
                                    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 33vw"
                                    alt={data.title}
                                    fill
                                    className="object-cover" />
                            </div>
                            <Link href={`/pengumuman/${data.id}`}>
                                <h3 className="font-plusJakarta hover:underline font-extrabold md:text-xl lg:text-2xl xl:text-[32px] mt-6">
                                    {data.title}
                                </h3>
                            </Link>
                            <p className="mt-3 font-plusJakarta font-normal text-xs lg:text-base">
                                {data.datePublished}
                            </p>
                            <p className="mt-4 font-plusJakarta font-normal text-[14px] md:text-base">
                                {truncateByWords({ text: data.description, wordLimit: 20 })}
                            </p>
                        </div>
                    </div>
                ))}
            </div>

            <div className="text-center mt-14">
                <Link href='/pengumuman' className="font-plusJakarta hover:underline font-normal text-[14px] md:text-base lg:text-[16px]">
                    Lihat lebih banyak &rarr;
                </Link>
            </div>
        </section>
    );
}