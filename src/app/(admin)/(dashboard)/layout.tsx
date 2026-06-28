// !TODO: berisi layout dari figma nya, sidebar atau component lain & children

import Sidebar from "@/features/admin/components/sidebar";

export default function AdminLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return(
        <>
            <Sidebar />
            { children }
        </>
    );
}
