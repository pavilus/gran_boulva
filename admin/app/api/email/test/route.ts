import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { plainTextToHtml, renderEmailHtml, sendEmail } from "@/lib/email";

export async function POST(req: Request) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { to } = await req.json();
  if (!to) return NextResponse.json({ error: "to required" }, { status: 400 });

  const result = await sendEmail({
    to,
    subject: "Gran Boulva email test",
    text: "This is a test email from the Gran Boulva admin panel.",
    html: renderEmailHtml({
      title: "Gran Boulva email test",
      body: plainTextToHtml("This is a test email from the Gran Boulva admin panel."),
      signature: "Gran Boulva Support<br />support@granboulva.com",
    }),
  });

  return NextResponse.json(result.ok ? { ok: true, id: result.id } : { error: result.error }, {
    status: result.ok ? 200 : 500,
  });
}
