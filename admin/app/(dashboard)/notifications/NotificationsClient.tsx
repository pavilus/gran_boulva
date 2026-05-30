"use client";

import { useState } from "react";
import { Send, Bell } from "lucide-react";

type NotifRow = { id: string; type: string; title: string; body?: string; created_at: string; is_read: boolean };

const NOTIF_TYPES = ["announcement", "matchup", "prediction", "reward", "system"];

function fmtDate(d: string) {
  return new Date(d).toLocaleString("fr-HT", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

export default function NotificationsClient({ recent, userCount }: { recent: NotifRow[]; userCount: number }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [type, setType] = useState("announcement");
  const [sendEmail, setSendEmail] = useState(false);
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const [rows, setRows] = useState(recent);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    type: "",
    title: "",
    body: "",
    date: "",
  });

  const filteredRows = rows.filter((n) => {
    if (filters.type && !n.type.toLowerCase().includes(filters.type.toLowerCase())) return false;
    if (filters.title && !n.title.toLowerCase().includes(filters.title.toLowerCase())) return false;
    if (filters.body && !(n.body ?? "").toLowerCase().includes(filters.body.toLowerCase())) return false;
    if (filters.date && !fmtDate(n.created_at).toLowerCase().includes(filters.date.toLowerCase())) return false;
    return true;
  });

  const send = async () => {
    if (!title.trim()) return;
    setSending(true);
    setError(null);
    setResult(null);
    try {
      const res = await fetch("/api/notifications/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title: title.trim(), body: body.trim(), type, sendEmail }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Erè");
      setSent(true);
      setResult(`${data.count ?? 0} notifikasyon voye.${data.email ? ` Email: ${data.email.error ?? `${data.email.sent} voye`}.` : ""}`);
      setRows((prev) => [{ id: data.id ?? Date.now().toString(), type, title, body, created_at: new Date().toISOString(), is_read: false }, ...prev]);
      setTitle("");
      setBody("");
      setTimeout(() => setSent(false), 3000);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erè");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-5 max-w-3xl">
      {/* Send form */}
      <div className="rounded-xl p-6" style={{ background: "#0e0f1e", border: "1px solid #2e3060" }}>
        <div className="flex items-center gap-2 mb-5">
          <Bell size={16} color="#a78bfa" />
          <div className="text-white font-semibold">Voye Notifikasyon ({userCount} itilizatè)</div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#94a3b8" }}>Tip</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="px-3 py-2 rounded-lg text-sm text-white outline-none w-full capitalize"
              style={{ background: "#0a0b18", border: "1px solid #2e3060" }}
            >
              {NOTIF_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#94a3b8" }}>Tit *</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Tit notifikasyon an…"
              className="px-3 py-2 rounded-lg text-sm text-white outline-none w-full"
              style={{ background: "#0a0b18", border: "1px solid #2e3060" }}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold mb-1" style={{ color: "#94a3b8" }}>Mesaj (opsyonèl)</label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="Kontni notifikasyon an…"
              rows={3}
              className="px-3 py-2 rounded-lg text-sm text-white outline-none w-full resize-none"
              style={{ background: "#0a0b18", border: "1px solid #2e3060" }}
            />
          </div>

          <label className="flex items-center gap-2 text-sm" style={{ color: "#94a3b8" }}>
            <input
              type="checkbox"
              checked={sendEmail}
              onChange={(e) => setSendEmail(e.target.checked)}
            />
            Voye tou pa email depi support@granboulva.com
          </label>

          {error && <div className="text-sm px-3 py-2 rounded-lg" style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}>{error}</div>}
          {result && <div className="text-sm px-3 py-2 rounded-lg" style={{ background: "rgba(16,185,129,0.1)", color: "#34d399" }}>{result}</div>}

          <button
            onClick={send}
            disabled={!title.trim() || sending}
            className="flex items-center gap-2 px-6 py-3 rounded-xl text-sm font-semibold text-white transition-all"
            style={{
              background: sent ? "#16a34a" : "linear-gradient(90deg,#7c3aed,#a855f7)",
              opacity: !title.trim() || sending ? 0.5 : 1,
              boxShadow: "0 0 20px rgba(124,58,237,0.3)",
            }}
          >
            <Send size={14} />
            {sending ? "Ap voye…" : sent ? "Voye ✓" : "Voye pou tout moun"}
          </button>
        </div>
      </div>

      {/* History */}
      <div>
        <div className="text-white font-semibold mb-3">Dènye Notifikasyon yo</div>
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
          <table className="w-full text-sm">
            <thead>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {["Tip", "Tit", "Kò", "Dat"].map((h) => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold uppercase" style={{ color: "#94a3b8" }}>{h}</th>
                ))}
              </tr>
              <tr style={{ background: "#0a0b18", borderBottom: "1px solid #2e3060" }}>
                {[
                  ["type", "Filtre tip"],
                  ["title", "Filtre tit"],
                  ["body", "Filtre kò"],
                  ["date", "Filtre dat"],
                ].map(([key, placeholder]) => (
                  <th key={key} className="px-4 pb-3">
                    <input value={filters[key as keyof typeof filters]}
                      onChange={(e) => setFilters((prev) => ({ ...prev, [key]: e.target.value }))}
                      placeholder={placeholder}
                      className="w-full px-2 py-1.5 rounded-md text-xs text-white outline-none"
                      style={{ background: "#0e0f1e", border: "1px solid #2e3060" }} />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filteredRows.length === 0 && (
                <tr><td colSpan={4} className="px-4 py-10 text-center" style={{ color: "#94a3b8" }}>Pa gen notifikasyon yo</td></tr>
              )}
              {filteredRows.slice(0, 30).map((n) => (
                <tr key={n.id} style={{ borderBottom: "1px solid #2e3060", background: "#0e0f1e" }}>
                  <td className="px-4 py-3">
                    <span className="px-2 py-0.5 rounded-full text-xs font-semibold"
                      style={{ background: "rgba(124,58,237,0.15)", color: "#a78bfa" }}>
                      {n.type}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-white font-medium">{n.title}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8", maxWidth: 300 }}>
                    <div className="truncate">{n.body ?? "—"}</div>
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#94a3b8" }}>{fmtDate(n.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
