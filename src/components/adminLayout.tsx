import Sidebar from "@/features/admin/components/sidebar";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
    return (
        <div className="flex flex-1 ">
            <Sidebar />
            <div>
                {children}
            </div>
        </div>
    );
}
