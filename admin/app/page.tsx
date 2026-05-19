"use client";
import Link from "next/link";
import Image from "next/image";
import { useState, useEffect } from "react";


const FEATURES = [
  { img: "/icon-debat.png", title: "Debat", desc: "Chwazi bò ou epi defann pozisyon ou avèk agiman solid." },
  { img: "/icon-vote.png", title: "Vote", desc: "Vwa ou konte. Vote pou moun oswa sijè ou pi kwè ladan." },
  { img: "/icon-prediksyon.png", title: "Prediksyon", desc: "Predi sak pral rive, teste kapasite analiz ou" },
  { img: "/icon-enpak.png", title: "Fè Enpak", desc: "Ogmante enflyans ou epi vin on gwo vwa nan kominote a!" },
  { img: "/icon-kominote.png", title: "Kominote", desc: "Rantre nan yon kominote aktif e ki gen pasyon pou pataje" },
  { img: "/icon-sekirite.png", title: "Sekirite", desc: "Yon espas sekirize ak règleman klè pou tout moun" }
]

const STEPS = [
  { title: "LI epi AGIMANTE", desc: "Li sijè yo, pataje agiman ou ak kominote a." },
  { title: "VOTE", desc: "Vote pou pozisyon ou kwè ki pi solid." },
  { title: "ENPAKTE", desc: "Ranmase pwen, monte rank, epi peze nan balans lan." },
];

const KAPAB = [
  "Antre nan deba a",
  "Pataje bonjan agiman pou kore bò ou chwazi a",
  "Vote, reponn, e kontre agiman",
  "Swiv debatè ak sijè ou renmen yo",
  "Ranmase pwen ak badj",
  "Patisipe nan prediksyon ak sondaj",
];


export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);

  return (
    <div style={{ background: "#07080f", color: "#e2e8f0", fontFamily: "'Poppins', system-ui, sans-serif", overflowX: "hidden" }}>

      {/* ── NAV ── */}
      <nav style={{
        position: "fixed", top: 0, left: 0, right: 0, zIndex: 100,
        padding: "0 20px", height: 64,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        background: scrolled ? "rgba(7,8,15,0.95)" : "transparent",
        backdropFilter: scrolled ? "blur(16px)" : "none",
        borderBottom: scrolled ? "1px solid rgba(168,85,247,0.15)" : "none",
        transition: "all 0.3s",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <Image src="/logo.png" alt="Gran Boulva" width={32} height={32} style={{ borderRadius: 8 }} />
          <span style={{ fontWeight: 800, fontSize: 17, color: "#fff", letterSpacing: "-0.3px" }}>Gran Boulva</span>
        </div>
        <div className="nav-links" style={{ display: "flex", alignItems: "center", gap: 32, position: "absolute", left: "50%", transform: "translateX(-50%)" }}>
          {[
            { label: "Akèy", href: "#fonksyon" },
            { label: "Kijan li Fonksyone", href: "#kijan-sa-mache" },
            { label: "Telechaje", href: "#telecharje" },
          ].map(({ label, href }) => (
            <a key={href} href={href}
              style={{ color: "#94a3b8", fontSize: 13, fontWeight: 500, textDecoration: "none", whiteSpace: "nowrap" }}
              className="nav-link">{label}</a>
          ))}
        </div>
        <a href="https://apps.apple.com/app/gran-boulva" target="_blank" rel="noopener noreferrer"
          className="nav-cta"
          style={{ background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", padding: "9px 20px", borderRadius: 99, fontSize: 13, fontWeight: 700, textDecoration: "none", whiteSpace: "nowrap" }}>
          Telechaje Kounye a
        </a>
      </nav>


      {/* ── HERO ── */}
      <section id="hero" className="hero-section" style={{ minHeight: "100vh", display: "flex", alignItems: "center", position: "relative", overflow: "hidden", padding: "100px 32px 60px" }}>
        <div style={{ position: "absolute", top: "10%", left: "30%", width: 700, height: 700, background: "radial-gradient(ellipse, rgba(168,85,247,0.22) 0%, transparent 65%)", pointerEvents: "none" }} />
        <div style={{ position: "absolute", bottom: 0, right: 0, width: 500, height: 400, background: "radial-gradient(ellipse, rgba(236,72,153,0.12) 0%, transparent 65%)", pointerEvents: "none" }} />

        <div className="hero-inner" style={{ maxWidth: 1200, margin: "0 auto", width: "100%", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 60, alignItems: "center" }}>
          {/* Left */}
          <div className="hero-text">
            <div className="hero-badge" style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(168,85,247,0.12)", border: "1px solid rgba(168,85,247,0.3)", borderRadius: 99, padding: "6px 14px", marginBottom: 28 }}>
              <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#a855f7", display: "inline-block" }} />
              <span style={{ fontSize: 12, color: "#a855f7", fontWeight: 600, letterSpacing: 0.5 }}>Disponib sou iOS ak Android</span>
            </div>
            {/* hidden for now */}
            <p style={{ fontSize: 17, color: "#94a3b8", lineHeight: 1.75, marginBottom: 16, maxWidth: 480 }}>
              Debate, vote, epi agimante. Gran Boulva se kote vwa ou gen pwa reyèl — kominote ki pou moun ki pa pè di sa yo panse.
            </p>
            <p style={{ fontSize: 14, color: "#64748b", lineHeight: 1.6, marginBottom: 36, maxWidth: 420 }}>
              Fè tande vwa w, enfliyanse lide, epi ede chanje bagay yo.
            </p>
            <div className="hero-btns" style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
              <a href="https://apps.apple.com/app/gran-boulva" target="_blank" rel="noopener noreferrer"
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "#fff", color: "#0a0a0f", padding: "13px 24px", borderRadius: 14, fontWeight: 700, fontSize: 14, textDecoration: "none" }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                App Store
              </a>
              <a href="#" style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.12)", color: "#fff", padding: "13px 24px", borderRadius: 14, fontWeight: 600, fontSize: 14, textDecoration: "none" }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3.18 23.76c.28.15.6.16.89.04l13.12-7.33-2.88-2.89-11.13 10.18zm16.4-9.29L16.44 12l3.14-2.47 3.28 1.83c.94.52.94 1.76 0 2.28l-3.28 1.83zM2.08.28C1.74.54 1.5.99 1.5 1.58v20.84c0 .59.24 1.04.58 1.3L14.3 12 2.08.28zm11.26 11.4L3.18.24c-.29-.12-.61-.11-.89.04l11.13 10.19-2.08 1.21z" /></svg>
                Google Play
              </a>
            </div>
          </div>

          {/* Right — phone mockups */}
          <div className="hero-phones" style={{ position: "relative", display: "flex", justifyContent: "center", alignItems: "flex-end", height: 650 }}>
            <div style={{ position: "absolute", bottom: -40, left: "50%", transform: "translateX(-50%)", width: 360, height: 120, background: "radial-gradient(ellipse, rgba(168,85,247,0.5) 0%, transparent 70%)", filter: "blur(20px)", pointerEvents: "none" }} />
            {/* Back phone */}
            <div className="back-phone" style={{ position: "absolute", right: 20, bottom: 0, transform: "rotate(5deg)", zIndex: 1 }}>
              <div style={{ width: 220, height: 470, borderRadius: 16, border: "2px solid rgba(168,85,247,0.4)", boxShadow: "0 30px 80px rgba(168,85,247,0.3)" }}>
                <Image src="/screen2.png" alt="Matchup screen" width={220} height={530} style={{ objectFit: "cover", objectPosition: "top", borderRadius: 14, display: "block" }} />
              </div>
            </div>
            {/* Front phone */}
            <div className="phone-front" style={{ position: "relative", zIndex: 2, transform: "rotate(-3deg)" }}>
              <div style={{ width: 240, height: 516, borderRadius: 20, border: "2px solid rgba(168,85,247,0.6)", boxShadow: "0 40px 100px rgba(168,85,247,0.4), 0 0 0 1px rgba(255,255,255,0.05)" }}>
                <Image src="/screen1.png" alt="Home screen" width={240} height={570} style={{ objectFit: "cover", objectPosition: "top", borderRadius: 18, display: "block" }} />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── WHY GRAN BOULVA ── */}
      <section id="fonksyon" className="section-pad" style={{ padding: "100px 32px", position: "relative" }}>
        <div style={{ position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)", width: 800, height: 2, background: "linear-gradient(90deg, transparent, rgba(168,85,247,0.4), transparent)" }} />
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 64 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>Poukisa Gran Boulva?</p>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 44px)", fontWeight: 900, color: "#fff", margin: 0, letterSpacing: "-1px" }}>Yon eksperyans inik, bati pou kominote a</h2>
          </div>
          <div className="features-grid" style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 20, marginBottom: 60 }}>
            {FEATURES.map((f) => (
              <div key={f.title} style={{ background: "transparent", border: "1px solid rgba(168,85,247,0.2)", borderRadius: 20, padding: "28px 24px", transition: "transform 0.2s, border-color 0.2s" }}>
                <Image src={f.img} alt={f.title} width={52} height={52} style={{ marginBottom: 16, objectFit: "contain" }} />
                <h3 style={{ fontSize: 16, fontWeight: 800, color: "#fff", margin: "0 0 10px", textTransform: "uppercase", letterSpacing: 0.5 }}>{f.title}</h3>
                <p style={{ fontSize: 13, color: "#64748b", margin: 0, lineHeight: 1.7 }}>{f.desc}</p>
              </div>
            ))}
          </div>
          {/* Stats bar hidden for now */}
        </div>
      </section>

      {/* ── HOW IT WORKS ── */}
      <section id="kijan-sa-mache" className="section-pad" style={{ padding: "100px 32px", background: "rgba(168,85,247,0.03)", borderTop: "1px solid rgba(168,85,247,0.1)", borderBottom: "1px solid rgba(168,85,247,0.1)" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>

          {/* Header */}
          <div style={{ textAlign: "center", marginBottom: 64 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>Kijan li fonksyone</p>
            <h2 style={{ fontSize: "clamp(26px, 3.5vw, 40px)", fontWeight: 900, color: "#fff", margin: "0 0 12px", letterSpacing: "-0.8px" }}>3 etap senp pou fè tande vwa w</h2>
          </div>

          {/* 3 steps */}
          <div className="steps-row" style={{ display: "flex", alignItems: "flex-start", justifyContent: "center", marginBottom: 80 }}>
            {STEPS.flatMap((s, i) => [
              <div key={s.title} style={{ textAlign: "center", maxWidth: 260, padding: "0 24px" }}>
                <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#a855f7,#7c3aed)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 20px", boxShadow: "0 0 28px rgba(168,85,247,0.45)" }}>
                  <span style={{ fontSize: 22, fontWeight: 900, color: "#fff" }}>{i + 1}</span>
                </div>
                <h3 style={{ fontSize: 13, fontWeight: 800, color: "#fff", margin: "0 0 10px", letterSpacing: 1.5, textTransform: "uppercase" }}>{s.title}</h3>
                <p style={{ fontSize: 13, color: "#64748b", margin: 0, lineHeight: 1.7 }}>{s.desc}</p>
              </div>,
              i < STEPS.length - 1 ? (
                <div key={`arrow-${i}`} className="step-arrow" style={{ display: "flex", alignItems: "center", paddingBottom: 52, flexShrink: 0 }}>
                  <svg width="48" height="14" viewBox="0 0 48 14" fill="none">
                    <path d="M0 7 H40" stroke="rgba(168,85,247,0.45)" strokeWidth="1.5" strokeLinecap="round" />
                    <path d="M34 2 L46 7 L34 12" stroke="rgba(168,85,247,0.45)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
              ) : null,
            ])}
          </div>

          {/* TOUT SA W KAPAB FÈ */}
          <div className="kapab-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 80, alignItems: "center" }}>
            <div>
              <p style={{ color: "#a855f7", fontSize: 11, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>Tout sa w kapab fè</p>
              <h2 style={{ fontSize: "clamp(22px, 3vw, 34px)", fontWeight: 900, color: "#fff", margin: "0 0 32px", letterSpacing: "-0.5px" }}>Yon platfòm. Tout pouvwa ou.</h2>
              <div style={{ display: "flex", flexDirection: "column", gap: 14, marginBottom: 36 }}>
                {KAPAB.map((item) => (
                  <div key={item} style={{ display: "flex", alignItems: "center", gap: 12 }}>
                    <div style={{ width: 22, height: 22, borderRadius: "50%", background: "linear-gradient(135deg,#a855f7,#7c3aed)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                      <svg width="11" height="9" viewBox="0 0 11 9" fill="none"><path d="M1 4.5L4 7.5L10 1.5" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    </div>
                    <span style={{ fontSize: 14, color: "#94a3b8" }}>{item}</span>
                  </div>
                ))}
              </div>
              <a href="https://apps.apple.com/app/gran-boulva" target="_blank" rel="noopener noreferrer"
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", padding: "12px 28px", borderRadius: 99, fontWeight: 700, fontSize: 14, textDecoration: "none", boxShadow: "0 6px 24px rgba(168,85,247,0.4)" }}>
                Eksplore App a →
              </a>
            </div>
            <div className="kapab-phone" style={{ display: "flex", justifyContent: "center", position: "relative" }}>
              <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 300, height: 300, background: "radial-gradient(ellipse, rgba(168,85,247,0.3) 0%, transparent 70%)", filter: "blur(30px)", pointerEvents: "none" }} />
              <div style={{ width: 240, height: 520, borderRadius: 20, overflow: "hidden", border: "2px solid rgba(168,85,247,0.5)", boxShadow: "0 40px 100px rgba(168,85,247,0.35)", position: "relative", zIndex: 1 }}>
                <Image src="/screen3.png" alt="App screen" width={240} height={520} style={{ objectFit: "cover", objectPosition: "top" }} />
              </div>
            </div>
          </div>

        </div>
      </section>


      {/* ── DOWNLOAD CTA ── */}
      <section id="telecharje" className="section-pad" style={{ padding: "120px 32px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)", width: 1000, height: 500, background: "radial-gradient(ellipse, rgba(168,85,247,0.2) 0%, transparent 65%)", pointerEvents: "none" }} />
        <div className="cta-grid" style={{ maxWidth: 1100, margin: "0 auto", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 80, alignItems: "center", position: "relative", zIndex: 1 }}>
          <div>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 16 }}>Telecharje kounye a</p>
            <h2 style={{ fontSize: "clamp(32px, 5vw, 56px)", fontWeight: 900, color: "#fff", margin: "0 0 20px", letterSpacing: "-1.5px", lineHeight: 1.05 }}>
              Pare pou w fè tande w?
            </h2>
            <p style={{ fontSize: 16, color: "#94a3b8", marginBottom: 40, lineHeight: 1.75 }}>
              Telechaje Gran Boulva kounye a epi kòmanse fè vwa ou konte nan kominote ayisyen ki pi aktif la. Yon plat fòm pou ayisyen tout kote!
            </p>
            <div style={{ display: "flex", gap: 14, flexWrap: "wrap" }}>
              <a href="https://apps.apple.com/app/gran-boulva" target="_blank" rel="noopener noreferrer"
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", padding: "14px 28px", borderRadius: 14, fontWeight: 700, fontSize: 15, textDecoration: "none", boxShadow: "0 8px 30px rgba(168,85,247,0.4)" }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" /></svg>
                Download on App Store
              </a>
              <a href="#" style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.15)", color: "#fff", padding: "14px 28px", borderRadius: 14, fontWeight: 600, fontSize: 15, textDecoration: "none" }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M3.18 23.76c.28.15.6.16.89.04l13.12-7.33-2.88-2.89-11.13 10.18zm16.4-9.29L16.44 12l3.14-2.47 3.28 1.83c.94.52.94 1.76 0 2.28l-3.28 1.83zM2.08.28C1.74.54 1.5.99 1.5 1.58v20.84c0 .59.24 1.04.58 1.3L14.3 12 2.08.28zm11.26 11.4L3.18.24c-.29-.12-.61-.11-.89.04l11.13 10.19-2.08 1.21z" /></svg>
                Get it on Google Play
              </a>
            </div>
          </div>
          {/* Phone */}
          <div style={{ display: "flex", justifyContent: "center", position: "relative" }}>
            <div style={{ position: "absolute", bottom: -60, left: "50%", transform: "translateX(-50%)", width: 300, height: 150, background: "radial-gradient(ellipse, rgba(168,85,247,0.6) 0%, transparent 70%)", filter: "blur(24px)", pointerEvents: "none" }} />
            <div style={{ width: 250, height: 529, borderRadius: 20, overflow: "hidden", border: "2px solid rgba(168,85,247,0.6)", boxShadow: "0 50px 120px rgba(168,85,247,0.45)", position: "relative", zIndex: 1 }}>
              <Image src="/screen1.png" alt="App preview" width={250} height={523} style={{ objectFit: "cover", objectPosition: "top" }} />
            </div>
          </div>
        </div>
      </section>

      {/* ── FOOTER ── */}
      <footer style={{ borderTop: "1px solid rgba(168,85,247,0.15)", padding: "48px 32px 32px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div className="footer-top" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 40, flexWrap: "wrap", gap: 32 }}>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
                <Image src="/logo.png" alt="Gran Boulva" width={28} height={28} style={{ borderRadius: 6 }} />
                <span style={{ fontWeight: 800, fontSize: 16, color: "#fff" }}>Gran Boulva</span>
              </div>
              <p style={{ fontSize: 13, color: "#475569", maxWidth: 260, lineHeight: 1.6, margin: 0 }}>Platfòm deba sosyal ki bay vwa ou yon pwa reyèl.</p>
            </div>
            <div style={{ display: "flex", gap: 48, flexWrap: "wrap" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Aplikasyon</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  {["App Store", "Google Play"].map(l => <a key={l} href="#" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>{l}</a>)}
                </div>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Legal</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  {[["Privacy Policy", "/privacy"], ["Terms of Service", "/terms"], ["Acceptable Use", "/aup"], ["DMCA", "/dmca"], ["Cookies", "/cookies"]].map(([l, h]) => (
                    <Link key={h} href={h} style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>{l}</Link>
                  ))}
                </div>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Kontak</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  <a href="mailto:support@granboulva.com" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>support@granboulva.com</a>
                  {/* <Link href="/login" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>Admin Dashboard</Link>*/}
                </div>
              </div>
            </div>
          </div>
          <div style={{ borderTop: "1px solid rgba(255,255,255,0.05)", paddingTop: 24, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
            <span style={{ fontSize: 12, color: "#1e2040" }}>© {new Date().getFullYear()} Gran Boulva. All rights reserved.</span>
            <span style={{ fontSize: 12, color: "#1e2040" }}>Sa se pou pèp Ayisyen an</span>
          </div>
        </div>
      </footer>

      <style>{`
        @keyframes slideBackPhone {
          0%   { opacity: 0; transform: rotate(5deg) translateX(-80px); }
          100% { opacity: 1; transform: rotate(5deg) translateX(0); }
        }
        @keyframes slideFrontPhone {
          0%   { opacity: 0; transform: rotate(-3deg) translateX(-80px); }
          100% { opacity: 1; transform: rotate(-3deg) translateX(0); }
        }
        @keyframes slideFrontPhoneMobile {
          0%   { opacity: 0; transform: translateX(-80px); }
          100% { opacity: 1; transform: translateX(0); }
        }
        .back-phone  { animation: slideBackPhone  0.7s ease-out 0.1s both; }
        .phone-front { animation: slideFrontPhone 0.7s ease-out 0.3s both; }

        @media (max-width: 768px) {
          /* Nav */
          .nav-links { display: none !important; }
          .nav-cta { font-size: 11px !important; padding: 8px 14px !important; }

          /* Hero */
          .hero-section { padding: 90px 20px 48px !important; min-height: auto !important; }
          .hero-inner { grid-template-columns: 1fr !important; gap: 40px !important; }
          .hero-text { text-align: center; }
          .hero-badge { margin-left: auto; margin-right: auto; }
          .hero-btns { justify-content: center !important; }
          .hero-phones { height: 360px !important; padding-bottom: 15px !important; }
          .back-phone { display: none !important; }
          .hero-phones > div:last-child { transform: rotate(0deg) !important; animation: slideFrontPhoneMobile 0.7s ease-out 0.3s both, phonefloat 3.5s ease-in-out 1.2s infinite; }
          .hero-phones > div:last-child > div { width: 190px !important; height: 390px !important; padding-bottom: 5px !important; border: none !important; box-shadow: none !important; }

          /* Sections */
          .section-pad { padding: 64px 20px !important; }

          /* Features */
          .features-grid { grid-template-columns: 1fr 1fr !important; gap: 12px !important; }

          /* Steps */
          .steps-row {
            flex-direction: column !important;
            align-items: center !important;
            gap: 8px !important;
            margin-bottom: 48px !important;
          }
          .step-arrow {
            padding-bottom: 0 !important;
            transform: rotate(90deg);
          }

          /* KAPAB */
          .kapab-grid { grid-template-columns: 1fr !important; gap: 40px !important; }
          .kapab-phone { display: none !important; }

          /* CTA */
          .cta-grid { grid-template-columns: 1fr !important; gap: 40px !important; }
          .cta-grid > div:last-child { display: none !important; }

          /* Footer */
          .footer-top { flex-direction: column !important; }
        }

        @keyframes phonefloat {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
        }

        @media (max-width: 480px) {
          .features-grid { grid-template-columns: 1fr !important; }
          .hero-phones { height: 300px !important; }
          .hero-phones > div:last-child > div { width: 160px !important; height: 290px !important; }
        }
      `}</style>
    </div>
  );
}
