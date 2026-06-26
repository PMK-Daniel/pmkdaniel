"use client"; 

import { useState } from "react";

export default function Navbar() {

  const [isOpen, setIsOpen] = useState(false);

  return (

    <nav className="fixed top-6 left-1/2 transform -translate-x-1/2 z-50 w-[95%] max-w-5xl">
      
      {}
      <div className="bg-white/90 backdrop-blur-md rounded-full shadow-sm px-6 py-3 flex items-center justify-between">
        
        {/* Kiri: Logo */}
        <div className="flex items-center cursor-pointer">
          <img src="/logo.png" alt="Logo PMK" className="h-10 w-auto" />
        </div>

        {

        }
        <div className="hidden md:flex items-center space-x-8 text-sm font-semibold text-gray-700">
          <a href="/" className="hover:text-[#3E4095] transition-colors">Beranda</a>
          <a href="/tentang" className="hover:text-[#3E4095] transition-colors">Tentang Kami</a>
          <a href="/pengumuman" className="hover:text-[#3E4095] transition-colors">Pengumuman</a>
          <a href="/pengurus" className="hover:text-[#3E4095] transition-colors">Kepengurusan</a>
          <a href="tentang" className="hover:text-[#3E4095] transition-colors">Form & Pendataan</a>
          <a href="/kontak" className="hover:text-[#3E4095] transition-colors">Kontak</a>
        </div>
        
        {

        }
        <div className="flex items-center space-x-4">
          <button className="hidden md:block px-6 py-2 text-sm font-bold text-white transition-all bg-gradient-to-r from-[#3E4095] to-[#F58732] rounded-full hover:opacity-90 shadow-md">
            Join Us!
          </button>

          {
        }
          <button 
            onClick={() => setIsOpen(!isOpen)} 
            
            className="md:hidden p-2 text-gray-700 focus:outline-none"
          >
            {    }
            {isOpen ? (
              <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            ) : (
              <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
            )}
          </button>
        </div>
      </div>

      {}
      {}
      {isOpen && (
        <div className="md:hidden absolute top-full left-0 w-full mt-4 bg-white/95 backdrop-blur-md rounded-2xl shadow-lg p-6 flex flex-col space-y-4 text-center text-sm font-semibold text-gray-700">
          <a href="#" className="hover:text-[#3E4095]">Beranda</a>
          <a href="#about" className="hover:text-[#3E4095]">Tentang Kami</a>
          <a href="#" className="hover:text-[#3E4095]">Pengumuman</a>
          <a href="#" className="hover:text-[#3E4095]">Kepengurusan</a>
          <a href="#" className="hover:text-[#3E4095]">Form & Pendataan</a>
          <a href="#" className="hover:text-[#3E4095]">Kontak</a>
          <button className="w-full px-6 py-3 mt-4 text-white font-bold bg-gradient-to-r from-[#3E4095] to-[#F58732] rounded-full">
            Join Us!
          </button>
        </div>
      )}

    </nav>
  );
}