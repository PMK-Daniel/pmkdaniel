import React from 'react';
import { Shield, Lock, University } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-slate-900 text-slate-400 py-12 border-t border-slate-800 text-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pb-8 border-b border-slate-800">
          <div>
            <div className="flex items-center gap-2 text-white font-bold text-base mb-2">
              <University className="w-5 h-5 text-blue-400" />
              <span>PMK Daniel Universitas Brawijaya</span>
            </div>
            <p className="text-slate-400 text-xs leading-relaxed">
              Sistem Pemilihan Elektronik (E-Voting) berbasis integritas tinggi dan kerahasiaan suara mutlak untuk suksesi kepemimpinan persekutuan.
            </p>
          </div>

          <div>
            <h4 className="text-white font-semibold text-xs uppercase tracking-wider mb-2">Prinsip Keamanan Sistem</h4>
            <ul className="space-y-1.5 text-xs">
              <li className="flex items-center gap-2">
                <Lock className="w-3.5 h-3.5 text-emerald-400" />
                <span>Zero-Knowledge Secret Ballot Architecture</span>
              </li>
              <li className="flex items-center gap-2">
                <Shield className="w-3.5 h-3.5 text-blue-400" />
                <span>One Student, One Verified Vote Enforcement</span>
              </li>
              <li className="flex items-center gap-2">
                <Lock className="w-3.5 h-3.5 text-indigo-400" />
                <span>Zero Voter-Choice Correlation in Database</span>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="text-white font-semibold text-xs uppercase tracking-wider mb-2">Kandidat Terdaftar</h4>
            <div className="flex flex-wrap gap-1.5 text-xs text-slate-300">
              <span className="bg-slate-800 px-2 py-0.5 rounded border border-slate-700">01. Joseph</span>
              <span className="bg-slate-800 px-2 py-0.5 rounded border border-slate-700">02. Zoe</span>
              <span className="bg-slate-800 px-2 py-0.5 rounded border border-slate-700">03. Anna</span>
              <span className="bg-slate-800 px-2 py-0.5 rounded border border-slate-700">04. Nata</span>
              <span className="bg-slate-800 px-2 py-0.5 rounded border border-slate-700">05. Chelsea</span>
            </div>
          </div>
        </div>

        <div className="pt-6 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-400 gap-4">
          <p>© {new Date().getFullYear()} Komisi Pemilihan PMK Daniel FILKOM Universitas Brawijaya. Seluruh hak cipta dilindungi undang-undang.</p>
          <div className="flex items-center gap-4 text-[11px]">
            <span>Enkripsi SHA-256</span>
            <span>•</span>
            <span>Supabase Cloud Secured</span>
            <span>•</span>
            <span>Vercel Edge Ready</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
