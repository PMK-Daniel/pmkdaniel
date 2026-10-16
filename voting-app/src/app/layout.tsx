import type { Metadata } from 'next';
import './globals.css';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';

export const metadata: Metadata = {
  title: 'E-Voting Pemilihan Ketua PMK Daniel FILKOM UB',
  description: 'Sistem Pemilihan Elektronik Mahasiswa Universitas Brawijaya dengan verifikasi email @student.ub.ac.id dan kerahasiaan suara mutlak (Secret Ballot).',
  icons: {
    icon: '/favicon.ico',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-slate-50 text-slate-900 font-sans">
        <Navbar />
        <div className="flex-1">
          {children}
        </div>
        <Footer />
      </body>
    </html>
  );
}
