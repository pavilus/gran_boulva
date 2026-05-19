import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Gran Boulva",
  description: "Debat, vote, ak kominote ayisyen an",
  icons: { icon: "/logo.png" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className="h-full" style={{ background: "#07080f" }}>
      <body className="h-full" style={{ background: "#07080f" }}>
        {children}
      </body>
    </html>
  );
}
