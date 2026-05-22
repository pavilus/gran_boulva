import Link from "next/link";

interface Section {
  title: string;
  content: string | string[];
}

interface Props {
  title: string;
  subtitle?: string;
  effectiveDate: string;
  sections: Section[];
}

export default function LegalPage({ title, subtitle, effectiveDate, sections }: Props) {
  return (
    <div style={{ minHeight: "100vh", background: "#0a0a0f", color: "#e2e8f0", fontFamily: "system-ui, sans-serif" }}>
      {/* Header */}
      <div style={{ background: "#0e0f1e", borderBottom: "1px solid #1e2040", padding: "16px 24px", display: "flex", alignItems: "center" }}>
        <span style={{ color: "#64748b", fontSize: 13 }}>granboulva.com</span>
      </div>

      <div style={{ maxWidth: 760, margin: "0 auto", padding: "48px 24px 80px" }}>
        {/* Title */}
        <div style={{ marginBottom: 40 }}>
          <h1 style={{ fontSize: 32, fontWeight: 800, color: "#D4D4D4", margin: "0 0 8px" }}>{title}</h1>
          {subtitle && <p style={{ color: "#94a3b8", fontSize: 15, margin: "0 0 12px" }}>{subtitle}</p>}
          <p style={{ color: "#475569", fontSize: 13, margin: 0 }}>Dènye mizajou / Last updated: {effectiveDate}</p>
        </div>

        {/* Sections */}
        <div style={{ display: "flex", flexDirection: "column", gap: 36 }}>
          {sections.map((section, i) => (
            <div key={i}>
              <h2 style={{ fontSize: 17, fontWeight: 700, color: "#c4b5fd", margin: "0 0 12px", paddingBottom: 8, borderBottom: "1px solid #1e2040" }}>
                {i + 1}. {section.title}
              </h2>
              {Array.isArray(section.content) ? (
                <ul style={{ margin: 0, paddingLeft: 20, display: "flex", flexDirection: "column", gap: 6 }}>
                  {section.content.map((item, j) => (
                    <li key={j} style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.7 }}>{item}</li>
                  ))}
                </ul>
              ) : (
                <p style={{ color: "#94a3b8", fontSize: 14, lineHeight: 1.8, margin: 0, whiteSpace: "pre-line" }}>{section.content}</p>
              )}
            </div>
          ))}
        </div>

        {/* Footer */}
        <div style={{ marginTop: 64, paddingTop: 24, borderTop: "1px solid #1e2040", display: "flex", flexWrap: "wrap", gap: 16 }}>
          {[
            { label: "Privacy Policy", href: "/privacy" },
            { label: "Terms of Service", href: "/terms" },
            { label: "Acceptable Use", href: "/aup" },
            { label: "DMCA", href: "/dmca" },
            { label: "Cookies", href: "/cookies" },
            { label: "Disclaimer", href: "/disclaimer" },
          ].map((link) => (
            <Link key={link.href} href={link.href} style={{ color: "#475569", fontSize: 13, textDecoration: "none" }}>
              {link.label}
            </Link>
          ))}
        </div>
        <p style={{ color: "#1e2040", fontSize: 12, marginTop: 16 }}>© {new Date().getFullYear()} Gran Boulva. All rights reserved.</p>
      </div>
    </div>
  );
}
