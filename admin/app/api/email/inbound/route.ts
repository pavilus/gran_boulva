import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export async function POST(req: Request) {
  const expected = process.env.EMAIL_WEBHOOK_SECRET;
  if (expected) {
    const actual = req.headers.get("x-webhook-secret");
    if (actual !== expected) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
  }

  const payload = await req.json().catch(() => ({}));
  const supabase = createAdminClient();
  const fromEmail = payload.from ?? payload.from_email ?? payload.sender ?? "";
  const toEmail = payload.to ?? payload.to_email ?? "support@granboulva.com";
  const subject = payload.subject ?? "(no subject)";

  const { error } = await supabase.from("email_messages").insert({
    direction: "inbound",
    status: "received",
    from_email: String(fromEmail),
    to_email: Array.isArray(toEmail) ? toEmail.join(", ") : String(toEmail),
    subject: String(subject),
    body_text: payload.text ?? payload.text_body ?? null,
    body_html: payload.html ?? payload.html_body ?? null,
    provider: payload.provider ?? "webhook",
    provider_id: payload.id ?? payload.message_id ?? null,
    metadata: payload,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
