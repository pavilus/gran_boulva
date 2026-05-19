import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { plainTextToHtml, renderEmailHtml, sendEmail } from "@/lib/email";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { title, body, type, sendEmail: shouldSendEmail } = await req.json();
  if (!title) return NextResponse.json({ error: "title required" }, { status: 400 });

  const supabase = createAdminClient();

  // Fetch all user IDs
  const { data: users, error: usersErr } = await supabase
    .from("users")
    .select("id, email");
  if (usersErr) return NextResponse.json({ error: usersErr.message }, { status: 500 });

  if (!users || users.length === 0) return NextResponse.json({ ok: true, count: 0 });

  // Batch insert notifications for all users
  const rows = users.map((u) => ({
    user_id: u.id,
    type: type ?? "announcement",
    title,
    body: body || null,
    is_read: false,
  }));

  // Insert in batches of 500
  const BATCH = 500;
  let inserted = 0;
  for (let i = 0; i < rows.length; i += BATCH) {
    const { error } = await supabase.from("notifications").insert(rows.slice(i, i + BATCH));
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    inserted += Math.min(BATCH, rows.length - i);
  }

  let emailResult: { sent: number; error?: string } | undefined;
  if (shouldSendEmail) {
    const recipients = users.map((u) => u.email).filter(Boolean) as string[];
    const result = await sendEmail({
      to: recipients,
      subject: title,
      text: body ?? title,
      html: renderEmailHtml({
        title,
        body: plainTextToHtml(body || title),
        signature: "Gran Boulva Support<br />support@granboulva.com",
      }),
    });
    emailResult = result.ok ? { sent: recipients.length } : { sent: 0, error: result.error };
  }

  return NextResponse.json({ ok: true, count: inserted, email: emailResult, id: Date.now().toString() });
}
