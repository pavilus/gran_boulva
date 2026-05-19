import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { plainTextToHtml, renderEmailHtml, sendEmail } from "@/lib/email";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { to, subject, body, html, signature, templateName } = await req.json();
  if (!to || !subject || (!body && !html)) {
    return NextResponse.json({ error: "to, subject, and body/html are required" }, { status: 400 });
  }

  const recipients = Array.isArray(to)
    ? to.map(String).filter(Boolean)
    : String(to).split(",").map((v) => v.trim()).filter(Boolean);
  if (recipients.length === 0) {
    return NextResponse.json({ error: "At least one recipient is required" }, { status: 400 });
  }

  const supabase = createAdminClient();
  const finalHtml = renderEmailHtml({
    title: subject,
    body: html ?? plainTextToHtml(body),
    signature,
  });

  const result = await sendEmail({
    to: recipients,
    subject,
    html: finalHtml,
    text: body,
  });

  await supabase.from("email_messages").insert({
    direction: "outbound",
    status: result.ok ? "sent" : "failed",
    from_email: "support@granboulva.com",
    to_email: recipients.join(", "),
    subject,
    body_text: body ?? null,
    body_html: finalHtml,
    provider: result.provider,
    provider_id: result.id ?? null,
    error: result.error ?? null,
    metadata: { templateName: templateName ?? null },
  });

  const { data: admins } = await supabase
    .from("users")
    .select("id")
    .in("role", ["admin", "owner", "moderator"]);

  if (admins?.length) {
    await supabase.from("notifications").insert(
      admins.map((u) => ({
        user_id: u.id,
        type: result.ok ? "system" : "email_failed",
        title: result.ok ? "Email sent" : "Email failed",
        body: result.ok ? `${subject} sent to ${recipients.length} recipient(s).` : result.error,
        is_read: false,
      }))
    );
  }

  return NextResponse.json(result.ok ? { ok: true, id: result.id } : { error: result.error }, {
    status: result.ok ? 200 : 500,
  });
}
