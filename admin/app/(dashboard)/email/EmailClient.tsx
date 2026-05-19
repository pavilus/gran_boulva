"use client";

import { useMemo, useState } from "react";
import { Inbox, Save, Send } from "lucide-react";

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
};

type Settings = {
  from_email: string;
  reply_to: string;
  default_signature_html?: string | null;
};

function fmtDate(d: string) {
  return new Date(d).toLocaleString("fr-HT", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

const defaultSignature = `<table cellpadding="0" cellspacing="0" border="0" style="font-family:Arial,sans-serif;font-size:13px;color:#64748B;line-height:1.5;">
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
  const [to, setTo] = useState("");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [signature, setSignature] = useState(settings.default_signature_html ?? defaultSignature);
  const [templateName, setTemplateName] = useState("");
  const [sending, setSending] = useState(false);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [notice, setNotice] = useState<string | null>(setupError ? `Email tables not ready: ${setupError}` : null);
  const [error, setError] = useState<string | null>(null);

  const previewHtml = useMemo(
    () => `
      <div style="font-family:Arial,sans-serif;padding:22px;color:#111827">
        <h2>${subject || "Subject preview"}</h2>
        <div style="line-height:1.6">${(body || "Email body preview").replace(/\n/g, "<br />")}</div>
        <div style="border-top:1px solid #e5e7eb;margin-top:20px;padding-top:14px">${signature}</div>
      </div>
    `,
    [body, signature, subject]
  );

  async function send() {
    setSending(true);
    setError(null);
    setNotice(null);
    try {
      const res = await fetch("/api/email/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ to, subject, body, signature, templateName }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "Email failed");
      setNotice("Email sent.");
      setRows((prev) => [{
        id: data.id ?? Date.now().toString(),
        direction: "outbound",
        status: "sent",
        from_email: settings.from_email,
        to_email: to,
        subject,
        body_text: body,
        created_at: new Date().toISOString(),
      }, ...prev]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Email failed");
    } finally {
      setSending(false);
    }
  }

  async function saveTemplate() {
    setSaving(true);
    setError(null);
    try {
      const res = await fetch("/api/email/templates", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: templateName || subject || "Untitled template",
          subject,
          body_text: body,
          body_html: body.replace(/\n/g, "<br />"),
          signature_html: signature,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "Template save failed");
      setTemplateRows((prev) => [data, ...prev.filter((t) => t.id !== data.id)]);
      setNotice("Template saved.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Template save failed");
    } finally {
      setSaving(false);
    }
  }

  async function sendTest() {
    setTesting(true);
    setError(null);
    setNotice(null);
    try {
      const res = await fetch("/api/email/test", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ to }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? "SMTP test failed");
      setNotice("Test email sent.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "SMTP test failed");
    } finally {
      setTesting(false);
    }
  }

  return (
    <div className="space-y-5">
      <div className="flex gap-2">
        {[
          ["compose", "Send"],
          ["inbox", "Receive"],
          ["templates", "Templates & Signature"],
        ].map(([key, label]) => (
          <button
            key={key}
            onClick={() => setTab(key as typeof tab)}
            className="px-3 py-2 rounded-lg text-xs font-semibold"
            style={{
              background: tab === key ? "rgba(124,58,237,0.18)" : "#0e0f1e",
              color: tab === key ? "#a78bfa" : "#64748b",
              border: "1px solid #1e2040",
            }}
          >
            {label}
          </button>
        ))}
      </div>

      {notice && <div className="rounded-lg px-4 py-3 text-sm" style={{ background: "rgba(16,185,129,0.1)", color: "#34d399" }}>{notice}</div>}
      {error && <div className="rounded-lg px-4 py-3 text-sm" style={{ background: "rgba(239,68,68,0.1)", color: "#f87171" }}>{error}</div>}

      {tab === "compose" && (
        <div className="grid gap-5" style={{ gridTemplateColumns: "minmax(0, 1fr) minmax(320px, 420px)" }}>
          <div className="rounded-xl p-5 space-y-4" style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}>
            <input value={to} onChange={(e) => setTo(e.target.value)} placeholder="recipient@example.com, another@example.com" className="w-full px-3 py-2 rounded-lg text-sm text-white outline-none" style={{ background: "#0a0b18", border: "1px solid #1e2040" }} />
            <input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Subject" className="w-full px-3 py-2 rounded-lg text-sm text-white outline-none" style={{ background: "#0a0b18", border: "1px solid #1e2040" }} />
            <textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Message body" rows={8} className="w-full px-3 py-2 rounded-lg text-sm text-white outline-none resize-none" style={{ background: "#0a0b18", border: "1px solid #1e2040" }} />
            <textarea value={signature} onChange={(e) => setSignature(e.target.value)} rows={4} className="w-full px-3 py-2 rounded-lg text-sm text-white outline-none resize-none font-mono" style={{ background: "#0a0b18", border: "1px solid #1e2040" }} />
            <div className="flex gap-2">
              <button onClick={sendTest} disabled={!to || testing} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ border: "1px solid #1e2040", color: "#94a3b8" }}>
                <Send size={14} /> {testing ? "Testing..." : "Test SMTP"}
              </button>
              <button onClick={send} disabled={!to || !subject || !body || sending} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ background: "#7c3aed", color: "white" }}>
                <Send size={14} /> {sending ? "Sending..." : "Send Email"}
              </button>
              <button onClick={saveTemplate} disabled={!subject || saving} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold disabled:opacity-50" style={{ border: "1px solid #1e2040", color: "#94a3b8" }}>
                <Save size={14} /> {saving ? "Saving..." : "Save Template"}
              </button>
            </div>
          </div>
          <div className="rounded-xl overflow-hidden" style={{ background: "white", border: "1px solid #1e2040" }}>
            <iframe title="Email preview" srcDoc={previewHtml} className="w-full h-full min-h-[480px]" />
          </div>
        </div>
      )}

      {tab === "inbox" && (
        <div className="rounded-xl overflow-hidden" style={{ border: "1px solid #1e2040" }}>
          <table className="w-full text-sm">
            <thead style={{ background: "#0a0b18" }}>
              <tr>{["Dir", "Status", "From", "To", "Subject", "Date"].map((h) => <th key={h} className="px-4 py-3 text-left text-xs uppercase" style={{ color: "#475569" }}>{h}</th>)}</tr>
            </thead>
            <tbody>
              {rows.length === 0 && <tr><td colSpan={6} className="px-4 py-12 text-center" style={{ color: "#475569" }}><Inbox size={20} className="inline mr-2" />No emails yet</td></tr>}
              {rows.map((m) => (
                <tr key={m.id} style={{ borderTop: "1px solid #1e2040", background: "#0e0f1e" }}>
                  <td className="px-4 py-3" style={{ color: m.direction === "inbound" ? "#34d399" : "#a78bfa" }}>{m.direction}</td>
                  <td className="px-4 py-3" style={{ color: m.status === "failed" ? "#f87171" : "#94a3b8" }}>{m.status}</td>
                  <td className="px-4 py-3 text-white">{m.from_email ?? "—"}</td>
                  <td className="px-4 py-3" style={{ color: "#94a3b8" }}>{m.to_email ?? "—"}</td>
                  <td className="px-4 py-3 text-white">{m.subject ?? "—"}</td>
                  <td className="px-4 py-3 whitespace-nowrap" style={{ color: "#64748b" }}>{fmtDate(m.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "templates" && (
        <div className="grid gap-4" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))" }}>
          {templateRows.map((t) => (
            <button
              key={t.id}
              onClick={() => {
                setTemplateName(t.name);
                setSubject(t.subject);
                setBody(t.body_text ?? "");
                setSignature(t.signature_html ?? settings.default_signature_html ?? defaultSignature);
                setTab("compose");
              }}
              className="rounded-xl p-4 text-left"
              style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
            >
              <div className="text-white font-semibold text-sm">{t.name}</div>
              <div className="mt-1 text-xs" style={{ color: "#64748b" }}>{t.subject}</div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
