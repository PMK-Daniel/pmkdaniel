// !TODO: route /pausmakanyunus adalah halaman "login" untuk admin PMK Daniel
// Deskripsi: Halaman autentikasi 


"use client";

import React from "react";
import Image from "next/image";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export default function Login() {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-background">
      {/* Rectangle 3 (Orange - Kanan Atas) */}
      <div
        className="pointer-events-none absolute"
        style={{
          width: "335px",
          height: "335px",
          left: "1272px",
          top: "214px",
          backgroundColor: "var(--secondary)",
          filter: "blur(339.95px)",
        }}
      />
      
      {/* Rectangle 4 (Orange - Kiri Bawah) */}
      <div
        className="pointer-events-none absolute"
        style={{
          width: "335px",
          height: "335px",
          left: "-46px",
          top: "738px",
          backgroundColor: "var(--secondary)",
          filter: "blur(339.95px)",
        }}
      />
      
      {/* Rectangle 2 (Purple - Kanan Bawah) */}
      <div
        className="pointer-events-none absolute"
        style={{
          width: "279px",
          height: "279px",
          left: "820px",
          top: "-157px",
          backgroundColor: "var(--primary)",
          filter: "blur(252.85px)",
        }}
      />

      {/* =========================================
          KONTEN UTAMA (Tengah Layar)
      ========================================= */}
      <div className="relative z-10 flex flex-col items-center gap-[80px] py-12">
        
        {/* ================= AREA HEADER ================= */}
        <div className="flex h-[241px] w-[540px] flex-col items-center gap-[12px]">
          <div className="flex h-[189px] w-[540px] flex-col items-center gap-[12px]">
            {/* Logo */}
            <div className="relative h-[117px] w-[121px] shrink-0">
              <Image
                src="/logo.png"
                alt="Logo PMK Daniel"
                fill
                priority
                className="object-contain"
              />
            </div>
            
            {/* Judul: PMK Daniel */}
            <h1 className="h-[60px] w-[540px] text-center font-plusJakarta text-[48px] font-extrabold leading-[60px] text-foreground">
              PMK Daniel
            </h1>
          </div>

          {/* Tagline: Together to be Better. */}
          <p className="h-[40px] w-[540px] text-center font-plusJakarta text-[32px] font-extrabold leading-[40px] text-foreground">
            Together to be <span className="text-secondary">Better.</span>
          </p>
        </div>

        {/* ================= AREA FORM LOGIN ================= */}
        <Card className="flex h-[324px] w-[480px] flex-col items-start rounded-[6px] border border-border bg-card px-[28px] py-[44px] shadow-sm">
          <CardContent className="w-full p-0">
            <div className="flex h-[236px] w-[424px] flex-col items-start gap-[48px]">
              
              {/* Grup Input */}
              <div className="flex h-[148px] w-[424px] flex-col items-start gap-[12px]">
                
                {/* Input Email */}
                <div className="flex h-[68px] w-full flex-col justify-between">
                  <label className="font-plusJakarta text-[16px] font-medium leading-[20px] text-foreground">
                    Email
                  </label>
                  <Input
                    type="email"
                    placeholder="Masukkan teks"
                    className="box-border flex h-[44px] w-full items-center gap-[10px] rounded-[8px] border border-grey bg-white p-[12px] font-plusJakarta text-[16px] font-light leading-[20px] text-foreground placeholder:text-muted-foreground focus-visible:ring-primary"
                  />
                </div>

                {/* Input Kata Sandi */}
                <div className="flex h-[68px] w-full flex-col justify-between">
                  <label className="font-plusJakarta text-[16px] font-medium leading-[20px] text-foreground">
                    Kata Sandi
                  </label>
                  <Input
                    type="password"
                    placeholder="Masukkan kata sandi"
                    className="box-border flex h-[44px] w-full items-center gap-[10px] rounded-[8px] border border-grey bg-white p-[12px] font-plusJakarta text-[16px] font-light leading-[20px] text-foreground placeholder:text-muted-foreground focus-visible:ring-primary"
                  />
                </div>
              </div>

              {/* Button Masuk */}
              <Button className="flex h-[40px] w-full flex-row items-center justify-center gap-[10px] rounded-full bg-primary px-[16px] py-[8px] hover:bg-primary/90 transition-colors">
                <span className="font-plusJakarta text-[14px] font-medium leading-[24px] text-primary-foreground">
                  Masuk
                </span>
              </Button>
              
            </div>
          </CardContent>
        </Card>

      </div>
    </div>
  );
}