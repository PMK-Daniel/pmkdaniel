import AdminLayout from "@/components/adminLayout";

export default function DashboardLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return <AdminLayout>{children}</AdminLayout>;
}
