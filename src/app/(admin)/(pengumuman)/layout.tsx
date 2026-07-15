import AdminLayout from "@/components/adminLayout";

export default function PengumumanLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return <AdminLayout>{children}</AdminLayout>;
}
