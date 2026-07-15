//Perbaikan Hero Section: Menambahkan animasi marquee GSAP untuk menampilkan ayat Alkitab yang bergerak horizontal di bagian bawah layar.

"use client";

import { useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";

export default function HeroSection() {
  const marqueeRef = useRef<HTMLDivElement>(null);

  // Animasi GSAP Marquee
  useGSAP(() => {
    gsap.to(marqueeRef.current, {
      xPercent: -50, // Bergerak setengah dari total lebar container (karena elemen kita duplikasi 2x)
      repeat: -1, // Loop tak terbatas
      duration: 25, // Kecepatan animasi (semakin besar semakin lambat)
      ease: "linear",
    });
  });

const SparkleIcon = () => (
    <svg width="25" height="26" viewBox="0 0 24 24" fill="currentColor" className="shrink-0 text-[#000000]">
      <path d="M12 0C12 6.62742 17.3726 12 24 12C17.3726 12 12 17.3726 12 24C12 17.3726 6.62742 12 0 12C6.62742 12 12 6.62742 12 0Z" />
    </svg>
  );

  return (
    <section className="relative flex min-h-screen w-full flex-col items-center justify-center overflow-hidden bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-primary/10 via-background to-background font-plusJakarta">
      {}
      {}
      <div className="pointer-events-none absolute left-[80%] top-[20%] h-[335px] w-[335px] rounded-full bg-secondary opacity-50 blur-[150px]" />
      {}
      <div className="pointer-events-none absolute -left-[5%] top-[30%] h-[279px] w-[279px] rounded-full bg-primary opacity-40 blur-[150px]" />

      {/* ================= HERO TEXT CONTENT ================= */}
      <div className="relative z-10 flex flex-col items-center gap-[8px] px-4 text-center">
        <p className="text-[20px] font-[400] leading-[32px] text-black md:text-[24px]">
          PMK Daniel FILKOM UB
        </p>
        <h1 className="max-w-[700px] text-[48px] font-[800] leading-[1.1] text-primary md:text-[64px] md:leading-[80px]">
          Together to be Better.
        </h1>
      </div>

      {/* ================= GSAP(Ayat Alkitab) ================= */}
      {}
      <div className="absolute bottom-[100px] flex h-[64px] w-full items-center overflow-hidden border-y border-black bg-white/50 backdrop-blur-sm">
        <div
          ref={marqueeRef}
          className="flex min-w-max items-center gap-[32px] whitespace-nowrap"
        >
          {/*Merender teks 2 kali (array 2) agar saat animasi berjalan, 
            ujung awal dan akhir bertemu tanpa ada bagian yang terpotong kosong. 
          */}
          {[...Array(2)].map((_, i) => (
            <div key={i} className="flex items-center gap-[32px]">
              <span className="text-[20px] font-[400] text-black md:text-[24px]">
                "Tuhan adalah gembalaku, takkan kekurangan aku." — Mazmur 23:1
              </span>

              {/* Memanggil Ikon Sparkle presisi */}
              <SparkleIcon />

              <span className="text-[20px] font-[400] text-black md:text-[24px]">
                "Jangan takut, sebab Aku menyertai engkau." — Yesaya 41:10
              </span>

              {/* Memanggil Ikon */}
              <SparkleIcon />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
