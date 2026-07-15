import Sidebar from "@/features/admin/components/sidebar";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    return (
        <div className="flex min-h-dvh w-full">
            <Sidebar />
            <main className="min-w-0 flex-1 w-full">
                {children}
            </main>
        </div>
    );
}
