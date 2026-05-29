import Link from "next/link";
import { Flag, ChevronRight } from "lucide-react";

type Report = {
  id: string;
  content_type: string | null;
  reported_type?: string | null;
  reason: string | null;
  reporter: { username: string }[] | { username: string } | null;
  created_at: string;
};

const URGENT_REASONS = ["diskriminasyon", "danjere", "agresyon", "abi", "vèbal"];

export default function ReportsPanel({ reports }: { reports: Report[] }) {
  return (
    <div
      className="rounded-xl p-5"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div
            className="flex items-center justify-center rounded-lg"
            style={{ width: 26, height: 26, background: "rgba(239,68,68,0.15)" }}
          >
            <Flag size={13} color="#ef4444" />
          </div>
          <div className="text-white font-semibold text-sm">Rapò ki bèswen atansyon</div>
        </div>
        <Link href="/reports" style={{ color: "#a78bfa", fontSize: 11, textDecoration: "none" }}>Wè tout →</Link>
      </div>

      <div className="space-y-2">
        {reports.length === 0 && (
          <div className="text-center py-6" style={{ color: "#475569", fontSize: 12 }}>
            Pa gen rapò pou kounye a
          </div>
        )}
        {reports.map((r) => {
          const urgent = URGENT_REASONS.some((w) =>
            r.reason?.toLowerCase().includes(w)
          );
          return (
          <Link
            key={r.id}
            href="/reports"
            className="flex items-center gap-3 p-3 rounded-lg group"
            style={{ background: "#13152a", textDecoration: "none", display: "flex" }}
          >
            <div
              className="rounded-md flex items-center justify-center shrink-0"
              style={{
                width: 32,
                height: 32,
                background: urgent ? "rgba(239,68,68,0.15)" : "rgba(124,58,237,0.12)",
              }}
            >
              <Flag size={13} color={urgent ? "#ef4444" : "#a78bfa"} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <span
                  className="text-xs px-1.5 py-0.5 rounded font-medium"
                  style={{
                    background: "rgba(124,58,237,0.12)",
                    color: "#a78bfa",
                    fontSize: 10,
                  }}
                >
                  {r.reported_type ?? r.content_type ?? "—"}
                </span>
                {urgent && (
                  <span
                    className="text-xs px-1.5 py-0.5 rounded font-medium"
                    style={{
                      background: "rgba(239,68,68,0.12)",
                      color: "#ef4444",
                      fontSize: 9,
                    }}
                  >
                    IJAN
                  </span>
                )}
              </div>
              <div style={{ color: "#94a3b8", fontSize: 11, marginTop: 2 }}>
                {(() => {
                  const u = Array.isArray(r.reporter) ? r.reporter[0] : r.reporter;
                  return u?.username ? `@${u.username}` : "—";
                })()} · {r.reason ?? "—"}
              </div>
            </div>
            <ChevronRight size={13} color="#334155" className="group-hover:text-purple-400 shrink-0" />
          </Link>
          );
        })}
      </div>
    </div>
  );
}
