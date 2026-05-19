import Topbar from "@/components/Topbar";
import { createAdminClient } from "@/lib/supabase/admin";
import EmailClient from "./EmailClient";

export default async function EmailPage() {
  const supabase = createAdminClient();

  const [messagesRes, templatesRes, settingsRes] = await Promise.all([
    supabase
      .from("email_messages")
      .select("id, direction, status, from_email, to_email, subject, body_text, body_html, error, created_at")
      .order("created_at", { ascending: false })
      .limit(80),
    supabase
      .from("email_templates")
      .select("id, name, subject, body_text, body_html, signature_html, created_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("email_settings")
      .select("from_email, reply_to, default_signature_html")
      .eq("id", true)
      .maybeSingle(),
  ]);

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title="Email" subtitle="support@granboulva.com" />
      <div className="flex-1 p-5">
        <EmailClient
          messages={messagesRes.data ?? []}
          templates={templatesRes.data ?? []}
          settings={settingsRes.data ?? {
            from_email: "support@granboulva.com",
            reply_to: "support@granboulva.com",
            default_signature_html: null,
          }}
          setupError={messagesRes.error?.message ?? templatesRes.error?.message ?? settingsRes.error?.message ?? null}
        />
      </div>
    </div>
  );
}
