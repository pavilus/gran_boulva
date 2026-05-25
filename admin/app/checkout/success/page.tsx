"use client";
import { useState } from "react";
import { useSearchParams } from "next/navigation";
import Image from "next/image";
import Link from "next/link";

// ── Shared styles ─────────────────────────────────────────────────────────────
const PAGE_BG   = "#07080f";
const CARD_BG   = "rgba(255,255,255,0.03)";
const BORDER    = "rgba(168,85,247,0.2)";
const PURPLE    = "#a855f7";
const GOLD      = "#f59e0b";
const GREEN     = "#10b981";
const TEXT_MAIN = "#e2e8f0";
const TEXT_SUB  = "#64748b";
const FONT      = "'Poppins', system-ui, sans-serif";

const inputStyle: React.CSSProperties = {
  width: "100%", padding: "12px 14px", borderRadius: 10,
  background: "#0a0b18", border: `1px solid ${BORDER}`,
  color: TEXT_MAIN, fontSize: 14, outline: "none",
  boxSizing: "border-box", fontFamily: FONT,
};
const labelStyle: React.CSSProperties = {
  fontSize: 11, color: TEXT_SUB, fontWeight: 700,
  display: "block", marginBottom: 6,
  textTransform: "uppercase", letterSpacing: 0.5,
};
const sectionHead: React.CSSProperties = {
  fontSize: 11, color: PURPLE, fontWeight: 700,
  letterSpacing: 3, textTransform: "uppercase",
  margin: "0 0 16px", paddingBottom: 8,
  borderBottom: `1px solid rgba(168,85,247,0.15)`,
};

const INTEREST_OPTIONS = [
  { key: "partnership",            label: "Partnership" },
  { key: "creator_support",        label: "Creator Support" },
  { key: "investment_discussion",  label: "Investment Discussion" },
  { key: "advisory_opportunities", label: "Advisory Opportunities" },
];

const INVESTMENT_OPTIONS = [
  "Under $5,000",
  "$5,000 – $25,000",
  "$25,000 – $100,000",
  "$100,000+",
  "Open to discussion",
];

const TIER_LABELS: Record<string, { name: string; badge: string; color: string }> = {
  supporter:        { name: "Supporter",        badge: "🎖️", color: TEXT_SUB },
  ambassador:       { name: "Ambassador",       badge: "⭐", color: PURPLE },
  founding_creator: { name: "Founding Creator", badge: "🔥", color: GOLD },
  founding_partner: { name: "Founding Partner", badge: "👑", color: "#ec4899" },
};

// ── Generic success (non-partner tiers) ──────────────────────────────────────
function GenericSuccess({ tier }: { tier: string }) {
  const info = TIER_LABELS[tier];
  return (
    <div style={{ minHeight: "100vh", background: PAGE_BG, color: TEXT_MAIN, fontFamily: FONT, display: "flex", alignItems: "center", justifyContent: "center", padding: 32 }}>
      <div style={{ maxWidth: 520, width: "100%", textAlign: "center" }}>
        <div style={{ display: "flex", justifyContent: "center", marginBottom: 40 }}>
          <Image src="/logo.png" alt="Gran Boulva" width={56} height={56} style={{ borderRadius: 14 }} />
        </div>
        <div style={{ background: "rgba(16,185,129,0.06)", border: `1px solid rgba(16,185,129,0.3)`, borderRadius: 24, padding: "48px 40px", marginBottom: 32 }}>
          <div style={{ fontSize: 56, marginBottom: 20 }}>{info?.badge ?? "🎉"}</div>
          <h1 style={{ fontSize: 28, fontWeight: 900, color: "#fff", margin: "0 0 12px", letterSpacing: "-0.5px" }}>Mèsi anpil!</h1>
          {info && (
            <p style={{ fontSize: 16, color: "#94a3b8", lineHeight: 1.7, margin: "0 0 16px" }}>
              Ou vinn yon <span style={{ color: info.color, fontWeight: 800 }}>{info.name}</span> fondatè Gran Boulva.
            </p>
          )}
          <p style={{ fontSize: 14, color: TEXT_SUB, lineHeight: 1.7, margin: 0 }}>
            Yon imèl konfirmasyon pral rive byento.<br />
            Nou ap kontakte ou avan lanse ofisyèl la — Novanm 18, 2026.
          </p>
        </div>
        <Link href="/" style={{ display: "block", padding: "14px", borderRadius: 14, background: `linear-gradient(135deg,${PURPLE},#7c3aed)`, color: "#fff", fontWeight: 700, fontSize: 15, textDecoration: "none" }}>
          Retounen sou sit la
        </Link>
      </div>
    </div>
  );
}

// ── Partner Interest Form ─────────────────────────────────────────────────────
function PartnerForm({ sessionId, onSuccess }: { sessionId: string; onSuccess: () => void }) {
  const [form, setForm] = useState({
    name: "", email: "", phone_number: "", country: "", profession: "",
    business_background: "", linkedin_url: "", why_interested: "",
    strategic_skills: "", investment_range: "", industry_expertise: "", audience_size: "",
  });
  const [interests, setInterests]   = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError]           = useState("");

  function set(field: string) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
      setForm(f => ({ ...f, [field]: e.target.value }));
  }

  function toggleInterest(key: string) {
    setInterests(prev => prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const res  = await fetch("/api/partner-application", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...form, interests, stripe_session_id: sessionId }),
      });
      const data = await res.json() as { ok?: boolean; error?: string };
      if (!res.ok && !data.ok) throw new Error(data.error ?? "Something went wrong");
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  const focusBorder = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    (e.target.style.borderColor = "rgba(168,85,247,0.6)");
  const blurBorder  = (e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    (e.target.style.borderColor = BORDER);

  return (
    <div style={{ background: PAGE_BG, color: TEXT_MAIN, fontFamily: FONT, minHeight: "100vh", padding: "60px 24px 80px" }}>
      <div style={{ maxWidth: 680, margin: "0 auto" }}>

        {/* Header */}
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <div style={{ display: "flex", justifyContent: "center", marginBottom: 24 }}>
            <Image src="/logo.png" alt="Gran Boulva" width={48} height={48} style={{ borderRadius: 12 }} />
          </div>

          {/* Payment confirmed pill */}
          <div style={{ display: "inline-flex", alignItems: "center", gap: 8, background: "rgba(16,185,129,0.08)", border: "1px solid rgba(16,185,129,0.25)", borderRadius: 99, padding: "6px 16px", marginBottom: 24 }}>
            <span style={{ width: 7, height: 7, borderRadius: "50%", background: GREEN, display: "inline-block" }} />
            <span style={{ fontSize: 12, color: GREEN, fontWeight: 700 }}>👑 Founding Partner — Payment Confirmed</span>
          </div>

          <h1 style={{ fontSize: "clamp(26px, 4vw, 38px)", fontWeight: 900, color: "#fff", margin: "0 0 12px", letterSpacing: "-0.8px" }}>
            Partner Interest Form
          </h1>
          <p style={{ fontSize: 15, color: "#94a3b8", lineHeight: 1.7, maxWidth: 520, margin: "0 auto" }}>
            Thank you for your investment in Gran Boulva. Please take a few minutes to tell us about yourself — this helps us align on the right partnership opportunities.
          </p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: "flex", flexDirection: "column", gap: 32 }}>

          {/* ── Personal Info ──────────────────────────────────── */}
          <div style={{ background: CARD_BG, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "28px 28px 24px" }}>
            <p style={sectionHead}>Personal Information</p>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              <div>
                <label style={labelStyle}>Full Name *</label>
                <input required value={form.name} onChange={set("name")} placeholder="Jean Pierre"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div>
                <label style={labelStyle}>Email *</label>
                <input required type="email" value={form.email} onChange={set("email")} placeholder="jean@example.com"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div>
                <label style={labelStyle}>Phone Number</label>
                <input value={form.phone_number} onChange={set("phone_number")} placeholder="+1 (509) 000-0000"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div>
                <label style={labelStyle}>Country</label>
                <input value={form.country} onChange={set("country")} placeholder="Haiti, USA, Canada…"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div style={{ gridColumn: "1 / -1" }}>
                <label style={labelStyle}>Profession / Title</label>
                <input value={form.profession} onChange={set("profession")} placeholder="Entrepreneur, Investor, Content Creator…"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
            </div>
          </div>

          {/* ── Background ────────────────────────────────────── */}
          <div style={{ background: CARD_BG, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "28px 28px 24px" }}>
            <p style={sectionHead}>Background & Online Presence</p>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <div>
                <label style={labelStyle}>Business Background</label>
                <textarea rows={3} value={form.business_background} onChange={set("business_background")}
                  placeholder="Brief overview of your professional or business background…"
                  style={{ ...inputStyle, resize: "vertical", lineHeight: 1.6 }}
                  onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div>
                <label style={labelStyle}>LinkedIn / Social Media / Business Links</label>
                <input value={form.linkedin_url} onChange={set("linkedin_url")}
                  placeholder="https://linkedin.com/in/yourprofile"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
            </div>
          </div>

          {/* ── Motivation ────────────────────────────────────── */}
          <div style={{ background: CARD_BG, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "28px 28px 24px" }}>
            <p style={sectionHead}>Your Interest in Gran Boulva</p>
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <div>
                <label style={labelStyle}>Why are you interested in Gran Boulva? *</label>
                <textarea required rows={4} value={form.why_interested} onChange={set("why_interested")}
                  placeholder="What draws you to Gran Boulva? What opportunity do you see?"
                  style={{ ...inputStyle, resize: "vertical", lineHeight: 1.6 }}
                  onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div>
                <label style={labelStyle}>Strategic Skills / Resources You Bring</label>
                <textarea rows={3} value={form.strategic_skills} onChange={set("strategic_skills")}
                  placeholder="Distribution network, media presence, technical skills, capital, etc."
                  style={{ ...inputStyle, resize: "vertical", lineHeight: 1.6 }}
                  onFocus={focusBorder} onBlur={blurBorder} />
              </div>
            </div>
          </div>

          {/* ── Interests (checkboxes) ────────────────────────── */}
          <div style={{ background: CARD_BG, border: `1px solid ${BORDER}`, borderRadius: 20, padding: "28px 28px 24px" }}>
            <p style={sectionHead}>Interested In *</p>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              {INTEREST_OPTIONS.map(({ key, label }) => {
                const checked = interests.includes(key);
                return (
                  <label key={key} style={{ display: "flex", alignItems: "center", gap: 12, cursor: "pointer", background: checked ? "rgba(168,85,247,0.1)" : "rgba(255,255,255,0.02)", border: `1px solid ${checked ? "rgba(168,85,247,0.4)" : "rgba(255,255,255,0.08)"}`, borderRadius: 12, padding: "14px 16px", transition: "all 0.15s" }}>
                    <input type="checkbox" checked={checked} onChange={() => toggleInterest(key)}
                      style={{ accentColor: PURPLE, width: 16, height: 16, flexShrink: 0 }} />
                    <span style={{ fontSize: 14, color: checked ? TEXT_MAIN : "#94a3b8", fontWeight: checked ? 600 : 400 }}>{label}</span>
                  </label>
                );
              })}
            </div>
          </div>

          {/* ── Optional ──────────────────────────────────────── */}
          <div style={{ background: CARD_BG, border: `1px solid rgba(255,255,255,0.06)`, borderRadius: 20, padding: "28px 28px 24px" }}>
            <p style={{ ...sectionHead, color: TEXT_SUB, borderBottomColor: "rgba(255,255,255,0.06)" }}>
              Optional Details
            </p>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              <div>
                <label style={labelStyle}>Investment Range</label>
                <select value={form.investment_range} onChange={set("investment_range")}
                  style={{ ...inputStyle, cursor: "pointer" }} onFocus={focusBorder} onBlur={blurBorder}>
                  <option value="">Select a range…</option>
                  {INVESTMENT_OPTIONS.map(o => <option key={o} value={o}>{o}</option>)}
                </select>
              </div>
              <div>
                <label style={labelStyle}>Industry Expertise</label>
                <input value={form.industry_expertise} onChange={set("industry_expertise")}
                  placeholder="Media, Finance, Tech, Entertainment…"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
              <div style={{ gridColumn: "1 / -1" }}>
                <label style={labelStyle}>Audience / Community Size</label>
                <input value={form.audience_size} onChange={set("audience_size")}
                  placeholder="e.g. 50K Instagram followers, 10K newsletter subscribers…"
                  style={inputStyle} onFocus={focusBorder} onBlur={blurBorder} />
              </div>
            </div>
          </div>

          {/* ── Submit ────────────────────────────────────────── */}
          {error && (
            <p style={{ fontSize: 13, color: "#f87171", margin: 0, textAlign: "center" }}>{error}</p>
          )}
          <button type="submit" disabled={submitting || !interests.length}
            style={{ padding: "16px", borderRadius: 14, background: `linear-gradient(135deg,#ec4899,${PURPLE})`, color: "#fff", fontWeight: 800, fontSize: 16, border: "none", cursor: submitting || !interests.length ? "not-allowed" : "pointer", opacity: submitting || !interests.length ? 0.6 : 1, boxShadow: "0 8px 30px rgba(236,72,153,0.35)", transition: "opacity 0.2s" }}>
            {submitting ? "Submitting…" : "Submit Partner Interest Form →"}
          </button>
          <p style={{ textAlign: "center", fontSize: 12, color: "#334155", margin: "-16px 0 0" }}>
            Your information is kept strictly confidential and will only be used to evaluate partnership opportunities.
          </p>
        </form>
      </div>

      {/* Mobile grid fix */}
      <style>{`
        @media (max-width: 600px) {
          .partner-grid-2 { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </div>
  );
}

// ── Thank-you screen (after partner form submit) ──────────────────────────────
function PartnerThankYou() {
  return (
    <div style={{ minHeight: "100vh", background: PAGE_BG, color: TEXT_MAIN, fontFamily: FONT, display: "flex", alignItems: "center", justifyContent: "center", padding: 32 }}>
      <div style={{ maxWidth: 520, width: "100%", textAlign: "center" }}>
        <div style={{ display: "flex", justifyContent: "center", marginBottom: 40 }}>
          <Image src="/logo.png" alt="Gran Boulva" width={56} height={56} style={{ borderRadius: 14 }} />
        </div>
        <div style={{ background: "rgba(16,185,129,0.06)", border: "1px solid rgba(16,185,129,0.3)", borderRadius: 24, padding: "48px 40px", marginBottom: 32 }}>
          <div style={{ fontSize: 56, marginBottom: 20 }}>👑</div>
          <h1 style={{ fontSize: 28, fontWeight: 900, color: "#fff", margin: "0 0 16px", letterSpacing: "-0.5px" }}>
            Application Received!
          </h1>
          <p style={{ fontSize: 16, color: "#94a3b8", lineHeight: 1.75, margin: "0 0 16px" }}>
            Thank you for completing your <span style={{ color: "#ec4899", fontWeight: 800 }}>Founding Partner</span> application.
          </p>
          <p style={{ fontSize: 14, color: TEXT_SUB, lineHeight: 1.7, margin: 0 }}>
            Our team will review your information and reach out personally before the November 18, 2026 launch.
            We look forward to building something meaningful together.
          </p>
        </div>
        <Link href="/" style={{ display: "block", padding: "14px", borderRadius: 14, background: `linear-gradient(135deg,${PURPLE},#7c3aed)`, color: "#fff", fontWeight: 700, fontSize: 15, textDecoration: "none" }}>
          Return to Gran Boulva
        </Link>
      </div>
    </div>
  );
}

// ── Page entry point ──────────────────────────────────────────────────────────
export default function CheckoutSuccess() {
  const params    = useSearchParams();
  const tier      = params.get("tier") ?? "";
  const sessionId = params.get("session_id") ?? "";

  const [partnerDone, setPartnerDone] = useState(false);

  if (tier === "founding_partner") {
    if (partnerDone) return <PartnerThankYou />;
    return <PartnerForm sessionId={sessionId} onSuccess={() => setPartnerDone(true)} />;
  }

  return <GenericSuccess tier={tier} />;
}
