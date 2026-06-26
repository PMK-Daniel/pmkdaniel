import Image from "next/image";

const dataKegiatan = [
  {
    title: "Persekutuan Doa",
    number: "01",
    imageUrl: "/images/persekutuan.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
  {
    title: "Doa Pengurus",
    number: "02",
    imageUrl: "/images/doapengurus.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
  {
    title: "Camp Daniel",
    number: "03",
    imageUrl: "/images/campdaniel.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
  {
    title: "Camp Regenerasi",
    number: "04",
    imageUrl: "/images/campregenerasi.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
  {
    title: "Paskah PMK Daniel",
    number: "05",
    imageUrl: "/images/paskahpmk.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
  {
    title: "Natal PMK Daniel",
    number: "06",
    imageUrl: "/images/natalpmk.webp",
    desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  },
];

export default function Kegiatan() {
  const doubleKegiatan = [...dataKegiatan, ...dataKegiatan];

  return (
    <section className="w-full px-4 sm:px-8 md:px-12 lg:px-16">
      <h1 className="font-plusJakarta font-bold text-primary text-2xl sm:text-3xl md:text-4xl xl:text-[64px]">
        Kegiatan Kami
      </h1>
      <h2 className="font-plusJakarta font-normal text-base sm:text-lg xl:text-2xl mt-2">
        Simak kegiatan dan kebersamaan PMK Daniel!
      </h2>

      <div className="relative w-full overflow-hidden pt-8 md:pt-12 xl:pt-16">
        <div className="flex w-max gap-6 animate-marquee hover:paused cursor-pointer">
          {doubleKegiatan.map((item, index) => (
            <div
              key={index}
              className="w-100 h-100 md:w-110 md:h-110 lg:h-120 lg:w-160 xl:w-160 xl:h-120 2xl:w-170 2xl:h-140 shrink-0 flex flex-col bg-white"
            >
              <div className="relative w-100 h-100 md:w-110 md:h-110 lg:h-120 lg:w-160 xl:w-160 xl:h-115 2xl:w-170 2xl:h-140 rounded-[2rem] overflow-hidden bg-gray-100 mb-6">
                <Image
                  src={item.imageUrl}
                  alt={item.title}
                  fill
                  className="object-cover"
                />
              </div>
              <div className="flex gap-10 items-center">
                <span className="text-sm font-semibold pt-1 text-[15px]">
                  {item.number}
                </span>
                <div className="flex flex-col gap-2">
                  <h3 className="text-2xl lg:text-[36px] font-plusJakarta font-bold">
                    {item.title}
                  </h3>
                  <p className="text-sm font-plusJakarta font-normal lg:text-base">
                    {item.desc}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
