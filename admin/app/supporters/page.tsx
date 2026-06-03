"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";
import T, { type Lang } from "@/lib/landing-translations";

const TIERS = [
  { key: "supporter",       name: "Supporter",        price: "$9",   period: "one-time", color: "#94a3b8", glow: "rgba(100,116,139,0.3)",  badge: "🎖️" },
  { key: "ambassador",      name: "Ambassador",       price: "$49",  period: "one-time", color: "#a855f7", glow: "rgba(168,85,247,0.35)",  badge: "⭐", popular: true },
  { key: "founding_creator",name: "Founding Creator", price: "$149", period: "one-time", color: "#f59e0b", glow: "rgba(245,158,11,0.35)",  badge: "🔥" },
  { key: "founding_partner",name: "Founding Partner", price: "$499", period: "one-time", color: "#ec4899", glow: "rgba(236,72,153,0.35)",  badge: "👑" },
];

function LangSwitcher({ lang, setLang }: { lang: Lang; setLang: (l: Lang) => void }) {
  return (
    <div style={{ display: "flex", gap: 2, background: "rgba(255,255,255,0.05)", borderRadius: 99, padding: 3, border: "1px solid rgba(255,255,255,0.08)" }}>
      {(["ht", "en", "fr"] as Lang[]).map((l) => (
        <button key={l} onClick={() => setLang(l)}
          style={{ padding: "5px 10px", borderRadius: 99, border: "none", cursor: "pointer", fontSize: 11, fontWeight: 700,
            background: lang === l ? "rgba(168,85,247,0.85)" : "transparent",
            color: lang === l ? "#fff" : "#64748b", transition: "all 0.15s" }}>
          {l.toUpperCase()}
        </button>
      ))}
    </div>
  );
}

export default function SupportersPage() {
  const [lang, setLang] = useState<Lang>("ht");
  const t = T[lang];

  const [checkoutLoading, setCheckoutLoading] = useState<string | null>(null);

  async function startCheckout(tierKey: string) {
    setCheckoutLoading(tierKey);
    try {
      const res = await fetch("/api/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tier: tierKey }),
      });
      const data = await res.json() as { url?: string; error?: string };
      if (!res.ok || !data.url) throw new Error(data.error ?? "Checkout failed");
      window.location.href = data.url;
    } catch (err) {
      alert(err instanceof Error ? err.message : "Something went wrong. Please try again.");
      setCheckoutLoading(null);
    }
  }

  return (
    <div style={{ background: "#07080f", color: "#e2e8f0", fontFamily: "'Poppins', system-ui, sans-serif", minHeight: "100vh" }}>

      {/* ── NAV ─────────────────────────────────────────────────────────── */}
      <nav style={{ position: "sticky", top: 0, zIndex: 100, padding: "0 24px", height: 64, display: "flex", alignItems: "center", justifyContent: "space-between", background: "rgba(7,8,15,0.96)", backdropFilter: "blur(18px)", borderBottom: "1px solid rgba(168,85,247,0.15)" }}>
        <Link href="/" style={{ display: "flex", alignItems: "center", gap: 10, textDecoration: "none" }}>
          <Image src="/logo.png" alt="Gran Boulva" width={30} height={30} style={{ borderRadius: 8 }} />
          <span style={{ fontWeight: 800, fontSize: 16, color: "#fff" }}>Gran Boulva</span>
        </Link>
        <LangSwitcher lang={lang} setLang={setLang} />
      </nav>

      {/* ── HEADER ──────────────────────────────────────────────────────── */}
      <div style={{ padding: "80px 32px 40px", textAlign: "center", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 800, height: 500, background: "radial-gradient(ellipse,rgba(245,158,11,0.1) 0%,transparent 65%)", pointerEvents: "none" }} />
        <p style={{ color: "#f59e0b", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 16 }}>{t.supporters.tag}</p>
        <h1 style={{ fontSize: "clamp(28px,4vw,52px)", fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-1.5px" }}>{t.supporters.h2}</h1>
        <p style={{ fontSize: 16, color: "#94a3b8", maxWidth: 560, margin: "0 auto 12px", lineHeight: 1.7 }}>{t.supporters.body}</p>
        <p style={{ fontSize: 13, color: "#f59e0b", fontWeight: 600 }}>{t.supporters.urgency}</p>
      </div>

      {/* ── TIERS ───────────────────────────────────────────────────────── */}
      <section style={{ padding: "40px 32px 100px", position: "relative" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div className="tiers-grid" style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 16 }}>
            {TIERS.map((tier, i) => {
              const perks = t.supporters.tierPerks[i] ?? [];
              return (
                <div key={tier.key} style={{
                  background: tier.popular ? `linear-gradient(180deg,${tier.color}18 0%,rgba(7,8,15,0.8) 100%)` : "rgba(255,255,255,0.03)",
                  border: `1px solid ${tier.popular ? tier.color + "66" : tier.color + "33"}`,
                  borderRadius: 20, padding: "28px 22px", position: "relative", display: "flex", flexDirection: "column",
                }}>
                  {tier.popular && (
                    <div style={{ position: "absolute", top: -12, left: "50%", transform: "translateX(-50%)", background: tier.color, color: "#fff", fontSize: 10, fontWeight: 800, padding: "4px 14px", borderRadius: 99, whiteSpace: "nowrap", letterSpacing: 0.5 }}>
                      MOST POPULAR
                    </div>
                  )}
                  <div style={{ fontSize: 32, marginBottom: 12 }}>{tier.badge}</div>
                  <h3 style={{ fontSize: 15, fontWeight: 800, color: "#fff", margin: "0 0 4px" }}>
                    {t.tierNames[tier.key as keyof typeof t.tierNames]}
                  </h3>
                  <div style={{ marginBottom: 20 }}>
                    <span style={{ fontSize: 32, fontWeight: 900, color: tier.color, letterSpacing: "-1px" }}>{tier.price}</span>
                    <span style={{ fontSize: 13, color: "#94a3b8", marginLeft: 6 }}>{tier.period}</span>
                  </div>
                  <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10, marginBottom: 24 }}>
                    {perks.map((perk) => (
                      <div key={perk} style={{ display: "flex", gap: 8, alignItems: "flex-start" }}>
                        <span style={{ color: tier.color, fontSize: 13, marginTop: 1, flexShrink: 0 }}>✓</span>
                        <span style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.5 }}>{perk}</span>
                      </div>
                    ))}
                  </div>
                  <button
                    onClick={() => startCheckout(tier.key)}
                    disabled={checkoutLoading !== null}
                    style={{
                      width: "100%", padding: "12px", borderRadius: 12, fontWeight: 700, fontSize: 13,
                      cursor: checkoutLoading !== null ? "wait" : "pointer",
                      border: `1px solid ${tier.color}`,
                      background: tier.popular ? tier.color : "transparent",
                      color: tier.popular ? "#fff" : tier.color,
                      transition: "all 0.2s",
                      opacity: checkoutLoading !== null && checkoutLoading !== tier.key ? 0.5 : 1,
                    }}
                    onMouseEnter={e => { if (!tier.popular && checkoutLoading === null) { (e.currentTarget as HTMLButtonElement).style.background = tier.color; (e.currentTarget as HTMLButtonElement).style.color = "#fff"; } }}
                    onMouseLeave={e => { if (!tier.popular) { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; (e.currentTarget as HTMLButtonElement).style.color = tier.color; } }}>
                    {checkoutLoading === tier.key ? "⏳ Loading…" : t.supporters.tierCta}
                  </button>
                </div>
              );
            })}
          </div>

          <p style={{ textAlign: "center", fontSize: 12, color: "#475569", marginTop: 24 }}>{t.supporters.disclaimer}</p>

          <div style={{ textAlign: "center", marginTop: 48 }}>
            <Link href="/" style={{ fontSize: 13, color: "#94a3b8", textDecoration: "none" }}>← {lang === "ht" ? "Retounen nan paj prensipal" : lang === "fr" ? "Retour à l'accueil" : "Back to home"}</Link>
          </div>
        </div>
      </section>

      <style>{`
        @media (max-width: 900px) { .tiers-grid { grid-template-columns: repeat(2,1fr) !important; } }
        @media (max-width: 520px) { .tiers-grid { grid-template-columns: 1fr !important; } }
      `}</style>
    </div>
  );
}
