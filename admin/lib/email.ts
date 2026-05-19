type SendEmailInput = {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  from?: string;
  replyTo?: string;
};

type SendEmailResult = {
  ok: boolean;
  provider: "smtp" | "disabled";
  id?: string;
  error?: string;
};

const DEFAULT_FROM = "Gran Boulva <support@granboulva.com>";

export function renderEmailHtml({
  title,
  body,
  signature,
}: {
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
        <h1 style="font-size:22px;line-height:1.25;margin:0 0 16px;color:#111827;">${escapeHtml(title)}</h1>
        <div style="font-size:15px;line-height:1.65;color:#374151;">${body}</div>
        ${signature ? `<div style="border-top:1px solid #e5e7eb;margin-top:24px;padding-top:18px;color:#4b5563;font-size:14px;line-height:1.55;">${signature}</div>` : ""}
      </div>
      <div style="text-align:center;color:#9ca3af;font-size:12px;margin-top:18px;">
        support@granboulva.com
      </div>
    </div>
  </body>
</html>`;
}

export function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export function plainTextToHtml(value: string) {
  return escapeHtml(value).replace(/\n/g, "<br />");
}

export async function sendEmail(input: SendEmailInput): Promise<SendEmailResult> {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT ?? "465");
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    return {
      ok: false,
      provider: "disabled",
      error: "SMTP_HOST, SMTP_USER, and SMTP_PASS must be configured",
    };
  }

  try {
    const nodemailer = eval("require")("nodemailer");
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: String(process.env.SMTP_SECURE ?? "true") !== "false",
      auth: { user, pass },
    });

    const info = await transporter.sendMail({
      from: input.from ?? process.env.EMAIL_FROM ?? DEFAULT_FROM,
      to: input.to,
      subject: input.subject,
      html: input.html,
      text: input.text,
      replyTo: input.replyTo ?? process.env.EMAIL_REPLY_TO ?? "support@granboulva.com",
    });

    return { ok: true, provider: "smtp", id: info.messageId };
  } catch (err) {
    return {
      ok: false,
      provider: "smtp",
      error: err instanceof Error ? err.message : "SMTP send failed",
    };
  }
}
