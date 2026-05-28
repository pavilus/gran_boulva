import { NextRequest, NextResponse } from "next/server";
import { sendEmail } from "@/lib/email";

export const runtime = "nodejs";

export async function POST(req: NextRequest) {
  const { name, device, score, feedback, checked, summary } =
    (await req.json()) as {
      name?: string;
      device?: string;
      score?: string;
      feedback?: string;
      checked?: Record<string, boolean>;
      summary?: string;
    };

  const doneCount = Object.values(checked ?? {}).filter(Boolean).length;

  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#07080f;color:#e2e8f0;padding:24px;border-radius:12px">
      <div style="background:linear-gradient(135deg,#1e0a6b,#7c1050);padding:20px;border-radius:10px;margin-bottom:20px">
        <h1 style="margin:0;color:#fff;font-size:20px">📋 Beta Test Checklist — ${name ?? "Testè Enkoni"}</h1>
      </div>
      <table style="width:100%;border-collapse:collapse;margin-bottom:20px">
        <tr>
          <td style="padding:8px 12px;color:#94a3b8;font-size:13px">Testè</td>
          <td style="padding:8px 12px;color:#e2e8f0;font-weight:600">${name ?? "—"}</td>
        </tr>
        <tr style="background:rgba(255,255,255,0.03)">
          <td style="padding:8px 12px;color:#94a3b8;font-size:13px">Aparèy</td>
          <td style="padding:8px 12px;color:#e2e8f0">${device ?? "—"}</td>
        </tr>
        <tr>
          <td style="padding:8px 12px;color:#94a3b8;font-size:13px">Nòt</td>
          <td style="padding:8px 12px;color:#a855f7;font-weight:700;font-size:16px">${score ?? "—"} / 10</td>
        </tr>
        <tr style="background:rgba(255,255,255,0.03)">
          <td style="padding:8px 12px;color:#94a3b8;font-size:13px">Pwogrè</td>
          <td style="padding:8px 12px;color:#22c55e;font-weight:700">${doneCount} seksyon konplè</td>
        </tr>
      </table>
      ${feedback ? `
      <div style="background:rgba(255,255,255,0.05);border-left:3px solid #a855f7;padding:12px 16px;border-radius:0 8px 8px 0;margin-bottom:20px">
        <div style="color:#94a3b8;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px">Kòmantè</div>
        <div style="color:#e2e8f0;font-size:14px;line-height:1.6">${feedback.replace(/\n/g, "<br>")}</div>
      </div>` : ""}
      <details>
        <summary style="color:#475569;font-size:12px;cursor:pointer;margin-bottom:8px">Wè tout checklist la</summary>
        <pre style="background:#080916;padding:12px;border-radius:8px;color:#64748b;font-size:11px;overflow:auto;white-space:pre-wrap">${summary ?? ""}</pre>
      </details>
    </div>
  `;

  await sendEmail({
    to: "g.pavilus@gmail.com",
    subject: `✅ Beta Test — ${name ?? "Testè"} (${doneCount} seksyon, nòt ${score ?? "—"}/10)`,
    html,
    text: summary ?? "",
  });

  return NextResponse.json({ ok: true });
}
