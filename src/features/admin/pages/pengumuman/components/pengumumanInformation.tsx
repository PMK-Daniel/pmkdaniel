import PengumumanCard from "./pengumumanCard";

export default function PengumumanInformation() {
    return (
        <div className="mt-8 grid w-full grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4 xl:gap-20">
            <PengumumanCard
                imageIcon="/megaphone.svg"
                description="Total"
                amount={0}
                bgIconColor="bg-bg-iconyellow"
                borderColor="border-border-yellow"
            />
            <PengumumanCard
                imageIcon="/checklist.svg"
                description="Aktif"
                amount={0}
                bgIconColor="bg-bg-icongreen"
                borderColor="border-border-green"
            />
            <PengumumanCard
                imageIcon="/clock.svg"
                description="Terjadwal"
                amount={0}
                bgIconColor="bg-bg-iconblue"
                borderColor="border-border-blue"
            />
            <PengumumanCard
                imageIcon="/trash.svg"
                description="Dihapus"
                amount={0}
                bgIconColor="bg-bg-iconred"
                borderColor="border-border-red"
            />
        </div>
    )
}