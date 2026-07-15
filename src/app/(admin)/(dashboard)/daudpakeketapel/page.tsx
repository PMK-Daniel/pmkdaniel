// !TODO: route /jasonfegacor adalah halaman "dashboard" untuk admin PMK Daniel
// !TODO: Halaman ini menampilkan informasi dashboard untuk admin PMK Daniel


"use client";

import React from "react";
import Image from "next/image";
import { LayoutDashboard, Megaphone, LogOut, Plus } from "lucide-react";

export default function DashboardPage() {
  return (

    <div className="flex min-h-screen bg-[#fafafa] font-plusJakarta">
      
      {
        
      }
      <aside className="fixed left-0 top-0 z-50 flex h-full w-[219px] flex-col bg-white shadow-[0px_4px_4px_rgba(0,0,0,0.25)]">
        
        {

        }
        <div className="relative flex h-[257px] w-[219px] flex-col items-center justify-center bg-primary">
          <div className="relative h-[84px] w-[87px]">
            <Image
              src="/logo.png"
              alt="Logo PMK Daniel"
              fill
              className="object-contain"
            />
          </div>
          {/* Teks Judul */}
          <h2 className="mt-[20px] font-plusJakarta text-[24px] font-[800] leading-[30px] text-white">
            PMK Daniel
          </h2>
        </div>

        {/* Menu Navigasi Tengah (Frame 150) */}
        <nav className="mt-[39px] flex w-full flex-col">
          {/* Menu: Dashboard */}
          <div className="flex h-[44px] w-full items-center gap-[8px] bg-gray-50 py-[8px] pl-[32px] pr-[12px]">
            <LayoutDashboard className="h-[24px] w-[24px] text-black" />
            {/* Teks Navigasi */}
            <span className="font-['Nunito_Sans'] text-[16px] font-[600] leading-[22px] text-black">
              Dashboard
            </span>
          </div>
          {/* Menu: Pengumuman */}
          <div className="flex h-[44px] w-full items-center gap-[8px] py-[8px] pl-[32px] pr-[12px] cursor-pointer hover:bg-gray-50 transition-colors">
            <Megaphone className="h-[24px] w-[24px] text-black" />
            <span className="font-['Nunito_Sans'] text-[16px] font-[600] leading-[22px] text-black">
              Pengumuman
            </span>
          </div>
        </nav>

        {/* Menu Navigasi Bawah (Frame 151) - Logout */}
        <div className="absolute bottom-[44px] left-0 flex w-full flex-col">
          <div className="flex h-[44px] w-full items-center gap-[8px] py-[8px] pl-[32px] pr-[12px] cursor-pointer hover:bg-gray-50 transition-colors">
            <LogOut className="h-[24px] w-[24px] text-black" />
            <span className="font-['Nunito_Sans'] text-[16px] font-[600] leading-[22px] text-black">
              Keluar
            </span>
          </div>
        </div>
      </aside>
      {/* ========================================================= */}


      { }
      <main className="ml-[219px] flex flex-1 flex-col px-8 py-12 lg:px-[69px] lg:py-[75px]">
        {/* Wadah fleksibel maksimal 1088px */}
        <div className="mx-auto flex w-full max-w-[1088px] flex-col">
          
          {/* Judul Utama Dashboard */}
          <h1 className="w-full font-plusJakarta text-[32px] md:text-[40px] font-[700] leading-tight text-primary">
            Dashboard
          </h1>

          {/* Seksi: Pengumuman Terbaru */}
          <section className="mt-16 md:mt-[132px] flex w-full flex-col gap-[32px]">
            <h2 className="w-full font-plusJakarta text-[28px] md:text-[40px] font-[700] leading-tight text-primary">
              Pengumuman Terbaru
            </h2>
            
            <div className="flex w-full flex-col bg-white">
              {[1, 2, 3, 4].map((item, index) => (
                <div
                  key={index}
                  className="flex min-h-[92px] w-full flex-col sm:flex-row sm:items-center justify-between border border-b-0 border-[#D9D9D9] px-[24px] py-[16px] md:px-[32px] last:border-b gap-2"
                >
                  <span className="font-plusJakarta text-[16px] font-[700] leading-[20px] text-black">
                    Camp Daniel 2026
                  </span>
                  <span className="font-plusJakarta text-[14px] md:text-[16px] font-[400] leading-[20px] text-gray-600 sm:text-black">
                    15 Juni 2026
                  </span>
                </div>
              ))}
            </div>
          </section>

          {/* Seksi: Aktivitas Terakhir */}
          <section className="mt-16 md:mt-[65px] flex w-full flex-col gap-[32px]">
            <h2 className="w-full font-plusJakarta text-[28px] md:text-[40px] font-[700] leading-tight text-primary">
              Aktivitas terakhir
            </h2>
            
            <div className="flex w-full flex-col gap-[8px]">
              {[1, 2, 3, 4].map((item, index) => (
                <div
                  key={index}
                  className="flex min-h-[72px] w-full flex-col sm:flex-row sm:items-center justify-between rounded-[10px] bg-primary/10 px-[24px] py-[16px] gap-2"
                >
                  <div className="flex items-center gap-[16px]">
                    <Plus className="h-[24px] w-[24px] shrink-0 text-black" />
                    <span className="font-plusJakarta text-[14px] md:text-[16px] font-[700] leading-[20px] text-black">
                      Pengumuman Persekutuan Doa dibuat
                    </span>
                  </div>
                  <span className="font-plusJakarta text-[14px] md:text-[16px] font-[400] leading-[20px] text-gray-600 sm:text-black">
                    15 november 2026
                  </span>
                </div>
              ))}
            </div>
          </section>

        </div>
      </main>

    </div>
  );
}