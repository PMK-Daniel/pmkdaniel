import { Button } from "@/components/ui/button";
import Image from "next/image";
import { DataTable } from "./pengumumanDataTable";
import { columns } from "./pengumumanTableColumns";
import { dummyPengumuman } from "../data/pengumumanData";

export default function PengumumanTablePage() {
    return (
        <section className="w-full pt-[90px]">
            <div className="flex items-center justify-between">
                <h1 className="font-plusJakarta font-bold text-primary text-2xl md:text-3xl lg:text-[40px]">
                    Kelola Pengumuman
                </h1>
                <Button size={"lg"} className="bg-primary px-6 py-2">
                    <Image src='/plus.svg' alt="svg" width={24} height={24} />
                    <p className="font-plusJakarta font-medium text-sm">
                        Buat Pengumuman
                    </p>
                </Button>
            </div>

            <DataTable columns={columns} data={dummyPengumuman} />
        </section>
    )
}