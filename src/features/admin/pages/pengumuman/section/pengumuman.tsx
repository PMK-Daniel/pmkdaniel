import PengumumanInformation from "../components/pengumumanInformation";
import PengumumanTablePage from "../components/pengumumanTablePage";

export default function PengumumanAdmin() {
    return (
        <section className="w-full min-h-screen py-[75px] px-[70px]">
            <h1 className="text-primary font-plusJakarta font-bold text-[40px]">
                Pengumuman
            </h1>
            <PengumumanInformation />
            <PengumumanTablePage />
        </section>
    );
}
