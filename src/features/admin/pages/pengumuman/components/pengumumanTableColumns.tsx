"use client"
import { Button } from "@/components/ui/button";
import { ColumnDef } from "@tanstack/react-table";
import { Pencil, Trash2 } from "lucide-react";


export type pengumuman = {
    id: string;
    judul: string;
    dibuat: string;
    publikasi: string;
    status: "Aktif" | "Terjadwal"
}

export const columns: ColumnDef<pengumuman>[] = [
    {
        accessorKey: "judul",
        header: "JUDUL PENGUMUMAN",
        cell: ({ row }) => {
            return <span className="font-plusJakarta font-bold text-base">{row.getValue("judul")}</span>
        },
    },
    {
        accessorKey: "dibuat",
        header: "DIBUAT",
    },
    {
        accessorKey: "publikasi",
        header: "PUBLIKASI",
    },
    {
        accessorKey: "status",
        header: "STATUS",
        cell: ({ row }) => {
            const status = row.getValue("status") as string;

            return (
                <div className="flex items-center gap-2">
                    <span
                        className={`h-3.5 w-3.5  rounded-full ${status === "Aktif"
                            ? "bg-[#14532D]"
                            : "bg-[#1E3A8A]"}
                        `}
                    />
                    <span className={`font-plusJakarta font-semibold text-base ${status === "Aktif" ? "text-[#14532D]" : "text-[#1E3A8A]"}`}>
                        {status}
                    </span>
                </div>
            )
        }
    },
    {
        id: "actions",
        header: "AKSI",
        cell: ({ row }) => {
            return (
                <div className="flex items-center ">
                    <Button variant={"ghost"} size={"icon"} className="w-9 h-9">
                        <Pencil className="size-5" />
                    </Button>
                    <Button variant={"ghost"} size={"icon"} className="w-9 h-9">
                        <Trash2 className="size-5 " />
                    </Button>
                </div>
            )
        }
    }
]