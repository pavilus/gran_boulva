"use client";
import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import Image from "next/image";
import Link from "next/link";

const TIER_LABELS: Record<string, { name: string; badge: string; color: string }> = {
  supporter:        { name: "Supporter",        badge: "🎖️", color: "#64748b" },
  ambassador:       { name: "Ambassador",       badge: "⭐", color: "#a855f7" },
  founding_creator: { name: "Founding Creator", badge: "🔥", color: "#f59e0b" },
  founding_partner: { name: "Founding Partner", badge: "👑", color: "#ec4899" },
};

export default function CheckoutSuccess() {
  const params      = useSearchParams();
  const tier        = params.get("tier") ?? "";
  const info        = TIER_LABELS[tier];
  const [dots, setDots] = useState(".");

  // Animated dots while "loading" (purely cosmetic — we don't need to fetch the session)
  useEffect(() => {
    if (info) return;
    const id = setInterval(() => setDots(d => d.length >= 3 ? "." : d + "."), 500);
    return () => clearInterval(id);
  }, [info]);

  return (
    <div style={{
      minHeight: "100vh", background: "#07080f", color: "#e2e8f0",
      fontFamily: "'Poppins', system-ui, sans-serif",
      display: "flex", alignItems: "center", justifyContent: "center",
      padding: "32px",
    }}>
      <div style={{ maxWidth: 520, width: "100%", textAlign: "center" }}>

        {/* Logo */}
        <div style={{ display: "flex", justifyContent: "center", marginBottom: 40 }}>
          <Image src="/logo.png" alt="Gran Boulva" width={56} height={56} style={{ borderRadius: 14 }} />
        </div>

        {/* Success card */}
        <div style={{
          background: "rgba(16,185,129,0.06)",
          border: "1px solid rgba(16,185,129,0.3)",
          borderRadius: 24,
          padding: "48px 40px",
          marginBottom: 32,
        }}>
          <div style={{ fontSize: 56, marginBottom: 20 }}>
            {info ? info.badge : "🎉"}
          </div>

          <h1 style={{ fontSize: 28, fontWeight: 900, color: "#fff", margin: "0 0 12px", letterSpacing: "-0.5px" }}>
            Mèsi anpil!
          </h1>

          {info ? (
            <>
              <p style={{ fontSize: 16, color: "#94a3b8", lineHeight: 1.7, margin: "0 0 20px" }}>
                Ou vinn yon{" "}
                <span style={{ color: info.color, fontWeight: 800 }}>{info.name}</span>{" "}
                fondatè Gran Boulva.
              </p>
              <p style={{ fontSize: 14, color: "#64748b", lineHeight: 1.7, margin: 0 }}>
                Yon imèl konfirmasyon pral rive bientôt.
                Nou ap kontakte ou avan lanse ofisyèl la — Novanm 18, 2026.
              </p>
            </>
          ) : (
            <p style={{ fontSize: 15, color: "#94a3b8" }}>Peman ou a konfime{dots}</p>
          )}
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <Link href="/"
            style={{
              display: "block", padding: "14px", borderRadius: 14,
              background: "linear-gradient(135deg,#a855f7,#7c3aed)",
              color: "#fff", fontWeight: 700, fontSize: 15,
              textDecoration: "none",
            }}>
            Retounen sou sit la
          </Link>
          <Link href="/#waitlist"
            style={{
              display: "block", padding: "14px", borderRadius: 14,
              background: "rgba(168,85,247,0.08)",
              border: "1px solid rgba(168,85,247,0.2)",
              color: "#a78bfa", fontWeight: 600, fontSize: 14,
              textDecoration: "none",
            }}>
            Rantre nan lis datant lan tou
          </Link>
        </div>

      </div>
    </div>
  );
}
