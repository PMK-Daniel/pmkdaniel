import Image from "next/image";

export default function Sidebar() {
    return (
        <div className="max-w-[219px] w-full min-h-dvh">
            <div className="w-full flex flex-col items-center justify-center bg-primary gap-2">
                <div className="pt-18">
                    <Image
                        src='/logo.svg'
                        alt="logo"
                        width={87}
                        height={84}
                    />
                </div>
                <h1 className="font-plusJakarta font-extrabold text-white text-lg md:text-xl lg:text-2xl text-center pb-15">
                    PMK DANIEL
                </h1>
            </div>

            <div className="mt-10 px-8 flex flex-col gap-4">
                <div className="flex items-center gap-2 ">
                    <Image src="/dashboard-sidebar.svg" alt="dashboard" width={24} height={24} />
                    <p className="font-plusJakarta font-medium">
                        Dashboard
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <Image src="/pengumuman-sidebar.svg" alt="dashboard" width={24} height={24} />
                    <p className="font-plusJakarta font-medium">
                        Pengumuman
                    </p>
                </div>
                <div className="flex items-center gap-2 bottom-50 absolute">
                    <Image src="/logout.svg" alt="dashboard" width={24} height={24} />
                    <p className="font-plusJakarta font-medium">
                        Keluar
                    </p>
                </div>
            </div>
        </div>
    );
}