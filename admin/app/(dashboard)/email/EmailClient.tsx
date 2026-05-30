"use client";

import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp, FilePlus, Inbox, Pencil, Save, Send, Trash2, X, Zap } from "lucide-react";

type Message = {
  id: string;
  direction: string;
  status: string;
  from_email?: string | null;
  to_email?: string | null;
  subject?: string | null;
  body_text?: string | null;
  body_html?: string | null;
  error?: string | null;
  created_at: string;
};

type Template = {
  id: string;
  name: string;
  subject: string;
  body_text?: string | null;
  body_html?: string | null;
  signature_html?: string | null;
  created_at?: string;
};

type EventMapping = {
  event_slug: string;
  template_id: string | null;
  enabled: boolean;
  label_ht: string;
  description_ht: string | null;
  category: string;
};

type Settings = {
  from_email: string;
  reply_to: string;
  default_signature_html?: string | null;
};

function fmtDate(d: string) {
  return new Date(d).toLocaleString("fr-HT", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

const DEFAULT_SIGNATURE = `<table cellpadding="0" cellspacing="0" border="0" style="font-family:Arial,sans-serif;font-size:13px;color:#64748B;line-height:1.5;">
  <tr>
    <td style="padding-right:16px;border-right:3px solid #5000A0;vertical-align:middle;">
      <img src="https://granboulva.com/logo_email.png" alt="Gran Boulva" width="96" style="display:block;height:auto;border-radius:8px;" />
    </td>
    <td style="padding-left:16px;vertical-align:middle;">
      <p style="margin:0 0 2px 0;font-size:15px;font-weight:700;color:#0F172A;">Gran Boulva Support</p>
      <p style="margin:0 0 6px 0;font-size:12px;color:#5000A0;font-weight:600;">Community Support · Gran Boulva</p>
      <p style="margin:0 0 2px 0;font-size:12px;">✉️ <a href="mailto:support@granboulva.com" style="color:#64748B;text-decoration:none;">support@granboulva.com</a></p>
      <p style="margin:0;font-size:12px;">🌐 <a href="https://granboulva.com" style="color:#5000A0;text-decoration:none;">granboulva.com</a></p>
    </td>
  </tr>
</table>`;

// Email header HTML shared across all previews
const EMAIL_HEADER_HTML = `<div style="background:#07080f;border-radius:14px;padding:18px 24px;margin-bottom:18px;text-align:center;">
  <img src="https://granboulva.com/logo_email.png" alt="Gran Boulva" width="72" style="display:block;margin:0 auto 12px;height:auto;border-radius:10px;" />
  <div style="color:#ffffff;font-size:18px;font-weight:800;letter-spacing:0.3px;">Gran Boulva</div>
  <div style="color:#a78bfa;font-size:11px;margin-top:3px;letter-spacing:0.5px;">Debat · Vote · Kominote</div>
</div>`;

function buildPreviewHtml(subject: string, body: string, signature: string) {
  return `<!doctype html><html><body style="margin:0;background:#f8fafc;font-family:Arial,sans-serif;color:#111827;">
<div style="max-width:640px;margin:0 auto;padding:28px 18px;">
  ${EMAIL_HEADER_HTML}
  <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:24px;">
    <h1 style="font-size:22px;line-height:1.25;margin:0 0 16px;">${subject || "Subject"}</h1>
    <div style="font-size:15px;line-height:1.65;color:#374151;">${body || "Body preview"}</div>
    ${signature ? `<div style="border-top:1px solid #e5e7eb;margin-top:24px;padding-top:18px;">${signature}</div>` : ""}
  </div>
</div></body></html>`;
}

// ── Shared input styles ────────────────────────────────────────────────────────
const inputCls = "w-full px-3 py-2 rounded-lg text-sm text-white outline-none";
const inputStyle = { background: "#0a0b18", border: "1px solid #2e3060" };
const cardStyle = { background: "#0e0f1e", border: "1px solid #2e3060" };
const labelCls = "text-xs font-semibold mb-1 block";

const CATEGORY_LABELS: Record<string, string> = {
  kont: "Kont Itilizatè",
  peman: "Peman",
  "kominotè": "Kominotè",
  general: "Jeneral",
};

// ── Single event row ───────────────────────────────────────────────────────────
function EventRow({ ev, templates, onChange }: {
  ev: EventMapping;
  templates: Template[];
  onChange: (slug: string, patch: Partial<EventMapping>) => void;
}) {
  const [saving, setSaving] = useState(false);
  const [ok, setOk] = useState(false);

  async function patch(update: Partial<EventMapping>) {
    setSaving(true);
    onChange(ev.event_slug, update);
    try {
      await fetch("/api/email/events", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ event_slug: ev.event_slug, ...update }),
      });
      setOk(true);
      setTimeout(() => setOk(false), 2000);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="flex items-center gap-4 px-5 py-4" style={{ borderTop: "1px solid #2e3060" }}>
      {/* Enabled toggle */}
      <button
        onClick={() => patch({ enabled: !ev.enabled })}
        title={ev.enabled ? "Dezaktive" : "Aktive"}
        className="flex-shrink-0 rounded-full transition-colors"
        style={{
          width: 36,
          height: 20,
          background: ev.enabled ? "#7c3aed" : "#1e2040",
          border: "1px solid " + (ev.enabled ? "#7c3aed" : "#2e3060"),
          position: "relative",
        }}
      >
        <span style={{
          position: "absolute",
          top: 2,
          left: ev.enabled ? 17 : 2,
          width: 14,
          height: 14,
          borderRadius: "50%",
          background: "white",
          transition: "left 0.15s",
          display: "block",
        }} />
      </button>

      {/* Labels */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-white">{ev.label_ht}</p>
        <p className="text-xs mt-0.5" style={{ color: "#94a3b8" }}>{ev.description_ht}</p>
        <p className="text-xs mt-0.5 font-mono" style={{ color: "#475569" }}>{ev.event_slug}</p>
      </div>

      {/* Template select */}
      <div className="flex-shrink-0 flex items-center gap-2">
        <select
          value={ev.template_id ?? ""}
          onChange={(e) => patch({ template_id: e.target.value || null })}
          disabled={saving}
          className="rounded-lg text-sm outline-none px-2 py-1.5"
          style={{ background: "#0a0b18", border: "1px solid #2e3060", color: ev.template_id ? "#e2e8f0" : "#475569", minWidth: 180 }}
        >
          <option value="">— Okenn template —</option>
          {templates.map((t) => (
            <option key={t.id} value={t.id}>{t.name}</option>
          ))}
        </select>

        {ok && <span style={{ color: "#34d399", fontSize: 11, whiteSpace: "nowrap" }}>✓ Sove</span>}
        {saving && !ok && <span style={{ color: "#94a3b8", fontSize: 11 }}>…</span>}
      </div>
    </div>
  );
}

// ── Template editor panel ──────────────────────────────────────────────────────
function TemplateEditor({
  initial,
  onSave,
  onCancel,
}: {
  initial?: Partial<Template>;
  onSave: (t: Template) => void;
  onCancel: () => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [subject, setSubject] = useState(initial?.subject ?? "");
  const [bodyText, setBodyText] = useState(initial?.body_text ?? "");
  const [bodyHtml, setBodyHtml] = useState(initial?.body_html ?? "");
  const [sigHtml, setSigHtml] = useState(initial?.signature_html ?? "");
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState("");
  const [previewOpen, setPreviewOpen] = useState(false);

  const previewHtml = buildPreviewHtml(
    subject,
    bodyHtml || bodyText.replace(/\n/g, "<br/>"),
    sigHtml,
  );

  async function save() {
    if (!name.trim() || !subject.trim()) { setErr("Name and subject are required"); return; }
    setSaving(true); setErr("");
    try {
      const res = await fetch("/api/email/templates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: initial?.id, name: name.trim(), subject: subject.trim(), body_text: bodyText, body_html: bodyHtml, signature_html: sigHtml }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Save failed");
      onSave(data as Template);
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Save failed");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="rounded-xl p-5 space-y-4" style={cardStyle}>
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-white">{initial?.id ? "Edit Template" : "New Template"}</h3>
        <button onClick={onCancel}><X size={16} style={{ color: "#94a3b8" }} /></button>
      </div>

      {err && <p className="text-xs rounded px-3 py-2" style={{ background: "rgba(239,68,68,.1)", color: "#f87171" }}>{err}</p>}

      <div className="grid gap-3" style={{ gridTemplateColumns: "1fr 1fr" }}>
        <div>
          <label className={labelCls} style={{ color: "#94a3b8" }}>Template name (slug)</label>
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="welcome_confirmed" className={inputCls} style={inputStyle} />
        </div>
        <div>
          <label className={labelCls} style={{ color: "#94a3b8" }}>Subject line</label>
          <input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Byenveni sou Gran Boulva!" className={inputCls} style={inputStyle} />
        </div>
      </div>

      <div>
        <label className={labelCls} style={{ color: "#94a3b8" }}>Body — plain text (fallback)</label>
        <textarea value={bodyText} onChange={(e) => setBodyText(e.target.value)} rows={5} placeholder={"Plain text body.\n\nUse {{name}} to personalise."} className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      <div>
        <label className={labelCls} style={{ color: "#94a3b8" }}>Body — HTML (shown inside the Gran Boulva email wrapper)</label>
        <textarea value={bodyHtml} onChange={(e) => setBodyHtml(e.target.value)} rows={6} placeholder={"<p>Kont ou konfime. <strong>Byenveni!</strong></p>"} className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      <div>
        <label className={labelCls} style={{ color: "#94a3b8" }}>Signature HTML (leave blank to use default)</label>
        <textarea value={sigHtml} onChange={(e) => setSigHtml(e.target.value)} rows={4} placeholder="<table>…</table>  — leave blank to use default signature" className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      <div className="flex gap-2 flex-wrap">
        <button
          onClick={() => setPreviewOpen((p) => !p)}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold"
          style={{ border: "1px solid #2e3060", color: "#94a3b8" }}
        >
          {previewOpen ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
          {previewOpen ? "Hide preview" : "Show preview"}
        </button>
        <button onClick={onCancel} className="px-4 py-2 rounded-lg text-xs font-semibold" style={{ border: "1px solid #2e3060", color: "#94a3b8" }}>
          Cancel
        </button>
        <button onClick={save} disabled={saving} className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold disabled:opacity-50" style={{ background: "#7c3aed", color: "white" }}>
          <Save size={13} /> {saving ? "Saving…" : "Save template"}
        </button>
      </div>

      {previewOpen && (
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060", height: 420 }}>
          <iframe title="preview" srcDoc={previewHtml} className="w-full h-full" />
        </div>
      )}
    </div>
  );
}

// ── Main component ─────────────────────────────────────────────────────────────
export default function EmailClient({
  messages,
  templates,
  settings,
  events,
  setupError,
}: {
  messages: Message[];
  templates: Template[];
  settings: Settings;
  events: EventMapping[];
  setupError: string | null;
}) {
  const [tab, setTab] = useState<"compose" | "inbox" | "templates" | "events">("compose");
  const [rows, setRows] = useState(messages);
  const [templateRows, setTemplateRows] = useState(templates);
  const [eventRows, setEventRows] = useState<EventMapping[]>(events);

  // Compose state
  const [to, setTo] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [signature, setSignature] = useState(settings.default_signature_html ?? DEFAULT_SIGNATURE);
  const [templateName, setTemplateName] = useState("");
  const [sending, setSending] = useState(false);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);

  // Templates tab state
  const [editingId, setEditingId] = useState<string | "new" | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // Signature settings state
  const [sigHtml, setSigHtml] = useState(settings.default_signature_html ?? DEFAULT_SIGNATURE);
  const [sigSaving, setSigSaving] = useState(false);
  const [sigPreview, setSigPreview] = useState(false);

  // Global notices
  const [notice, setNotice] = useState<string | null>(setupError ? `Email tables not ready: ${setupError}` : null);
  const [error, setError] = useState<string | null>(null);

  function flash(msg: string, type: "ok" | "err" = "ok") {
    if (type === "ok") { setNotice(msg); setError(null); }
    else { setError(msg); setNotice(null); }
    setTimeout(() => { setNotice(null); setError(null); }, 4000);
  }

  const previewHtml = useMemo(
    () => buildPreviewHtml(subject, body.replace(/\n/g, "<br/>"), signature),
    [body, signature, subject]
  );

  // ── Compose actions ────────────────────────────────────────────────────────
  async function send() {
    setSending(true); setError(null); setNotice(null);
    try {
      const res = await fetch("/api/email/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ to, subject, body, signature, templateName }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "Email failed");
      flash("Email sent.");
      setRows((p) => [{ id: data.id ?? Date.now().toString(), direction: "outbound", status: "sent", from_email: settings.from_email, to_email: to, subject, body_text: body, created_at: new Date().toISOString() }, ...p]);
    } catch (e) { flash(e instanceof Error ? e.message : "Email failed", "err"); }
    finally { setSending(false); }
  }

  async function saveTemplate() {
    setSaving(true); setError(null);
    try {
      const res = await fetch("/api/email/templates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: templateName || subject || "Untitled", subject, body_text: body, body_html: body.replace(/\n/g, "<br/>"), signature_html: signature }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "Save failed");
      setTemplateRows((p) => [data, ...p.filter((t) => t.id !== data.id)]);
      flash("Template saved.");
    } catch (e) { flash(e instanceof Error ? e.message : "Save failed", "err"); }
    finally { setSaving(false); }
  }

  async function sendTest() {
    setTesting(true); setError(null); setNotice(null);
    try {
      const res = await fetch("/api/email/test", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ to }) });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "SMTP test failed");
      flash("Test email sent.");
    } catch (e) { flash(e instanceof Error ? e.message : "SMTP test failed", "err"); }
    finally { setTesting(false); }
  }

  // ── Templates actions ─────────────────────────────────────────────────────
  async function deleteTemplate(id: string) {
    setDeletingId(id);
    try {
      const res = await fetch("/api/email/templates", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id }),
      });
      if (!res.ok) { const d = await res.json().catch(() => ({})); throw new Error(d.error ?? "Delete failed"); }
      setTemplateRows((p) => p.filter((t) => t.id !== id));
      flash("Template deleted.");
    } catch (e) { flash(e instanceof Error ? e.message : "Delete failed", "err"); }
    finally { setDeletingId(null); }
  }

  // ── Signature save ────────────────────────────────────────────────────────
  async function saveSignature() {
    setSigSaving(true);
    try {
      const res = await fetch("/api/email/settings", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ from_email: settings.from_email, reply_to: settings.reply_to, default_signature_html: sigHtml }),
      });
      if (!res.ok) { const d = await res.json().catch(() => ({})); throw new Error(d.error ?? "Save failed"); }
      flash("Default signature saved.");
    } catch (e) { flash(e instanceof Error ? e.message : "Save failed", "err"); }
    finally { setSigSaving(false); }
  }

  // ── Events update ─────────────────────────────────────────────────────────
  function handleEventChange(slug: string, patch: Partial<EventMapping>) {
    setEventRows((prev) => prev.map((e) => e.event_slug === slug ? { ...e, ...patch } : e));
  }

  // Group events by category
  const eventsByCategory = useMemo(() => {
    const map: Record<string, EventMapping[]> = {};
    for (const ev of eventRows) {
      if (!map[ev.category]) map[ev.category] = [];
      map[ev.category].push(ev);
    }
    return map;
  }, [eventRows]);

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-5">
      {/* Tabs */}
      <div className="flex gap-2">
        {([
          ["compose",   "Compose"],
          ["inbox",     "Inbox"],
          ["templates", "Templates"],
          ["events",    "Evènman"],
        ] as const).map(([key, label]) => (
          <button key={key} onClick={() => setTab(key)}
            className="px-3 py-2 rounded-lg text-xs font-semibold"
            style={{ background: tab === key ? "rgba(124,58,237,0.18)" : "#0e0f1e", color: tab === key ? "#a78bfa" : "#94a3b8", border: "1px solid #2e3060" }}>
            {label}
          </button>
        ))}
      </div>

      {notice && <div className="rounded-lg px-4 py-3 text-sm" style={{ background: "rgba(16,185,129,0.1)", color: "#34d399" }}>{notice}</div>}
      {error && <div className="rounded-lg px-4 py-3 text-sm" style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}>{error}</div>}

      {/* ── Compose ─────────────────────────────────────────────────────── */}
      {tab === "compose" && (
        <div className="grid gap-5" style={{ gridTemplateColumns: "minmax(0,1fr) minmax(320px,420px)" }}>
          <div className="rounded-xl p-5 space-y-4" style={cardStyle}>
            <input value={to} onChange={(e) => setTo(e.target.value)} placeholder="recipient@example.com" className={inputCls} style={inputStyle} />
            <input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Subject" className={inputCls} style={inputStyle} />
            <input value={templateName} onChange={(e) => setTemplateName(e.target.value)} placeholder="Template name (optional — for Save Template)" className={inputCls} style={inputStyle} />
            <textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Message body" rows={8} className={`${inputCls} resize-none`} style={inputStyle} />
            <div>
              <label className={labelCls} style={{ color: "#94a3b8" }}>Signature HTML</label>
              <textarea value={signature} onChange={(e) => setSignature(e.target.value)} rows={4} className={`${inputCls} resize-none font-mono`} style={inputStyle} />
            </div>

            {/* Template quick-load */}
            {templateRows.length > 0 && (
              <div className="flex flex-wrap gap-2">
                <span className="text-xs self-center" style={{ color: "#94a3b8" }}>Load:</span>
                {templateRows.map((t) => (
                  <button key={t.id} onClick={() => { setTemplateName(t.name); setSubject(t.subject); setBody(t.body_text ?? ""); setSignature(t.signature_html ?? sigHtml); }}
                    className="px-2 py-1 rounded text-xs" style={{ border: "1px solid #2e3060", color: "#94a3b8" }}>
                    {t.name}
                  </button>
                ))}
              </div>
            )}

            <div className="flex gap-2 flex-wrap">
              <button onClick={sendTest} disabled={!to || testing} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ border: "1px solid #2e3060", color: "#94a3b8" }}>
                <Send size={14} /> {testing ? "Testing…" : "Test SMTP"}
              </button>
              <button onClick={send} disabled={!to || !subject || !body || sending} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ background: "#7c3aed", color: "white" }}>
                <Send size={14} /> {sending ? "Sending…" : "Send"}
              </button>
              <button onClick={saveTemplate} disabled={!subject || saving} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ border: "1px solid #2e3060", color: "#94a3b8" }}>
                <Save size={14} /> {saving ? "Saving…" : "Save Template"}
              </button>
            </div>
          </div>
          <div className="rounded-xl overflow-hidden" style={{ background: "white", border: "1px solid #2e3060" }}>
            <iframe title="Email preview" srcDoc={previewHtml} className="w-full h-full min-h-[480px]" />
          </div>
        </div>
      )}

      {/* ── Inbox ───────────────────────────────────────────────────────── */}
      {tab === "inbox" && (
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
          <table className="w-full text-sm">
            <thead style={{ background: "#0a0b18" }}>
              <tr>{["Dir", "Status", "From", "To", "Subject", "Date"].map((h) => (
                <th key={h} className="px-4 py-3 text-left text-xs uppercase" style={{ color: "#94a3b8" }}>{h}</th>
              ))}</tr>
            </thead>
            <tbody>
              {rows.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-12 text-center" style={{ color: "#94a3b8" }}><Inbox size={20} className="inline mr-2" />No emails yet</td></tr>
              )}
              {rows.map((m) => (
                <tr key={m.id} style={{ borderTop: "1px solid #2e3060", background: "#0e0f1e" }}>
                  <td className="px-4 py-3" style={{ color: m.direction === "inbound" ? "#34d399" : "#a78bfa" }}>{m.direction}</td>
                  <td className="px-4 py-3" style={{ color: m.status === "failed" ? "#f87171" : "#94a3b8" }}>{m.status}</td>
                  <td className="px-4 py-3 text-white">{m.from_email ?? "—"}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{m.to_email ?? "—"}</td>
                  <td className="px-4 py-3 text-white">{m.subject ?? "—"}</td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#94a3b8" }}>{fmtDate(m.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Templates & Signature ────────────────────────────────────────── */}
      {tab === "templates" && (
        <div className="space-y-6">

          {/* ── Default Signature ─────────────────────────────────────────── */}
          <section className="rounded-xl p-5 space-y-4" style={cardStyle}>
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-semibold text-white">Siyati pa defò</h2>
                <p className="text-xs mt-0.5" style={{ color: "#94a3b8" }}>Used in Compose and as fallback when a template has no signature.</p>
              </div>
              <div className="flex gap-2">
                <button onClick={() => setSigPreview((p) => !p)} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold" style={{ border: "1px solid #2e3060", color: "#94a3b8" }}>
                  {sigPreview ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
                  {sigPreview ? "Hide" : "Preview"}
                </button>
                <button onClick={saveSignature} disabled={sigSaving} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold disabled:opacity-50" style={{ background: "#7c3aed", color: "white" }}>
                  <Save size={12} /> {sigSaving ? "Saving…" : "Save signature"}
                </button>
              </div>
            </div>
            <textarea
              value={sigHtml}
              onChange={(e) => setSigHtml(e.target.value)}
              rows={7}
              className={`${inputCls} resize-none font-mono`}
              style={inputStyle}
              placeholder="<table>…HTML signature…</table>"
            />
            {sigPreview && (
              <div className="rounded-xl overflow-hidden" style={{ background: "white", border: "1px solid #e5e7eb", height: 160 }}>
                <iframe title="sig-preview" srcDoc={`<html><body style="margin:16px;font-family:Arial,sans-serif;">${sigHtml}</body></html>`} className="w-full h-full" />
              </div>
            )}
          </section>

          {/* ── Templates list ────────────────────────────────────────────── */}
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-semibold text-white">Templates ({templateRows.length})</h2>
              <button
                onClick={() => setEditingId("new")}
                disabled={editingId === "new"}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold disabled:opacity-40"
                style={{ background: "rgba(124,58,237,0.18)", color: "#a78bfa", border: "1px solid #4c1d95" }}
              >
                <FilePlus size={13} /> New template
              </button>
            </div>

            {editingId === "new" && (
              <TemplateEditor
                onSave={(t) => { setTemplateRows((p) => [t, ...p]); setEditingId(null); flash("Template created."); }}
                onCancel={() => setEditingId(null)}
              />
            )}

            {templateRows.length === 0 && editingId !== "new" && (
              <p className="text-sm py-8 text-center" style={{ color: "#94a3b8" }}>Okenn template. Klike « New template » pou kreye youn.</p>
            )}

            {templateRows.map((t) =>
              editingId === t.id ? (
                <TemplateEditor
                  key={t.id}
                  initial={t}
                  onSave={(updated) => { setTemplateRows((p) => p.map((x) => x.id === updated.id ? updated : x)); setEditingId(null); flash("Template updated."); }}
                  onCancel={() => setEditingId(null)}
                />
              ) : (
                <div key={t.id} className="rounded-xl px-5 py-4 flex items-start justify-between gap-4" style={cardStyle}>
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{t.name}</p>
                    <p className="text-xs mt-0.5 truncate" style={{ color: "#94a3b8" }}>{t.subject}</p>
                    {t.body_text && (
                      <p className="text-xs mt-1 line-clamp-2" style={{ color: "#94a3b8" }}>{t.body_text}</p>
                    )}
                  </div>
                  <div className="flex gap-2 flex-shrink-0">
                    <button
                      onClick={() => { setSubject(t.subject); setBody(t.body_text ?? ""); setSignature(t.signature_html ?? sigHtml); setTemplateName(t.name); setTab("compose"); }}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold"
                      style={{ border: "1px solid #2e3060", color: "#94a3b8" }}
                      title="Load into Compose"
                    >
                      <Send size={12} /> Use
                    </button>
                    <button
                      onClick={() => setEditingId(t.id)}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold"
                      style={{ border: "1px solid #2e3060", color: "#94a3b8" }}
                    >
                      <Pencil size={12} /> Edit
                    </button>
                    <button
                      onClick={() => deleteTemplate(t.id)}
                      disabled={deletingId === t.id}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold disabled:opacity-40"
                      style={{ border: "1px solid #3f1515", color: "#f87171" }}
                    >
                      <Trash2 size={12} /> {deletingId === t.id ? "…" : "Delete"}
                    </button>
                  </div>
                </div>
              )
            )}
          </section>
        </div>
      )}

      {/* ── Evènman ─────────────────────────────────────────────────────── */}
      {tab === "events" && (
        <div className="space-y-6">
          <div className="rounded-xl px-5 py-4 flex items-start gap-3" style={{ background: "rgba(124,58,237,0.08)", border: "1px solid rgba(124,58,237,0.2)" }}>
            <Zap size={16} style={{ color: "#a78bfa", flexShrink: 0, marginTop: 1 }} />
            <div>
              <p className="text-sm font-semibold text-white">Evènman otomatik</p>
              <p className="text-xs mt-1" style={{ color: "#94a3b8" }}>
                Chak evènman ka lye ak yon template imèl. Aktive switch la pou Gran Boulva voye imèl otomatikman lè evènman sa rive.
                Si okenn template pa chwazi, imèl la p ap voye menm si li aktive.
              </p>
            </div>
          </div>

          {templateRows.length === 0 && (
            <div className="rounded-xl px-5 py-4 text-sm" style={{ background: "rgba(239,68,68,0.07)", border: "1px solid rgba(239,68,68,0.2)", color: "#f87171" }}>
              Kreye omwen yon template anvan ou ka asiye evènman yo. Ale nan « Templates » pou kòmanse.
            </div>
          )}

          {Object.entries(eventsByCategory).map(([cat, evs]) => (
            <section key={cat} className="rounded-xl overflow-hidden" style={{ border: "1px solid #2e3060" }}>
              {/* Category header */}
              <div className="px-5 py-3 flex items-center gap-2" style={{ background: "#0a0b18" }}>
                <span className="text-xs font-bold uppercase tracking-widest" style={{ color: "#a78bfa" }}>
                  {CATEGORY_LABELS[cat] ?? cat}
                </span>
                <span className="text-xs rounded-full px-2 py-0.5" style={{ background: "rgba(124,58,237,0.12)", color: "#94a3b8" }}>
                  {evs.filter((e) => e.enabled).length}/{evs.length} aktive
                </span>
              </div>

              {evs.map((ev) => (
                <EventRow
                  key={ev.event_slug}
                  ev={ev}
                  templates={templateRows}
                  onChange={handleEventChange}
                />
              ))}
            </section>
          ))}

          {eventRows.length === 0 && (
            <p className="text-center py-12 text-sm" style={{ color: "#94a3b8" }}>
              Tab evènman an p ap disponib — migrasyon DB a pa aplike yo. Voye <code>supabase db push</code>.
            </p>
          )}
        </div>
      )}
    </div>
  );
}
