"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Bot, RefreshCw, Check, X, Loader2 } from "lucide-react";

type ScoutDraft = {
  id: string;
  title_ht: string;
  category: { name_ht: string } | { name_ht: string }[] | null;
  combined_score: number | null;
  risk_level: string | null;
  status: string;
};

const riskColor: Record<string, string> = {
  low: "#10b981",
  medium: "#f59e0b",
  high: "#ef4444",
};

export default function ScoutPanel({ drafts: initialDrafts }: { drafts: ScoutDraft[] }) {
  const router = useRouter();
  const [running, startRunning] = useTransition();
  const [acting, setActing] = useState<string | null>(null);
  const [drafts, setDrafts] = useState(initialDrafts);
  const [error, setError] = useState<string | null>(null);

  async function runScout() {
    setError(null);
    startRunning(async () => {
      const res = await fetch("/api/scout/run", { method: "POST" });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "Scout failed");
      } else {
        router.refresh();
      }
    });
  }

  async function doAction(draftId: string, action: "approve" | "reject") {
    setActing(draftId);
    setError(null);
    const res = await fetch("/api/scout/action", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ draft_id: draftId, action }),
    });
    const data = await res.json();
    setActing(null);
    if (!res.ok) {
      setError(data.error ?? "Action failed");
    } else {
      setDrafts((prev) => prev.filter((d) => d.id !== draftId));
    }
  }

  return (
    <div
      className="rounded-xl p-5 flex flex-col"
      style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div
            className="flex items-center justify-center rounded-lg"
            style={{ width: 28, height: 28, background: "rgba(124,58,237,0.2)" }}
          >
            <Bot size={14} color="#a78bfa" />
          </div>
          <div>
            <div className="text-white font-semibold text-sm">AI Boulva Scout</div>
            <div style={{ color: "#94a3b8", fontSize: 10 }}>Sijèsyon ki pi bon yo</div>
          </div>
        </div>
        <button
          onClick={runScout}
          disabled={running}
          className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg font-medium disabled:opacity-60"
          style={{ background: "linear-gradient(90deg,#7c3aed,#a855f7)", color: "white" }}
        >
          {running ? <Loader2 size={11} className="animate-spin" /> : <RefreshCw size={11} />}
          {running ? "Running…" : "Run Scout"}
        </button>
      </div>

      {error && (
        <div
          className="text-xs px-3 py-2 rounded-lg mb-3"
          style={{ background: "rgba(239,68,68,0.1)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.2)" }}
        >
          {error}
        </div>
      )}

      {/* List */}
      <div className="space-y-2 flex-1">
        {drafts.length === 0 && (
          <div className="text-center py-6" style={{ color: "#94a3b8", fontSize: 12 }}>
            Pa gen sijèsyon — klike Run Scout
          </div>
        )}
        {drafts.map((d) => {
          const risk = d.risk_level ?? "low";
          const isActing = acting === d.id;
          return (
            <div
              key={d.id}
              className="flex items-center gap-3 p-3 rounded-lg"
              style={{ background: "#13152a", border: "1px solid #1e2040" }}
            >
              <div className="flex-1 min-w-0">
                <div className="text-white text-xs font-medium leading-tight truncate">
                  {d.title_ht}
                </div>
                <div className="flex items-center gap-2 mt-1">
                  <span style={{ color: "#94a3b8", fontSize: 10 }}>
                  {(Array.isArray(d.category) ? d.category[0]?.name_ht : d.category?.name_ht) ?? "—"}
                </span>
                  <span className="text-xs font-bold" style={{ color: riskColor[risk] ?? "#94a3b8" }}>●</span>
                  <span style={{ fontSize: 10, color: riskColor[risk] ?? "#94a3b8" }}>{risk}</span>
                </div>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <span className="text-xs font-bold" style={{ color: "#a78bfa", minWidth: 28, textAlign: "right" }}>
                  {d.combined_score?.toFixed(1) ?? "—"}
                </span>
                {isActing ? (
                  <Loader2 size={14} color="#64748b" className="animate-spin" />
                ) : (
                  <>
                    <button
                      onClick={() => doAction(d.id, "approve")}
                      className="flex items-center justify-center rounded-md"
                      style={{ width: 24, height: 24, background: "rgba(16,185,129,0.15)", color: "#10b981" }}
                      title="Apwouve"
                    >
                      <Check size={12} />
                    </button>
                    <button
                      onClick={() => doAction(d.id, "reject")}
                      className="flex items-center justify-center rounded-md"
                      style={{ width: 24, height: 24, background: "rgba(239,68,68,0.12)", color: "#ef4444" }}
                      title="Rejte"
                    >
                      <X size={12} />
                    </button>
                  </>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <Link
        href="/scout"
        className="mt-3 block w-full text-xs py-2 rounded-lg font-medium text-center"
        style={{
          background: "rgba(124,58,237,0.1)",
          border: "1px solid rgba(124,58,237,0.25)",
          color: "#a78bfa",
        }}
      >
        Wè tout sijèsyon yo →
      </Link>
    </div>
  );
}
