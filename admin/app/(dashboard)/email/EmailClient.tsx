"use client";

import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp, FilePlus, Inbox, Pencil, Save, Send, Trash2, X } from "lucide-react";

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

// ── Shared input styles ────────────────────────────────────────────────────────
const inputCls = "w-full px-3 py-2 rounded-lg text-sm text-white outline-none";
const inputStyle = { background: "#0a0b18", border: "1px solid #2e3060" };
const cardStyle = { background: "#0e0f1e", border: "1px solid #2e3060" };
const labelCls = "text-xs font-semibold mb-1 block";

// ── Template editor panel (create or edit) ────────────────────────────────────
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

  const previewHtml = `<!doctype html><html><body style="margin:0;background:#f8fafc;font-family:Arial,sans-serif;color:#111827;">
<div style="max-width:640px;margin:0 auto;padding:28px 18px;">
  <div style="background:#07080f;border-radius:14px;padding:22px 24px;margin-bottom:18px;">
    <div style="color:#fff;font-size:20px;font-weight:800;">Gran Boulva</div>
    <div style="color:#a78bfa;font-size:12px;margin-top:4px;">Debat, vote, kominote</div>
  </div>
  <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:24px;">
    <h1 style="font-size:22px;line-height:1.25;margin:0 0 16px;">${subject || "Subject"}</h1>
    <div style="font-size:15px;line-height:1.65;color:#374151;">${bodyHtml || bodyText.replace(/\n/g, "<br/>") || "Body preview"}</div>
    ${sigHtml ? `<div style="border-top:1px solid #e5e7eb;margin-top:24px;padding-top:18px;">${sigHtml}</div>` : ""}
  </div>
</div></body></html>`;

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
      {/* Header */}
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-white">{initial?.id ? "Edit Template" : "New Template"}</h3>
        <button onClick={onCancel}><X size={16} style={{ color: "#94a3b8" }} /></button>
      </div>

      {err && <p className="text-xs rounded px-3 py-2" style={{ background: "rgba(239,68,68,.1)", color: "#f87171" }}>{err}</p>}

      {/* Fields */}
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
        <label className={labelCls} style={{ color: "#94a3b8" }}>Body — plain text (fallback + edge function)</label>
        <textarea value={bodyText} onChange={(e) => setBodyText(e.target.value)} rows={5} placeholder={"Plain text body.\n\nUse {{name}} to personalise."} className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      <div>
        <label className={labelCls} style={{ color: "#94a3b8" }}>Body — HTML (optional, shown inside the Gran Boulva email wrapper)</label>
        <textarea value={bodyHtml} onChange={(e) => setBodyHtml(e.target.value)} rows={6} placeholder={"<p>Kont ou konfime. <strong>Byenveni!</strong></p>\n\nUse {{name}} to personalise."} className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      <div>
        <label className={labelCls} style={{ color: "#94a3b8" }}>Signature HTML (leave blank to use default)</label>
        <textarea value={sigHtml} onChange={(e) => setSigHtml(e.target.value)} rows={4} placeholder="<table>…</table>  — leave blank to use default signature" className={`${inputCls} resize-none font-mono`} style={inputStyle} />
      </div>

      {/* Actions */}
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
  setupError,
}: {
  messages: Message[];
  templates: Template[];
  settings: Settings;
  setupError: string | null;
}) {
  const [tab, setTab] = useState<"compose" | "inbox" | "templates">("compose");
  const [rows, setRows] = useState(messages);
  const [templateRows, setTemplateRows] = useState(templates);

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
    () => `<!doctype html><html><body style="margin:0;background:#f8fafc;font-family:Arial,sans-serif;color:#111827;">
<div style="max-width:640px;margin:0 auto;padding:28px 18px;">
  <div style="background:#07080f;border-radius:14px;padding:22px 24px;margin-bottom:18px;">
    <div style="color:#fff;font-size:20px;font-weight:800;">Gran Boulva</div>
    <div style="color:#a78bfa;font-size:12px;margin-top:4px;">Debat, vote, kominote</div>
  </div>
  <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:24px;">
    <h1 style="font-size:22px;line-height:1.25;margin:0 0 16px;">${subject || "Subject"}</h1>
    <div style="font-size:15px;line-height:1.65;color:#374151;">${body.replace(/\n/g, "<br/>") || "Body preview"}</div>
    ${signature ? `<div style="border-top:1px solid #e5e7eb;margin-top:24px;padding-top:18px;">${signature}</div>` : ""}
  </div>
</div></body></html>`,
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

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-5">
      {/* Tabs */}
      <div className="flex gap-2">
        {([["compose", "Compose"], ["inbox", "Inbox"], ["templates", "Templates & Signature"]] as const).map(([key, label]) => (
          <button key={key} onClick={() => setTab(key)}
            className="px-3 py-2 rounded-lg text-xs font-semibold"
            style={{ background: tab === key ? "rgba(124,58,237,0.18)" : "#0e0f1e", color: tab === key ? "#a78bfa" : "#64748b", border: "1px solid #2e3060" }}>
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

            {/* New template form */}
            {editingId === "new" && (
              <TemplateEditor
                onSave={(t) => { setTemplateRows((p) => [t, ...p]); setEditingId(null); flash("Template created."); }}
                onCancel={() => setEditingId(null)}
              />
            )}

            {/* Existing templates */}
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
                    {/* Use in compose */}
                    <button
                      onClick={() => { setSubject(t.subject); setBody(t.body_text ?? ""); setSignature(t.signature_html ?? sigHtml); setTemplateName(t.name); setTab("compose"); }}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold"
                      style={{ border: "1px solid #2e3060", color: "#94a3b8" }}
                      title="Load into Compose"
                    >
                      <Send size={12} /> Use
                    </button>
                    {/* Edit */}
                    <button
                      onClick={() => setEditingId(t.id)}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold"
                      style={{ border: "1px solid #2e3060", color: "#94a3b8" }}
                    >
                      <Pencil size={12} /> Edit
                    </button>
                    {/* Delete */}
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
    </div>
  );
}
