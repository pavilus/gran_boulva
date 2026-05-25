"use client";

import { useState } from "react";
import { Download } from "lucide-react";

type Entry = {
  id: string;
  name: string;
  email: string;
  is_creator: boolean;
  is_supporter: boolean;
  tier: string | null;
  created_at: string;
};

const TIER_LABELS: Record<string, string> = {
  founding_partner: "👑 Founding Partner",
  early_supporter: "⭐ Early Supporter",
  community: "🌱 Community",
};

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-US", {
    month: "short", day: "numeric", year: "numeric", hour: "2-digit", minute: "2-digit",
  });
}

export default function WaitlistClient({ entries }: { entries: Entry[] }) {
  const [search, setSearch] = useState("");

  const filtered = entries.filter((e) =>
    e.name.toLowerCase().includes(search.toLowerCase()) ||
    e.email.toLowerCase().includes(search.toLowerCase())
  );

  const exportCSV = () => {
    const header = ["Name", "Email", "Creator", "Supporter", "Tier", "Date"];
    const rows = entries.map((e) => [
      e.name,
      e.email,
      e.is_creator ? "Yes" : "No",
      e.is_supporter ? "Yes" : "No",
      e.tier ?? "",
      fmt(e.created_at),
    ]);
    const csv = [header, ...rows].map((r) => r.map((c) => `"${c}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = "waitlist.csv"; a.click();
    URL.revokeObjectURL(url);
  };

  const cellStyle = { padding: "12px 16px", borderBottom: "1px solid #1a1b2e", fontSize: 13, color: "#D4D4D4" };
  const headStyle = { padding: "10px 16px", color: "#475569", fontSize: 11, fontWeight: 600, textTransform: "uppercase" as const, letterSpacing: "0.05em", borderBottom: "1px solid #1e2040" };

  return (
    <div>
      {/* ── Stats row ── */}
      <div className="flex gap-4 mb-5">
        {[
          { label: "Total signups", value: entries.length },
          { label: "Creators", value: entries.filter((e) => e.is_creator).length },
          { label: "Supporters", value: entries.filter((e) => e.is_supporter).length },
          { label: "Founding Partners", value: entries.filter((e) => e.tier === "founding_partner").length },
        ].map((s) => (
          <div key={s.label} style={{ background: "#0e0f1e", border: "1px solid #1e2040", borderRadius: 12, padding: "14px 20px", flex: 1 }}>
            <p style={{ color: "#64748b", fontSize: 11, marginBottom: 4 }}>{s.label}</p>
            <p style={{ color: "#fff", fontSize: 24, fontWeight: 800 }}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* ── Toolbar ── */}
      <div className="flex items-center gap-3 mb-4">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Chèche non oswa email…"
          style={{ flex: 1, background: "#0e0f1e", border: "1px solid #1e2040", borderRadius: 10, padding: "8px 14px", color: "#D4D4D4", fontSize: 13, outline: "none" }}
        />
        <button
          onClick={exportCSV}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold"
          style={{ background: "rgba(168,85,247,0.1)", color: "#a855f7", border: "1px solid rgba(168,85,247,0.25)" }}
        >
          <Download size={14} /> Ekspòte CSV
        </button>
      </div>

      {/* ── Table ── */}
      <div style={{ background: "#0e0f1e", border: "1px solid #1e2040", borderRadius: 14, overflow: "hidden" }}>
        {filtered.length === 0 ? (
          <p style={{ color: "#64748b", textAlign: "center", padding: 40, fontSize: 14 }}>
            {entries.length === 0 ? "Okenn moun poko enskri." : "Okenn rezilta pou rechèch sa."}
          </p>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ background: "#07080f" }}>
                <th style={headStyle} className="text-left">Non</th>
                <th style={headStyle} className="text-left">Email</th>
                <th style={headStyle} className="text-left">Wòl</th>
                <th style={headStyle} className="text-left">Tier</th>
                <th style={headStyle} className="text-left">Dat</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((e) => (
                <tr key={e.id} style={{ transition: "background 0.15s" }}
                  onMouseEnter={(el) => el.currentTarget.style.background = "#12131f"}
                  onMouseLeave={(el) => el.currentTarget.style.background = "transparent"}>
                  <td style={cellStyle}><span style={{ fontWeight: 600, color: "#fff" }}>{e.name}</span></td>
                  <td style={cellStyle}><a href={`mailto:${e.email}`} style={{ color: "#a855f7" }}>{e.email}</a></td>
                  <td style={cellStyle}>
                    <div className="flex gap-1 flex-wrap">
                      {e.is_creator && (
                        <span style={{ fontSize: 10, fontWeight: 700, padding: "2px 8px", borderRadius: 20, background: "rgba(168,85,247,0.12)", color: "#a855f7" }}>Kreyatè</span>
                      )}
                      {e.is_supporter && (
                        <span style={{ fontSize: 10, fontWeight: 700, padding: "2px 8px", borderRadius: 20, background: "rgba(34,197,94,0.1)", color: "#22c55e" }}>Sipòtè</span>
                      )}
                      {!e.is_creator && !e.is_supporter && (
                        <span style={{ fontSize: 10, color: "#475569" }}>—</span>
                      )}
                    </div>
                  </td>
                  <td style={cellStyle}>
                    {e.tier ? (
                      <span style={{ fontSize: 11, color: "#f59e0b" }}>{TIER_LABELS[e.tier] ?? e.tier}</span>
                    ) : (
                      <span style={{ color: "#475569" }}>—</span>
                    )}
                  </td>
                  <td style={{ ...cellStyle, color: "#64748b" }}>{fmt(e.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <p style={{ color: "#334155", fontSize: 11, marginTop: 10, textAlign: "right" }}>
        {filtered.length} / {entries.length} enskri
      </p>
    </div>
  );
}
