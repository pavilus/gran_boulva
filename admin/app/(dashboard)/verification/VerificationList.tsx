"use client";

import { useState } from "react";
import { CheckCircle, XCircle, Eye, Clock } from "lucide-react";

type Request = {
  id: string;
  user_id: string;
  verification_type: string;
  status: string;
  display_name?: string;
  legal_name?: string;
  organization_name?: string;
  website?: string;
  organization_email?: string;
  social_links?: string;
  proof_notes?: string;
  admin_notes?: string;
  rejection_reason?: string;
  submitted_at: string;
  reviewed_at?: string;
  user?: { username: string; avatar_url?: string; verification_status: string };
};

const TABS = ["pending", "under_review", "approved", "rejected"] as const;
const TAB_LABELS: Record<string, string> = {
  pending: "An Atant",
  under_review: "An Revizyon",
  approved: "Apwouve",
  rejected: "Rejte",
};
const STATUS_COLORS: Record<string, string> = {
  pending: "#f59e0b",
  under_review: "#60a5fa",
  approved: "#22c55e",
  rejected: "#ef4444",
  revoked: "#94a3b8",
};
const TYPE_LABELS: Record<string, string> = {
  standard: "Verifye",
  public_figure: "Pèsonalite piblik",
  organization: "Òganizasyon",
  trusted_creator: "Kreyatè serye",
  admin: "Ekip",
};
const BADGE_IMGS: Record<string, string> = {
  standard: "/categories/star.png",
  public_figure: "/categories/star.png",
  organization: "/categories/star.png",
  trusted_creator: "/categories/star.png",
};

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString("fr-HT", {
    month: "short", day: "numeric", year: "numeric", hour: "2-digit", minute: "2-digit",
  });
}

async function callApi(body: object) {
  const res = await fetch("/api/verification/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return res.json();
}

export default function VerificationList({ requests: initial }: { requests: Request[] }) {
  const [requests, setRequests] = useState(initial);
  const [activeTab, setActiveTab] = useState<typeof TABS[number]>("pending");
  const [loading, setLoading] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [adminNotes, setAdminNotes] = useState<Record<string, string>>({});
  const [rejectionReason, setRejectionReason] = useState<Record<string, string>>({});

  const filtered = requests.filter((r) => r.status === activeTab);

  const counts: Record<string, number> = {};
  for (const t of TABS) counts[t] = requests.filter((r) => r.status === t).length;

  const act = async (req: Request, action: "approve" | "reject" | "under_review") => {
    setLoading(`${req.id}-${action}`);
    await callApi({
      action,
      requestId: req.id,
      userId: req.user_id,
      verificationType: req.verification_type,
      adminNotes: adminNotes[req.id] ?? null,
      rejectionReason: rejectionReason[req.id] ?? null,
    });
    const newStatus = action === "approve" ? "approved" : action === "reject" ? "rejected" : "under_review";
    setRequests((prev) => prev.map((r) => r.id === req.id ? { ...r, status: newStatus } : r));
    setExpanded(null);
    setLoading(null);
  };

  const inputStyle = { background: "#0a0b18", border: "1px solid #2e3060", color: "#D4D4D4" };

  return (
    <div className="space-y-4">
      {/* Tabs */}
      <div className="flex gap-2 flex-wrap">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setActiveTab(t)}
            className="px-4 py-2 rounded-lg text-xs font-semibold transition-all"
            style={{
              background: activeTab === t ? "linear-gradient(90deg,#7c3aed,#a855f7)" : "#0e0f1e",
              color: activeTab === t ? "white" : "#64748b",
              border: activeTab === t ? "none" : "1px solid #2e3060",
            }}
          >
            {TAB_LABELS[t]}
            {counts[t] > 0 && (
              <span
                className="ml-2 px-1.5 py-0.5 rounded-full text-xs"
                style={{ background: activeTab === t ? "rgba(255,255,255,0.2)" : "#1e2040", color: activeTab === t ? "white" : "#94a3b8" }}
              >
                {counts[t]}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Empty state */}
      {filtered.length === 0 && (
        <div className="text-center py-16" style={{ color: "#94a3b8" }}>
          <CheckCircle size={40} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">Pa gen demann {TAB_LABELS[activeTab].toLowerCase()}</p>
        </div>
      )}

      {/* Request cards */}
      <div className="space-y-3">
        {filtered.map((req) => {
          const isExpanded = expanded === req.id;
          const isLoading = (action: string) => loading === `${req.id}-${action}`;

          return (
            <div
              key={req.id}
              className="rounded-xl overflow-hidden"
              style={{ border: "1px solid #2e3060", background: "#0e0f1e" }}
            >
              {/* Card header */}
              <div className="flex items-center gap-3 px-4 py-3">
                {/* Avatar */}
                <div
                  style={{
                    width: 40, height: 40, borderRadius: "50%", flexShrink: 0,
                    background: "linear-gradient(135deg,#7c3aed,#ec4899)",
                    display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden",
                  }}
                >
                  {req.user?.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={req.user.avatar_url} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                  ) : (
                    <span style={{ color: "#D4D4D4", fontWeight: "bold", fontSize: 14 }}>
                      {req.user?.username?.[0]?.toUpperCase() ?? "?"}
                    </span>
                  )}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span style={{ color: "#D4D4D4", fontWeight: 700, fontSize: 14 }}>
                      @{req.user?.username ?? "—"}
                    </span>
                    <span
                      className="px-2 py-0.5 rounded-full text-xs font-semibold"
                      style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa", border: "1px solid rgba(124,58,237,0.3)" }}
                    >
                      {TYPE_LABELS[req.verification_type] ?? req.verification_type}
                    </span>
                    <span
                      className="px-2 py-0.5 rounded-full text-xs font-semibold"
                      style={{ background: `${STATUS_COLORS[req.status]}20`, color: STATUS_COLORS[req.status] }}
                    >
                      {TAB_LABELS[req.status] ?? req.status}
                    </span>
                  </div>
                  <div style={{ color: "#94a3b8", fontSize: 12, marginTop: 2 }}>
                    {req.display_name && <span>{req.display_name} · </span>}
                    Soumèt {fmtDate(req.submitted_at)}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    onClick={() => setExpanded(isExpanded ? null : req.id)}
                    className="p-1.5 rounded-lg transition-colors"
                    style={{ color: "#94a3b8", background: "rgba(148,163,184,0.08)" }}
                    title="Detay"
                  >
                    <Eye size={15} />
                  </button>
                  {req.status === "pending" && (
                    <button
                      onClick={() => act(req, "under_review")}
                      disabled={!!loading}
                      className="p-1.5 rounded-lg transition-colors"
                      style={{ color: "#60a5fa", background: "rgba(96,165,250,0.08)" }}
                      title="Mete an revizyon"
                    >
                      <Clock size={15} />
                    </button>
                  )}
                  {(req.status === "pending" || req.status === "under_review") && (
                    <>
                      <button
                        onClick={() => act(req, "approve")}
                        disabled={!!loading}
                        className="p-1.5 rounded-lg transition-colors"
                        style={{ color: "#22c55e", background: "rgba(34,197,94,0.08)" }}
                        title="Apwouve"
                      >
                        {isLoading("approve") ? (
                          <span style={{ fontSize: 10 }}>...</span>
                        ) : (
                          <CheckCircle size={15} />
                        )}
                      </button>
                      <button
                        onClick={() => act(req, "reject")}
                        disabled={!!loading}
                        className="p-1.5 rounded-lg transition-colors"
                        style={{ color: "#ef4444", background: "rgba(239,68,68,0.08)" }}
                        title="Rejte"
                      >
                        {isLoading("reject") ? (
                          <span style={{ fontSize: 10 }}>...</span>
                        ) : (
                          <XCircle size={15} />
                        )}
                      </button>
                    </>
                  )}
                </div>
              </div>

              {/* Expanded detail */}
              {isExpanded && (
                <div className="px-4 pb-4 space-y-3" style={{ borderTop: "1px solid #1a1b2e" }}>
                  <div className="grid grid-cols-1 gap-2 pt-3" style={{ color: "#94a3b8", fontSize: 13 }}>
                    {req.legal_name && (
                      <div><span style={{ color: "#94a3b8" }}>Non legal: </span>{req.legal_name}</div>
                    )}
                    {req.organization_name && (
                      <div><span style={{ color: "#94a3b8" }}>Òganizasyon: </span>{req.organization_name}</div>
                    )}
                    {req.organization_email && (
                      <div><span style={{ color: "#94a3b8" }}>Imèl òg: </span>{req.organization_email}</div>
                    )}
                    {req.website && (
                      <div>
                        <span style={{ color: "#94a3b8" }}>Sit: </span>
                        <a href={req.website} target="_blank" rel="noopener noreferrer" style={{ color: "#a78bfa" }}>{req.website}</a>
                      </div>
                    )}
                    {req.social_links && (
                      <div><span style={{ color: "#94a3b8" }}>Rezo sosyal: </span>{req.social_links}</div>
                    )}
                    {req.proof_notes && (
                      <div>
                        <span style={{ color: "#94a3b8" }}>Prèv / nòt: </span>
                        <span style={{ whiteSpace: "pre-wrap" }}>{req.proof_notes}</span>
                      </div>
                    )}
                    {req.rejection_reason && (
                      <div style={{ color: "#ef4444" }}>
                        <span style={{ color: "#94a3b8" }}>Rezon refi: </span>{req.rejection_reason}
                      </div>
                    )}
                    {req.admin_notes && (
                      <div><span style={{ color: "#94a3b8" }}>Nòt admin: </span>{req.admin_notes}</div>
                    )}
                  </div>

                  {(req.status === "pending" || req.status === "under_review") && (
                    <div className="space-y-2 pt-1">
                      <textarea
                        rows={2}
                        placeholder="Nòt admin (opsyonèl)"
                        value={adminNotes[req.id] ?? ""}
                        onChange={(e) => setAdminNotes((p) => ({ ...p, [req.id]: e.target.value }))}
                        className="w-full px-3 py-2 rounded-lg text-xs outline-none resize-none"
                        style={inputStyle}
                      />
                      <textarea
                        rows={2}
                        placeholder="Rezon refi (si w ap rejte)"
                        value={rejectionReason[req.id] ?? ""}
                        onChange={(e) => setRejectionReason((p) => ({ ...p, [req.id]: e.target.value }))}
                        className="w-full px-3 py-2 rounded-lg text-xs outline-none resize-none"
                        style={{ ...inputStyle, borderColor: "#3f1a1a" }}
                      />
                      <div className="flex gap-2">
                        <button
                          onClick={() => act(req, "approve")}
                          disabled={!!loading}
                          className="flex-1 py-2 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5"
                          style={{ background: "rgba(34,197,94,0.12)", color: "#22c55e", border: "1px solid rgba(34,197,94,0.25)" }}
                        >
                          <CheckCircle size={13} /> Apwouve
                        </button>
                        <button
                          onClick={() => act(req, "reject")}
                          disabled={!!loading}
                          className="flex-1 py-2 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5"
                          style={{ background: "rgba(239,68,68,0.08)", color: "#ef4444", border: "1px solid rgba(239,68,68,0.2)" }}
                        >
                          <XCircle size={13} /> Rejte
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
