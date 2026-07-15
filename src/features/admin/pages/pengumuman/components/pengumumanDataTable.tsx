"use client"

import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ColumnDef, ColumnFiltersState, flexRender, getCoreRowModel, getFilteredRowModel, getPaginationRowModel, useReactTable } from "@tanstack/react-table"
import { ChevronLeft, ChevronRight, Funnel } from "lucide-react";
import { cn } from "@/lib/utils";
import React from "react";

interface DataTableProps<TData, TValue> {
    columns: ColumnDef<TData, TValue>[];
    data: TData[];
}

export function DataTable<TData, TValue>({
    columns,
    data,
}: DataTableProps<TData, TValue>) {
    const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([]);

    const table = useReactTable({
        data,
        columns,
        getCoreRowModel: getCoreRowModel(),
        getPaginationRowModel: getPaginationRowModel(),
        onColumnFiltersChange: setColumnFilters,
        getFilteredRowModel: getFilteredRowModel(),
        state: {
            columnFilters,
        },
        initialState: {
            pagination: {
                pageSize: 5
            }
        }
    })

    const { pageIndex, pageSize } = table.getState().pagination;
    const totalRows = table.getFilteredRowModel().rows.length;
    const startRow = totalRows === 0 ? 0 : pageIndex * pageSize + 1;
    const endRow = Math.min((pageIndex + 1) * pageSize, totalRows);
    const pageCount = table.getPageCount();

    return (
        <div className="w-full border rounded-xl bg-white shadow-sm overflow-hidden mt-10">
            <div className="flex items-center justify-between p-4 border-b gap-4 flex-wrap">
                <div className="max-w-sm w-full relative flex items-center">
                    <Funnel className="absolute left-3.5 top-1/2 -translate-y-1/2 size-6 text-gray-500 pointer-events-none" />
                    <input
                        placeholder="Filter berdasarkan judul..."
                        value={(table.getColumn("judul")?.getFilterValue() as string) ?? ""}
                        onChange={(event) =>
                            table.getColumn("judul")?.setFilterValue(event.target.value)
                        }
                        className="w-full pl-12 pr-4 py-2 text-sm bg-neutral-50 hover:bg-neutral-100/50 focus:bg-white border border-neutral-200 focus:border-black rounded-lg focus:outline-none focus:ring-4 focus:ring-black/5 transition-all duration-200 placeholder:text-gray-500 font-plusJakarta font-medium text-black/80"
                    />
                </div>

                <div className="flex items-center gap-30 text-sm md:text-base font-medium font-plusJakarta ">
                    <span>
                        Menampilkan {startRow}–{endRow} dari {totalRows}
                    </span>
                    <div className="flex items-center gap-1">
                        <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => table.previousPage()}
                            disabled={!table.getCanPreviousPage()}
                        >
                            <ChevronLeft className="h-4 w-4" />
                        </Button>
                        <Button
                            variant="outline"
                            size="icon"
                            className="h-8 w-8"
                            onClick={() => table.nextPage()}
                            disabled={!table.getCanNextPage()}
                        >
                            <ChevronRight className="h-4 w-4" />
                        </Button>
                    </div>
                </div>
            </div>

            <Table>
                <TableHeader className="bg-[#F5873280] ">
                    {table.getHeaderGroups().map((headerGroup) => (
                        <TableRow key={headerGroup.id} className="hover:bg-transparent border-none">
                            {headerGroup.headers.map((header) => {
                                return (
                                    <TableHead
                                        key={header.id}
                                        className={cn(
                                            "font-medium font-plusJakarta text-xs md:text-base py-8",
                                            header.id === "judul" && "pl-8 w-[20%]",
                                            header.id === "dibuat" && "pl-8 w-[15%]",
                                            header.id === "publikasi" && "pl-20 w-[5%]",
                                            header.id === "status" && "pl-30 w-[25%]",
                                            header.id === "actions" && "pl-5 w-[15%]"
                                        )}
                                    >
                                        {header.isPlaceholder
                                            ? null
                                            : flexRender(
                                                header.column.columnDef.header,
                                                header.getContext()
                                            )}
                                    </TableHead>
                                )
                            })}
                        </TableRow>
                    ))}
                </TableHeader>
                <TableBody>
                    {table.getRowModel().rows?.length ? (
                        table.getRowModel().rows.map((row) => (
                            <TableRow
                                key={row.id}
                                data-state={row.getIsSelected() && "selected"}
                                className="border-b border-black/20 py-4"
                            >
                                {row.getVisibleCells().map((cell) => (
                                    <TableCell
                                        key={cell.id}
                                        className={cn(
                                            "py-4 text-sm md:text-base font-plusJakarta",
                                            cell.column.id === "judul" && "pl-8 font-bold",
                                            cell.column.id === "dibuat" && "pl-8",
                                            cell.column.id === "publikasi" && "pl-20",
                                            cell.column.id === "status" && "pl-30",
                                        )}
                                    >
                                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                    </TableCell>
                                ))}
                            </TableRow>
                        ))
                    ) : (
                        <TableRow>
                            <TableCell colSpan={columns.length} className="h-24 text-center">
                                Tidak ada data pengumuman.
                            </TableCell>
                        </TableRow>
                    )}
                </TableBody>
            </Table>

            {pageCount > 1 && (
                <div className="flex items-center justify-center py-4 border-t gap-2">
                    {Array.from({ length: pageCount }, (_, index) => (
                        <Button
                            key={index}
                            variant={pageIndex === index ? "default" : "ghost"}
                            className={`h-9 w-9 p-0 rounded-[6px] ${pageIndex === index
                                    ? "bg-[#2E3A8C] text-white hover:bg-[#2E3A8C]/95"
                                    : "text-[#1E3A8A] hover:text-gray-950"
                                }`}
                            onClick={() => table.setPageIndex(index)}
                        >
                            {index + 1}
                        </Button>
                    ))}
                </div>
            )}
        </div>
    )
}