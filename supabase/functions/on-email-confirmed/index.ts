/**
 * on-email-confirmed
 *
 * Triggered by a Supabase Database Webhook on auth.users (UPDATE event).
 * Fires only when email_confirmed_at changes from null → a timestamp.
 *
 * Sends the `welcome_confirmed` email template to the newly confirmed user.
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Types ─────────────────────────────────────────────────────────────────────

/** Supabase Database Webhook payload for auth.users UPDATE */
interface DbWebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: AuthUserRecord | null;
  old_record: AuthUserRecord | null;
}

interface AuthUserRecord {
  id: string;
  email: string | null;
  email_confirmed_at: string | null;
  raw_user_meta_data?: {
    full_name?: string;
    username?: string;
  };
}

interface EmailTemplate {
  subject: string;
  body_text: string | null;
  body_html: string | null;
  signature_html: string | null;
}

// ── SMTP sender (nodemailer via Deno npm compat) ───────────────────────────

async function sendSmtp(opts: {
  to: string;
  subject: string;
  html: string;
  text?: string;
}): Promise<{ ok: boolean; id?: string; error?: string }> {
  const host = Deno.env.get("SMTP_HOST");
  const port = Number(Deno.env.get("SMTP_PORT") ?? "465");
  const user = Deno.env.get("SMTP_USER");
  const pass = Deno.env.get("SMTP_PASS");
  const from =
    Deno.env.get("EMAIL_FROM") ?? "Gran Boulva <support@granboulva.com>";

  if (!host || !user || !pass) {
    return { ok: false, error: "SMTP_HOST / SMTP_USER / SMTP_PASS not set in secrets" };
  }

  try {
    // deno-lint-ignore no-explicit-any
    const { default: nodemailer } = await import("npm:nodemailer") as any;
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: (Deno.env.get("SMTP_SECURE") ?? "true") !== "false",
      auth: { user, pass },
    });

    const info = await transporter.sendMail({
      from,
      to: opts.to,
      subject: opts.subject,
      html: opts.html,
      text: opts.text ?? undefined,
      replyTo: Deno.env.get("EMAIL_REPLY_TO") ?? "support@granboulva.com",
    });

    return { ok: true, id: info.messageId };
  } catch (err) {
    const msg = err instanceof Error ? err.message : "SMTP error";
    return { ok: false, error: msg };
  }
}

// ── Email HTML wrapper (mirrors admin/lib/email.ts) ────────────────────────

function escapeHtml(v: string) {
  return v
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function renderEmailHtml(opts: {
  title: string;
  body: string;
  signature?: string | null;
}) {
  return `<!doctype html>
<html>
  <body style="margin:0;background:#f8fafc;font-family:Arial,sans-serif;color:#111827;">
    <div style="max-width:640px;margin:0 auto;padding:28px 18px;">
      <div style="background:#07080f;border-radius:14px;padding:22px 24px;margin-bottom:18px;">
        <div style="color:#ffffff;font-size:20px;font-weight:800;">Gran Boulva</div>
        <div style="color:#a78bfa;font-size:12px;margin-top:4px;">Debat, vote, kominote</div>
      </div>
      <div style="background:#ffffff;border:1px solid #e5e7eb;border-radius:14px;padding:24px;">
        <h1 style="font-size:22px;line-height:1.25;margin:0 0 16px;color:#111827;">${escapeHtml(opts.title)}</h1>
        <div style="font-size:15px;line-height:1.65;color:#374151;">${opts.body}</div>
        ${opts.signature ? `<div style="border-top:1px solid #e5e7eb;margin-top:24px;padding-top:18px;color:#4b5563;font-size:14px;line-height:1.55;">${opts.signature}</div>` : ""}
      </div>
      <div style="text-align:center;color:#9ca3af;font-size:12px;margin-top:18px;">
        support@granboulva.com
      </div>
    </div>
  </body>
</html>`;
}

// ── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  // Webhook secret verification
  const webhookSecret = Deno.env.get("WEBHOOK_SECRET");
  if (webhookSecret) {
    const authHeader = req.headers.get("authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (token !== webhookSecret) {
      return Response.json({ error: "Unauthorized" }, { status: 401 });
    }
  }

  let payload: DbWebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }

  // Only process UPDATE on auth.users where email_confirmed_at just became non-null
  const { type, record, old_record } = payload;
  if (
    type !== "UPDATE" ||
    !record?.email ||
    !record.email_confirmed_at ||
    old_record?.email_confirmed_at !== null  // already had confirmation → skip
  ) {
    return Response.json({ ok: true, skipped: true });
  }

  const email = record.email;
  const authUserId = record.id;

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const admin = createClient(supabaseUrl, serviceRoleKey);

  // ── Idempotency: skip if we already sent a welcome to this address ───────
  const { data: existing } = await admin
    .from("email_messages")
    .select("id")
    .eq("to_email", email)
    .contains("metadata", { templateName: "welcome_confirmed" })
    .limit(1)
    .maybeSingle();

  if (existing) {
    return Response.json({ ok: true, skipped: true, reason: "already_sent" });
  }

  // ── Fetch template ────────────────────────────────────────────────────────
  const { data: tpl, error: tplErr } = await admin
    .from("email_templates")
    .select("subject, body_text, body_html, signature_html")
    .eq("name", "welcome_confirmed")
    .single<EmailTemplate>();

  if (tplErr || !tpl) {
    console.error("welcome_confirmed template not found:", tplErr?.message);
    return Response.json(
      { error: "Template welcome_confirmed not found" },
      { status: 500 }
    );
  }

  // ── Personalise: try to get display name from public.users ───────────────
  let displayName: string | null = null;
  try {
    const { data: profile } = await admin
      .from("users")
      .select("full_name, username")
      .eq("auth_user_id", authUserId)
      .maybeSingle();
    displayName = profile?.full_name ?? profile?.username ?? null;
  } catch {
    // non-critical — proceed without name
  }

  // ── Personalise subject / body if we have a name ─────────────────────────
  const subject = tpl.subject;
  const bodyHtml = displayName
    ? tpl.body_html?.replace("{{name}}", escapeHtml(displayName)) ?? tpl.body_html
    : tpl.body_html;
  const bodyText = displayName
    ? tpl.body_text?.replace("{{name}}", displayName) ?? tpl.body_text
    : tpl.body_text;

  const finalHtml = renderEmailHtml({
    title: subject,
    body: bodyHtml ?? (bodyText ? escapeHtml(bodyText).replace(/\n/g, "<br/>") : ""),
    signature: tpl.signature_html,
  });

  // ── Send ─────────────────────────────────────────────────────────────────
  const result = await sendSmtp({
    to: email,
    subject,
    html: finalHtml,
    text: bodyText ?? undefined,
  });

  // ── Log to email_messages ────────────────────────────────────────────────
  await admin.from("email_messages").insert({
    direction: "outbound",
    status: result.ok ? "sent" : "failed",
    from_email: Deno.env.get("EMAIL_FROM") ?? "support@granboulva.com",
    to_email: email,
    subject,
    body_text: bodyText ?? null,
    body_html: finalHtml,
    provider: "smtp",
    provider_id: result.id ?? null,
    error: result.error ?? null,
    metadata: { templateName: "welcome_confirmed", auth_user_id: authUserId },
  });

  if (!result.ok) {
    console.error("Failed to send welcome email:", result.error);
    return Response.json({ error: result.error }, { status: 500 });
  }

  console.log(`Welcome email sent to ${email} (auth_user_id: ${authUserId})`);
  return Response.json({ ok: true, email });
});
