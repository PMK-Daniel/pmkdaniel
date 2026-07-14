import { Card, CardContent } from "@/components/ui/card";
import Image from "next/image";

interface PengumumanCardProps {
    imageIcon: string;
    description: string;
    amount: number;
    borderColor: string;
    bgIconColor: string;
}

export default function PengumumanCard({ imageIcon, description, amount, borderColor, bgIconColor }: PengumumanCardProps) {
    return (
        <Card className={`${borderColor} border w-full`}>
            <CardContent className="flex items-center gap-5">
                <div className={`${bgIconColor} rounded-full px-2.5 py-2.5`}>
                    <Image
                        src={imageIcon}
                        alt={description}
                        width={32}
                        height={32}
                    />
                </div>
                <div>
                    <h2 className="font-plusJakarta font-normal text-sm md:text-base">
                        {description}
                    </h2>
                    <p className="font-plusJakarta font-semibold text-lg md:text-2xl">
                        {amount}
                    </p>
                </div>
            </CardContent>
        </Card>
    )
}