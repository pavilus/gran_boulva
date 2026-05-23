"use client";
import Link from "next/link";
import Image from "next/image";
import { useState, useEffect, useRef } from "react";

// ── Data ──────────────────────────────────────────────────────────────────────

const NAV_LINKS = [
  { label: "Features",   href: "#features" },
  { label: "Vision",     href: "#vision" },
  { label: "Creators",   href: "#creators" },
  { label: "Supporters", href: "#supporters" },
  { label: "FAQ",        href: "#faq" },
];

const FEATURES = [
  { img: "/icon-debat.png",     title: "Live Debates",          desc: "Users battle ideas live while the community votes in real time." },
  { img: "/icon-vote.png",      title: "Creator Battles",       desc: "Influencers compete for rankings, visibility, and rewards." },
  { img: "/icon-prediksyon.png",title: "Predictions",           desc: "Predict outcomes of events, debates, trends, and competitions." },
  { img: "/icon-enpak.png",     title: "Creator Monetization",  desc: "Tips, subscriptions, gifts, and supporter badges — earn from your influence." },
  { img: "/icon-kominote.png",  title: "Influence Rankings",    desc: "Dynamic leaderboards for creators and communities — rise to the top." },
  { img: "/icon-sekirite.png",  title: "Community Power",       desc: "The audience decides what trends, creators, and conversations rise." },
];

const VISION_POINTS = [
  { icon: "🌍", title: "Diaspora Connection",      desc: "Bridging Haitians across Haiti, the US, Canada, France, and the Caribbean." },
  { icon: "💡", title: "Creator Empowerment",      desc: "Giving creators the tools and economy to turn influence into income." },
  { icon: "🏆", title: "Community Ownership",      desc: "The community shapes what rises — not algorithms controlled by outsiders." },
  { icon: "🚀", title: "Culture-Driven Technology", desc: "Tech built for and by our culture, not adapted from something else." },
];

const CREATOR_PERKS = [
  "Live debates & creator battles with real audiences",
  "Monetize through tips, subscriptions, and supporter badges",
  "Dynamic influence rankings that reward consistency",
  "Built-in prediction markets for event creators",
  "Creator analytics and audience engagement insights",
  "Priority verification for top voices in the community",
];

const TIERS = [
  {
    key: "supporter",
    name: "Supporter",
    price: "$9",
    period: "one-time",
    color: "#64748b",
    glow: "rgba(100,116,139,0.3)",
    badge: "🎖️",
    perks: [
      "Early access to the platform",
      "Supporter badge on your profile",
      "Exclusive supporter newsletter",
      "Gran Boulva community Discord",
    ],
  },
  {
    key: "ambassador",
    name: "Ambassador",
    price: "$49",
    period: "one-time",
    color: "#a855f7",
    glow: "rgba(168,85,247,0.35)",
    badge: "⭐",
    popular: true,
    perks: [
      "Everything in Supporter",
      "Ambassador badge (permanent)",
      "Name on the founding wall",
      "Vote on platform features",
      "Founding Ambassador Discord role",
    ],
  },
  {
    key: "founding_creator",
    name: "Founding Creator",
    price: "$149",
    period: "one-time",
    color: "#f59e0b",
    glow: "rgba(245,158,11,0.35)",
    badge: "🔥",
    perks: [
      "Everything in Ambassador",
      "Founding Creator badge (lifetime)",
      "Priority creator verification",
      "Creator tools early access",
      "Featured in founding creators wall",
      "Direct feedback channel to team",
    ],
  },
  {
    key: "founding_partner",
    name: "Founding Partner",
    price: "$499",
    period: "one-time",
    color: "#ec4899",
    glow: "rgba(236,72,153,0.35)",
    badge: "👑",
    perks: [
      "Everything in Founding Creator",
      "Founding Partner badge (permanent gold)",
      "Founding Partner recognition wall (forever)",
      "Founding call with the team",
      "Input on platform roadmap",
      "Lifetime platform perks",
    ],
  },
];

const FAQ_ITEMS = [
  {
    q: "What is Gran Boulva?",
    a: "Gran Boulva is a Haitian creator economy and social influence platform — a digital home for live debates, creator battles, predictions, community voting, and influence rankings. Think TikTok + Twitch + FanDuel, built specifically for Haitian and Caribbean culture.",
  },
  {
    q: "When is the launch?",
    a: "Gran Boulva is currently in early access on iOS. We're building toward a full public launch. Join the waitlist to be among the first — founding members get priority access and exclusive perks.",
  },
  {
    q: "Is it only for Haitians?",
    a: "Gran Boulva was built by Haitians, for Haitians — but anyone who loves our culture, our energy, and our community is welcome. The platform celebrates Caribbean culture broadly and welcomes allies worldwide.",
  },
  {
    q: "How do creators make money?",
    a: "Multiple streams: tips from supporters, subscription revenue, gifts during live events, creator battle prizes, supporter badges, boost revenue, and more. Gran Boulva is built to give creators real economic power.",
  },
  {
    q: "How can I become a founding supporter?",
    a: "Choose a founding tier above — Supporter, Ambassador, Founding Creator, or Founding Partner — and reserve your spot. Founding supporter access is limited. Early supporters get lifetime perks and permanent recognition.",
  },
  {
    q: "Will there be a mobile app?",
    a: "Gran Boulva is already available on iOS. Android is coming soon. The full web experience is also in development. Download the iOS app now or join the waitlist for early access.",
  },
];

// ── Helpers ───────────────────────────────────────────────────────────────────

function smoothScroll(id: string) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

// ── Main ──────────────────────────────────────────────────────────────────────

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [selectedTier, setSelectedTier] = useState<string | null>(null);

  // Waitlist form
  const [wName, setWName] = useState("");
  const [wEmail, setWEmail] = useState("");
  const [wCreator, setWCreator] = useState(false);
  const [wSupporter, setWSupporter] = useState(false);
  const [wSubmitting, setWSubmitting] = useState(false);
  const [wDone, setWDone] = useState(false);
  const [wError, setWError] = useState("");
  const waitlistRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);

  async function submitWaitlist(e: React.FormEvent) {
    e.preventDefault();
    setWSubmitting(true);
    setWError("");
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: wName, email: wEmail, is_creator: wCreator, is_supporter: wSupporter, tier: selectedTier }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Something went wrong");
      setWDone(true);
    } catch (err) {
      setWError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setWSubmitting(false);
    }
  }

  function pickTier(key: string) {
    setSelectedTier(key);
    waitlistRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
    setWSupporter(true);
  }

  return (
    <div style={{ background: "#07080f", color: "#e2e8f0", fontFamily: "'Poppins', system-ui, sans-serif", overflowX: "hidden" }}>

      {/* ── NAV ─────────────────────────────────────────────────────────── */}
      <nav style={{
        position: "fixed", top: 0, left: 0, right: 0, zIndex: 100,
        padding: "0 24px", height: 64,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        background: scrolled ? "rgba(7,8,15,0.96)" : "transparent",
        backdropFilter: scrolled ? "blur(18px)" : "none",
        borderBottom: scrolled ? "1px solid rgba(168,85,247,0.15)" : "none",
        transition: "all 0.3s",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <Image src="/logo.png" alt="Gran Boulva" width={32} height={32} style={{ borderRadius: 8 }} />
          <span style={{ fontWeight: 800, fontSize: 17, color: "#fff", letterSpacing: "-0.3px" }}>Gran Boulva</span>
        </div>
        <div className="nav-links" style={{ display: "flex", alignItems: "center", gap: 28, position: "absolute", left: "50%", transform: "translateX(-50%)" }}>
          {NAV_LINKS.map(({ label, href }) => (
            <a key={href} href={href}
              style={{ color: "#94a3b8", fontSize: 13, fontWeight: 500, textDecoration: "none" }}>
              {label}
            </a>
          ))}
        </div>
        <button
          onClick={() => smoothScroll("waitlist")}
          className="nav-cta"
          style={{ background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", padding: "9px 20px", borderRadius: 99, fontSize: 13, fontWeight: 700, border: "none", cursor: "pointer", whiteSpace: "nowrap" }}>
          Join the Waitlist
        </button>
      </nav>

      {/* ── HERO ─────────────────────────────────────────────────────────── */}
      <section style={{ minHeight: "100vh", display: "flex", alignItems: "center", position: "relative", overflow: "hidden", padding: "110px 32px 60px" }}>
        {/* Glows */}
        <div style={{ position: "absolute", top: "5%", left: "20%", width: 800, height: 700, background: "radial-gradient(ellipse, rgba(168,85,247,0.2) 0%, transparent 65%)", pointerEvents: "none" }} />
        <div style={{ position: "absolute", bottom: 0, right: "5%", width: 500, height: 400, background: "radial-gradient(ellipse, rgba(236,72,153,0.12) 0%, transparent 65%)", pointerEvents: "none" }} />

        <div className="hero-inner" style={{ maxWidth: 1200, margin: "0 auto", width: "100%", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 60, alignItems: "center" }}>
          {/* Text */}
          <div className="hero-text">
            <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(168,85,247,0.12)", border: "1px solid rgba(168,85,247,0.3)", borderRadius: 99, padding: "6px 14px", marginBottom: 28 }}>
              <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#a855f7", display: "inline-block", animation: "pulse 2s infinite" }} />
              <span style={{ fontSize: 12, color: "#a855f7", fontWeight: 600, letterSpacing: 0.5 }}>Available on iOS · Android Coming Soon</span>
            </div>

            <h1 style={{ fontSize: "clamp(34px, 5vw, 62px)", fontWeight: 900, color: "#fff", margin: "0 0 20px", letterSpacing: "-2px", lineHeight: 1.05 }}>
              Where Haitian Culture,{" "}
              <span style={{ background: "linear-gradient(90deg,#a855f7,#ec4899)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                Creators, and Influence
              </span>{" "}
              Go Live.
            </h1>

            <p style={{ fontSize: 16, color: "#94a3b8", lineHeight: 1.75, marginBottom: 12, maxWidth: 500 }}>
              Gran Boulva is building the digital home for Haitian creators, debates, livestreams, predictions, and community influence.
            </p>
            <p style={{ fontSize: 14, color: "#64748b", lineHeight: 1.6, marginBottom: 36, maxWidth: 420 }}>
              Fè tande vwa w, enfliyanse lide, epi ede chanje bagay yo.
            </p>

            <div className="hero-btns" style={{ display: "flex", gap: 14, flexWrap: "wrap", marginBottom: 48 }}>
              <button
                onClick={() => smoothScroll("waitlist")}
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", padding: "14px 28px", borderRadius: 14, fontWeight: 700, fontSize: 15, border: "none", cursor: "pointer", boxShadow: "0 8px 30px rgba(168,85,247,0.4)" }}>
                Join the Waitlist →
              </button>
              <button
                onClick={() => smoothScroll("supporters")}
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "rgba(245,158,11,0.1)", border: "1px solid rgba(245,158,11,0.4)", color: "#f59e0b", padding: "14px 28px", borderRadius: 14, fontWeight: 700, fontSize: 15, cursor: "pointer" }}>
                👑 Become a Founding Supporter
              </button>
            </div>

            {/* Social proof */}
            <div className="social-proof" style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
              {[
                { num: "1,200+", label: "Creators on Waitlist" },
                { num: "3,400+", label: "Early Supporters" },
                { num: "28",     label: "Countries" },
              ].map(({ num, label }) => (
                <div key={label}>
                  <div style={{ fontSize: 22, fontWeight: 900, color: "#fff", letterSpacing: "-0.5px" }}>{num}</div>
                  <div style={{ fontSize: 12, color: "#475569", marginTop: 2 }}>{label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Phones */}
          <div className="hero-phones" style={{ position: "relative", display: "flex", justifyContent: "center", alignItems: "flex-end", height: 640 }}>
            <div style={{ position: "absolute", bottom: -40, left: "50%", transform: "translateX(-50%)", width: 360, height: 120, background: "radial-gradient(ellipse, rgba(168,85,247,0.5) 0%, transparent 70%)", filter: "blur(20px)", pointerEvents: "none" }} />
            <div className="back-phone" style={{ position: "absolute", right: 20, bottom: 0, transform: "rotate(5deg)", zIndex: 1 }}>
              <div style={{ width: 220, height: 470, borderRadius: 16, border: "2px solid rgba(168,85,247,0.4)", boxShadow: "0 30px 80px rgba(168,85,247,0.3)" }}>
                <Image src="/screen2.png" alt="Matchup screen" width={220} height={530} style={{ objectFit: "cover", objectPosition: "top", borderRadius: 14, display: "block" }} />
              </div>
            </div>
            <div className="phone-front" style={{ position: "relative", zIndex: 2, transform: "rotate(-3deg)" }}>
              <div style={{ width: 240, height: 516, borderRadius: 20, border: "2px solid rgba(168,85,247,0.6)", boxShadow: "0 40px 100px rgba(168,85,247,0.4), 0 0 0 1px rgba(255,255,255,0.05)" }}>
                <Image src="/screen1.png" alt="Home screen" width={240} height={570} style={{ objectFit: "cover", objectPosition: "top", borderRadius: 18, display: "block" }} />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── FEATURES ─────────────────────────────────────────────────────── */}
      <section id="features" style={{ padding: "100px 32px", position: "relative" }}>
        <div style={{ position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)", width: 800, height: 2, background: "linear-gradient(90deg, transparent, rgba(168,85,247,0.4), transparent)" }} />
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 64 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>What We're Building</p>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 44px)", fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-1px" }}>
              Everything the Haitian community deserves
            </h2>
            <p style={{ fontSize: 16, color: "#64748b", maxWidth: 520, margin: "0 auto" }}>
              One platform. Six pillars of culture, competition, and community.
            </p>
          </div>
          <div className="features-grid" style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 20 }}>
            {FEATURES.map((f) => (
              <div key={f.title} style={{ background: "rgba(168,85,247,0.04)", border: "1px solid rgba(168,85,247,0.15)", borderRadius: 20, padding: "28px 24px", transition: "border-color 0.2s" }}
                onMouseEnter={e => (e.currentTarget.style.borderColor = "rgba(168,85,247,0.4)")}
                onMouseLeave={e => (e.currentTarget.style.borderColor = "rgba(168,85,247,0.15)")}>
                <Image src={f.img} alt={f.title} width={52} height={52} style={{ marginBottom: 16, objectFit: "contain" }} />
                <h3 style={{ fontSize: 15, fontWeight: 800, color: "#fff", margin: "0 0 10px" }}>{f.title}</h3>
                <p style={{ fontSize: 13, color: "#64748b", margin: 0, lineHeight: 1.7 }}>{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── VISION ───────────────────────────────────────────────────────── */}
      <section id="vision" style={{ padding: "120px 32px", background: "linear-gradient(180deg, rgba(168,85,247,0.06) 0%, rgba(7,8,15,0) 100%)", borderTop: "1px solid rgba(168,85,247,0.1)", borderBottom: "1px solid rgba(168,85,247,0.1)", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 900, height: 600, background: "radial-gradient(ellipse, rgba(168,85,247,0.12) 0%, transparent 65%)", pointerEvents: "none" }} />
        <div style={{ maxWidth: 1100, margin: "0 auto", position: "relative", zIndex: 1 }}>
          <div style={{ textAlign: "center", marginBottom: 72 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 20 }}>Our Vision</p>
            <h2 style={{ fontSize: "clamp(28px, 4.5vw, 52px)", fontWeight: 900, color: "#fff", margin: "0 auto 24px", letterSpacing: "-1.5px", lineHeight: 1.1, maxWidth: 800 }}>
              Gran Boulva is more than a social app.
            </h2>
            <p style={{ fontSize: "clamp(17px, 2vw, 22px)", color: "#a78bfa", fontWeight: 600, margin: "0 auto 20px", maxWidth: 700, lineHeight: 1.5 }}>
              It is the digital infrastructure for Haitian and Caribbean culture.
            </p>
            <p style={{ fontSize: 16, color: "#64748b", maxWidth: 640, margin: "0 auto", lineHeight: 1.8 }}>
              For too long, the Haitian community has built culture without owning the platforms it runs on.
              Gran Boulva changes that — giving creators, communities, and voices the tools to define their own narrative,
              build real income, and shape the world's perception of Haiti.
            </p>
          </div>

          <div className="vision-grid" style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 24 }}>
            {VISION_POINTS.map((v) => (
              <div key={v.title} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(168,85,247,0.15)", borderRadius: 20, padding: "28px 28px", display: "flex", gap: 20, alignItems: "flex-start" }}>
                <div style={{ fontSize: 32, flexShrink: 0, marginTop: 2 }}>{v.icon}</div>
                <div>
                  <h3 style={{ fontSize: 16, fontWeight: 800, color: "#fff", margin: "0 0 8px" }}>{v.title}</h3>
                  <p style={{ fontSize: 14, color: "#64748b", margin: 0, lineHeight: 1.7 }}>{v.desc}</p>
                </div>
              </div>
            ))}
          </div>

          <div style={{ textAlign: "center", marginTop: 56 }}>
            <p style={{ fontSize: 20, fontWeight: 800, color: "#fff", marginBottom: 8 }}>
              "Sa se pou pèp Ayisyen an."
            </p>
            <p style={{ fontSize: 13, color: "#475569" }}>This is for the Haitian people.</p>
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS ─────────────────────────────────────────────────── */}
      <section style={{ padding: "100px 32px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 64 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>Kijan li fonksyone</p>
            <h2 style={{ fontSize: "clamp(26px, 3.5vw, 40px)", fontWeight: 900, color: "#fff", margin: "0 0 12px", letterSpacing: "-0.8px" }}>3 etap senp pou fè tande vwa w</h2>
          </div>
          <div className="steps-row" style={{ display: "flex", alignItems: "flex-start", justifyContent: "center" }}>
            {[
              { title: "LI epi AGIMANTE", desc: "Li sijè yo, pataje agiman ou ak kominote a." },
              { title: "VOTE",            desc: "Vote pou pozisyon ou kwè ki pi solid." },
              { title: "ENPAKTE",         desc: "Ranmase pwen, monte rank, epi peze nan balans lan." },
            ].flatMap((s, i, arr) => [
              <div key={s.title} style={{ textAlign: "center", maxWidth: 260, padding: "0 24px" }}>
                <div style={{ width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#a855f7,#7c3aed)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 20px", boxShadow: "0 0 28px rgba(168,85,247,0.45)" }}>
                  <span style={{ fontSize: 22, fontWeight: 900, color: "#fff" }}>{i + 1}</span>
                </div>
                <h3 style={{ fontSize: 13, fontWeight: 800, color: "#fff", margin: "0 0 10px", letterSpacing: 1.5, textTransform: "uppercase" }}>{s.title}</h3>
                <p style={{ fontSize: 13, color: "#64748b", margin: 0, lineHeight: 1.7 }}>{s.desc}</p>
              </div>,
              i < arr.length - 1 ? (
                <div key={`arrow-${i}`} className="step-arrow" style={{ display: "flex", alignItems: "center", paddingBottom: 52, flexShrink: 0 }}>
                  <svg width="48" height="14" viewBox="0 0 48 14" fill="none">
                    <path d="M0 7 H40" stroke="rgba(168,85,247,0.45)" strokeWidth="1.5" strokeLinecap="round" />
                    <path d="M34 2 L46 7 L34 12" stroke="rgba(168,85,247,0.45)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
              ) : null,
            ])}
          </div>
        </div>
      </section>

      {/* ── CREATOR SECTION ──────────────────────────────────────────────── */}
      <section id="creators" style={{ padding: "120px 32px", background: "rgba(168,85,247,0.03)", borderTop: "1px solid rgba(168,85,247,0.1)", borderBottom: "1px solid rgba(168,85,247,0.1)" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div className="creator-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 80, alignItems: "center" }}>
            <div>
              <p style={{ color: "#ec4899", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 16 }}>For Creators</p>
              <h2 style={{ fontSize: "clamp(28px, 4vw, 46px)", fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-1.2px", lineHeight: 1.1 }}>
                Build Your Audience.{" "}
                <span style={{ background: "linear-gradient(90deg,#ec4899,#a855f7)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
                  Own Your Influence.
                </span>
              </h2>
              <p style={{ fontSize: 15, color: "#64748b", lineHeight: 1.75, marginBottom: 36, maxWidth: 460 }}>
                Gran Boulva gives creators the tools, audience, and monetization streams to turn passion into a career —
                without relying on platforms that don't understand our culture.
              </p>
              <div style={{ display: "flex", flexDirection: "column", gap: 14, marginBottom: 40 }}>
                {CREATOR_PERKS.map((item) => (
                  <div key={item} style={{ display: "flex", alignItems: "flex-start", gap: 12 }}>
                    <div style={{ width: 22, height: 22, borderRadius: "50%", background: "linear-gradient(135deg,#ec4899,#a855f7)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, marginTop: 1 }}>
                      <svg width="11" height="9" viewBox="0 0 11 9" fill="none"><path d="M1 4.5L4 7.5L10 1.5" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    </div>
                    <span style={{ fontSize: 14, color: "#94a3b8", lineHeight: 1.5 }}>{item}</span>
                  </div>
                ))}
              </div>
              <button
                onClick={() => smoothScroll("waitlist")}
                style={{ display: "inline-flex", alignItems: "center", gap: 10, background: "linear-gradient(135deg,#ec4899,#a855f7)", color: "#fff", padding: "13px 28px", borderRadius: 99, fontWeight: 700, fontSize: 14, border: "none", cursor: "pointer", boxShadow: "0 6px 24px rgba(236,72,153,0.4)" }}>
                Apply as a Creator →
              </button>
            </div>

            {/* Creator visual */}
            <div style={{ display: "flex", justifyContent: "center", position: "relative" }}>
              <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%,-50%)", width: 320, height: 320, background: "radial-gradient(ellipse, rgba(236,72,153,0.25) 0%, transparent 70%)", filter: "blur(30px)", pointerEvents: "none" }} />
              {/* Creator stat cards */}
              <div style={{ position: "relative", zIndex: 1, display: "flex", flexDirection: "column", gap: 16, width: "100%", maxWidth: 340 }}>
                {[
                  { label: "Avg. creator earnings / month", value: "$240", sub: "from tips + badges + boosts", color: "#a855f7" },
                  { label: "Top creator ranking", value: "#1 Vwa", sub: "on leaderboard this week", color: "#ec4899" },
                  { label: "Community engagement rate", value: "34%", sub: "vs 3% on legacy platforms", color: "#f59e0b" },
                ].map((stat) => (
                  <div key={stat.label} style={{ background: "rgba(255,255,255,0.04)", border: `1px solid ${stat.color}33`, borderRadius: 16, padding: "18px 20px", display: "flex", alignItems: "center", gap: 16 }}>
                    <div style={{ width: 4, borderRadius: 2, alignSelf: "stretch", background: stat.color, flexShrink: 0 }} />
                    <div>
                      <div style={{ fontSize: 11, color: "#475569", marginBottom: 4, fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5 }}>{stat.label}</div>
                      <div style={{ fontSize: 22, fontWeight: 900, color: stat.color, letterSpacing: "-0.5px" }}>{stat.value}</div>
                      <div style={{ fontSize: 11, color: "#475569", marginTop: 2 }}>{stat.sub}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── FOUNDING SUPPORTER TIERS ─────────────────────────────────────── */}
      <section id="supporters" style={{ padding: "120px 32px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: "30%", left: "50%", transform: "translateX(-50%)", width: 900, height: 500, background: "radial-gradient(ellipse, rgba(245,158,11,0.08) 0%, transparent 65%)", pointerEvents: "none" }} />
        <div style={{ maxWidth: 1100, margin: "0 auto", position: "relative", zIndex: 1 }}>
          <div style={{ textAlign: "center", marginBottom: 16 }}>
            <p style={{ color: "#f59e0b", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 16 }}>Limited Availability</p>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 48px)", fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-1.2px" }}>
              Become a Founding Supporter
            </h2>
            <p style={{ fontSize: 16, color: "#64748b", maxWidth: 560, margin: "0 auto 16px" }}>
              Founding supporter access is limited. Early supporters get lifetime perks, permanent recognition, and a direct line to the team building Gran Boulva.
            </p>
            <p style={{ fontSize: 13, color: "#f59e0b", fontWeight: 600 }}>⚡ Founding member spots are going fast</p>
          </div>

          <div className="tiers-grid" style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16, marginTop: 56 }}>
            {TIERS.map((tier) => (
              <div key={tier.key} style={{
                background: tier.popular ? `linear-gradient(180deg, ${tier.color}18 0%, rgba(7,8,15,0.8) 100%)` : "rgba(255,255,255,0.03)",
                border: `1px solid ${tier.popular ? tier.color + "66" : tier.color + "33"}`,
                borderRadius: 20,
                padding: "28px 22px",
                position: "relative",
                display: "flex",
                flexDirection: "column",
              }}>
                {tier.popular && (
                  <div style={{ position: "absolute", top: -12, left: "50%", transform: "translateX(-50%)", background: tier.color, color: "#fff", fontSize: 10, fontWeight: 800, padding: "4px 14px", borderRadius: 99, whiteSpace: "nowrap", letterSpacing: 0.5 }}>
                    MOST POPULAR
                  </div>
                )}
                <div style={{ fontSize: 32, marginBottom: 12 }}>{tier.badge}</div>
                <h3 style={{ fontSize: 15, fontWeight: 800, color: "#fff", margin: "0 0 4px" }}>{tier.name}</h3>
                <div style={{ marginBottom: 20 }}>
                  <span style={{ fontSize: 32, fontWeight: 900, color: tier.color, letterSpacing: "-1px" }}>{tier.price}</span>
                  <span style={{ fontSize: 13, color: "#475569", marginLeft: 6 }}>{tier.period}</span>
                </div>
                <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10, marginBottom: 24 }}>
                  {tier.perks.map((perk) => (
                    <div key={perk} style={{ display: "flex", gap: 8, alignItems: "flex-start" }}>
                      <span style={{ color: tier.color, fontSize: 13, marginTop: 1, flexShrink: 0 }}>✓</span>
                      <span style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.5 }}>{perk}</span>
                    </div>
                  ))}
                </div>
                <button
                  onClick={() => pickTier(tier.key)}
                  style={{ width: "100%", padding: "12px", borderRadius: 12, fontWeight: 700, fontSize: 13, cursor: "pointer", border: `1px solid ${tier.color}`, background: tier.popular ? tier.color : "transparent", color: tier.popular ? "#fff" : tier.color, transition: "all 0.2s" }}
                  onMouseEnter={e => { if (!tier.popular) { (e.currentTarget as HTMLButtonElement).style.background = tier.color; (e.currentTarget as HTMLButtonElement).style.color = "#fff"; }}}
                  onMouseLeave={e => { if (!tier.popular) { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; (e.currentTarget as HTMLButtonElement).style.color = tier.color; }}}>
                  Reserve Your Spot
                </button>
              </div>
            ))}
          </div>

          <p style={{ textAlign: "center", fontSize: 12, color: "#1e3a5f", marginTop: 24 }}>
            Payments processed securely via Stripe · Founding perks are lifetime commitments from Gran Boulva
          </p>
        </div>
      </section>

      {/* ── WAITLIST ─────────────────────────────────────────────────────── */}
      <section id="waitlist" ref={waitlistRef} style={{ padding: "120px 32px", background: "rgba(168,85,247,0.04)", borderTop: "1px solid rgba(168,85,247,0.1)" }}>
        <div style={{ maxWidth: 560, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 48 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 16 }}>Join the Waitlist</p>
            <h2 style={{ fontSize: "clamp(28px, 4vw, 42px)", fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-1px" }}>
              Reserve Your Spot
            </h2>
            <p style={{ fontSize: 15, color: "#64748b", lineHeight: 1.7 }}>
              Founding member access is limited. Be the first to know when we open — and get priority access to the platform.
            </p>
            {selectedTier && (
              <div style={{ marginTop: 16, display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(245,158,11,0.1)", border: "1px solid rgba(245,158,11,0.3)", borderRadius: 99, padding: "6px 14px" }}>
                <span style={{ fontSize: 12, color: "#f59e0b", fontWeight: 700 }}>
                  👑 {TIERS.find(t => t.key === selectedTier)?.name} tier selected
                </span>
                <button onClick={() => setSelectedTier(null)} style={{ background: "none", border: "none", color: "#64748b", cursor: "pointer", fontSize: 14, lineHeight: 1 }}>×</button>
              </div>
            )}
          </div>

          {wDone ? (
            <div style={{ textAlign: "center", padding: "48px 32px", background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.25)", borderRadius: 24 }}>
              <div style={{ fontSize: 48, marginBottom: 16 }}>🎉</div>
              <h3 style={{ fontSize: 22, fontWeight: 900, color: "#fff", margin: "0 0 12px" }}>You&apos;re on the list!</h3>
              <p style={{ fontSize: 15, color: "#64748b", lineHeight: 1.7, margin: 0 }}>
                We&apos;ll reach out as soon as founding access opens. Welcome to the movement — <em>Gran Boulva ap vini!</em>
              </p>
            </div>
          ) : (
            <form onSubmit={submitWaitlist} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid rgba(168,85,247,0.2)", borderRadius: 24, padding: "40px 36px", display: "flex", flexDirection: "column", gap: 18 }}>
              <div>
                <label style={{ fontSize: 12, color: "#64748b", fontWeight: 600, display: "block", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.5 }}>Your Name</label>
                <input
                  required value={wName} onChange={(e) => setWName(e.target.value)}
                  placeholder="Jean-Pierre Louis"
                  style={{ width: "100%", padding: "13px 16px", borderRadius: 12, background: "#0a0b18", border: "1px solid rgba(168,85,247,0.2)", color: "#fff", fontSize: 15, outline: "none", boxSizing: "border-box" }}
                  onFocus={e => (e.target.style.borderColor = "rgba(168,85,247,0.6)")}
                  onBlur={e => (e.target.style.borderColor = "rgba(168,85,247,0.2)")}
                />
              </div>
              <div>
                <label style={{ fontSize: 12, color: "#64748b", fontWeight: 600, display: "block", marginBottom: 8, textTransform: "uppercase", letterSpacing: 0.5 }}>Email Address</label>
                <input
                  required type="email" value={wEmail} onChange={(e) => setWEmail(e.target.value)}
                  placeholder="you@example.com"
                  style={{ width: "100%", padding: "13px 16px", borderRadius: 12, background: "#0a0b18", border: "1px solid rgba(168,85,247,0.2)", color: "#fff", fontSize: 15, outline: "none", boxSizing: "border-box" }}
                  onFocus={e => (e.target.style.borderColor = "rgba(168,85,247,0.6)")}
                  onBlur={e => (e.target.style.borderColor = "rgba(168,85,247,0.2)")}
                />
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                <label style={{ fontSize: 12, color: "#64748b", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5 }}>I am joining as… (select all that apply)</label>
                {[
                  { key: "creator", label: "🎤 A Creator — I want to build an audience on Gran Boulva", val: wCreator, set: setWCreator },
                  { key: "supporter", label: "❤️ A Supporter — I believe in this movement and want to help", val: wSupporter, set: setWSupporter },
                ].map(({ key, label, val, set }) => (
                  <label key={key} style={{ display: "flex", alignItems: "flex-start", gap: 12, cursor: "pointer", background: val ? "rgba(168,85,247,0.1)" : "rgba(255,255,255,0.02)", border: `1px solid ${val ? "rgba(168,85,247,0.4)" : "rgba(255,255,255,0.08)"}`, borderRadius: 12, padding: "14px 16px", transition: "all 0.15s" }}>
                    <input type="checkbox" checked={val} onChange={(e) => set(e.target.checked)} style={{ accentColor: "#a855f7", width: 16, height: 16, marginTop: 2, flexShrink: 0 }} />
                    <span style={{ fontSize: 14, color: "#94a3b8", lineHeight: 1.5 }}>{label}</span>
                  </label>
                ))}
              </div>

              {wError && <p style={{ fontSize: 13, color: "#f87171", margin: 0 }}>{wError}</p>}

              <button
                type="submit"
                disabled={wSubmitting || !wName || !wEmail}
                style={{ padding: "15px", borderRadius: 14, background: "linear-gradient(135deg,#a855f7,#7c3aed)", color: "#fff", fontWeight: 800, fontSize: 16, border: "none", cursor: "pointer", opacity: wSubmitting || !wName || !wEmail ? 0.6 : 1, boxShadow: "0 8px 30px rgba(168,85,247,0.35)", transition: "opacity 0.2s" }}>
                {wSubmitting ? "Reserving your spot…" : "Reserve Your Spot →"}
              </button>

              <p style={{ textAlign: "center", fontSize: 12, color: "#334155", margin: 0 }}>
                No spam, ever. We only send important Gran Boulva updates.
              </p>
            </form>
          )}
        </div>
      </section>

      {/* ── FAQ ──────────────────────────────────────────────────────────── */}
      <section id="faq" style={{ padding: "100px 32px" }}>
        <div style={{ maxWidth: 720, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 56 }}>
            <p style={{ color: "#a855f7", fontSize: 12, fontWeight: 700, letterSpacing: 3, textTransform: "uppercase", marginBottom: 12 }}>FAQ</p>
            <h2 style={{ fontSize: "clamp(26px, 3.5vw, 38px)", fontWeight: 900, color: "#fff", margin: 0, letterSpacing: "-0.8px" }}>
              Questions? We have answers.
            </h2>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {FAQ_ITEMS.map((item, i) => (
              <div key={i} style={{ background: "rgba(255,255,255,0.03)", border: `1px solid ${openFaq === i ? "rgba(168,85,247,0.4)" : "rgba(255,255,255,0.08)"}`, borderRadius: 16, overflow: "hidden", transition: "border-color 0.2s" }}>
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  style={{ width: "100%", display: "flex", justifyContent: "space-between", alignItems: "center", padding: "20px 24px", background: "none", border: "none", cursor: "pointer", textAlign: "left", gap: 16 }}>
                  <span style={{ fontSize: 15, fontWeight: 700, color: "#fff" }}>{item.q}</span>
                  <span style={{ color: "#a855f7", fontSize: 20, flexShrink: 0, transition: "transform 0.2s", transform: openFaq === i ? "rotate(45deg)" : "rotate(0deg)" }}>+</span>
                </button>
                {openFaq === i && (
                  <div style={{ padding: "0 24px 20px" }}>
                    <p style={{ fontSize: 14, color: "#64748b", margin: 0, lineHeight: 1.75 }}>{item.a}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── DOWNLOAD CTA (hidden) ────────────────────────────────────────── */}
      {/* <section style={{ padding: "120px 32px", position: "relative", overflow: "hidden", borderTop: "1px solid rgba(168,85,247,0.1)" }}>
        ...
      </section> */}

      {/* ── FOOTER ───────────────────────────────────────────────────────── */}
      <footer style={{ borderTop: "1px solid rgba(168,85,247,0.15)", padding: "60px 32px 32px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div className="footer-top" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 48, flexWrap: "wrap", gap: 40 }}>
            {/* Brand */}
            <div style={{ maxWidth: 280 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
                <Image src="/logo.png" alt="Gran Boulva" width={28} height={28} style={{ borderRadius: 6 }} />
                <span style={{ fontWeight: 800, fontSize: 16, color: "#fff" }}>Gran Boulva</span>
              </div>
              <p style={{ fontSize: 13, color: "#475569", lineHeight: 1.65, margin: "0 0 20px" }}>
                The digital home for Haitian creators, debates, and community influence.
              </p>
              {/* Social links */}
              <div style={{ display: "flex", gap: 12 }}>
                {[
                  { label: "X / Twitter", href: "https://twitter.com/granboulva", icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.259 5.63 5.905-5.63zm-1.161 17.52h1.833L7.084 4.126H5.117z" /></svg> },
                  { label: "Instagram", href: "https://instagram.com/granboulva", icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" /></svg> },
                  { label: "TikTok", href: "https://tiktok.com/@granboulva", icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1V9.01a6.27 6.27 0 00-.79-.05 6.34 6.34 0 00-6.34 6.34 6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.33-6.34V8.87a8.18 8.18 0 004.78 1.52V7.02a4.85 4.85 0 01-1.01-.33z" /></svg> },
                  { label: "Facebook", href: "https://facebook.com/granboulva", icon: <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" /></svg> },
                ].map(({ label, href, icon }) => (
                  <a key={label} href={href} target="_blank" rel="noopener noreferrer" aria-label={label}
                    style={{ width: 36, height: 36, borderRadius: "50%", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)", display: "flex", alignItems: "center", justifyContent: "center", color: "#64748b", textDecoration: "none", transition: "all 0.2s" }}
                    onMouseEnter={e => { (e.currentTarget as HTMLAnchorElement).style.color = "#a855f7"; (e.currentTarget as HTMLAnchorElement).style.borderColor = "rgba(168,85,247,0.4)"; }}
                    onMouseLeave={e => { (e.currentTarget as HTMLAnchorElement).style.color = "#64748b"; (e.currentTarget as HTMLAnchorElement).style.borderColor = "rgba(255,255,255,0.08)"; }}>
                    {icon}
                  </a>
                ))}
              </div>
            </div>

            {/* Links */}
            <div style={{ display: "flex", gap: 48, flexWrap: "wrap" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Platform</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  {[["Features", "#features"], ["Vision", "#vision"], ["Creators", "#creators"], ["Supporters", "#supporters"]].map(([l, h]) => (
                    <a key={h} href={h} style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>{l}</a>
                  ))}
                </div>
              </div>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Download</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  <a href="https://apps.apple.com/app/gran-boulva" target="_blank" rel="noopener noreferrer" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>App Store (iOS)</a>
                  <a href="#" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>Google Play (Soon)</a>
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
                <div style={{ fontSize: 11, fontWeight: 700, color: "#475569", letterSpacing: 1.5, textTransform: "uppercase", marginBottom: 16 }}>Contact</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  <a href="mailto:support@granboulva.com" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>support@granboulva.com</a>
                  <a href="mailto:creators@granboulva.com" style={{ fontSize: 13, color: "#64748b", textDecoration: "none" }}>creators@granboulva.com</a>
                </div>
              </div>
            </div>
          </div>

          <div style={{ borderTop: "1px solid rgba(255,255,255,0.05)", paddingTop: 24, display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
            <span style={{ fontSize: 12, color: "#1e2040" }}>© {new Date().getFullYear()} Gran Boulva. All rights reserved.</span>
            <span style={{ fontSize: 12, color: "#1e2040" }}>Sa se pou pèp Ayisyen an 🇭🇹</span>
          </div>
        </div>
      </footer>

      {/* ── Styles ───────────────────────────────────────────────────────── */}
      <style>{`
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        @keyframes slideBackPhone  { 0%{opacity:0;transform:rotate(5deg) translateX(-80px)}  100%{opacity:1;transform:rotate(5deg) translateX(0)} }
        @keyframes slideFrontPhone { 0%{opacity:0;transform:rotate(-3deg) translateX(-80px)} 100%{opacity:1;transform:rotate(-3deg) translateX(0)} }
        @keyframes phonefloat { 0%,100%{transform:rotate(-3deg) translateY(0)} 50%{transform:rotate(-3deg) translateY(-10px)} }
        .back-phone  { animation: slideBackPhone  0.7s ease-out 0.1s both; }
        .phone-front { animation: slideFrontPhone 0.7s ease-out 0.3s both; animation-fill-mode: forwards; }
        .phone-front { animation: slideFrontPhone 0.7s ease-out 0.3s both, phonefloat 3.5s ease-in-out 1.2s infinite; }
        a { transition: color 0.2s; }
        a:hover { color: #a855f7 !important; }

        @media (max-width: 900px) {
          .tiers-grid { grid-template-columns: repeat(2,1fr) !important; }
        }
        @media (max-width: 768px) {
          .nav-links { display: none !important; }
          .nav-cta { font-size: 11px !important; padding: 8px 14px !important; }
          .hero-inner { grid-template-columns: 1fr !important; gap: 40px !important; }
          .hero-text { text-align: center; }
          .hero-btns { justify-content: center !important; }
          .hero-phones { height: 360px !important; }
          .back-phone { display: none !important; }
          .phone-front { transform: rotate(0deg) !important; animation: phonefloat 3.5s ease-in-out 1.2s infinite !important; }
          .phone-front > div { width: 190px !important; height: 390px !important; }
          .social-proof { justify-content: center !important; }
          .vision-grid { grid-template-columns: 1fr !important; }
          .creator-grid { grid-template-columns: 1fr !important; gap: 40px !important; }
          .features-grid { grid-template-columns: 1fr 1fr !important; }
          .steps-row { flex-direction: column !important; align-items: center !important; gap: 8px !important; }
          .step-arrow { padding-bottom: 0 !important; transform: rotate(90deg); }
          .footer-top { flex-direction: column !important; }
          .tiers-grid { grid-template-columns: 1fr !important; }
        }
        @media (max-width: 480px) {
          .features-grid { grid-template-columns: 1fr !important; }
          .hero-phones { height: 300px !important; }
          .phone-front > div { width: 160px !important; height: 290px !important; }
          .tiers-grid { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </div>
  );
}
