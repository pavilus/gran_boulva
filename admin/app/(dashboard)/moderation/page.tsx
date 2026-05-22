import { createAdminClient } from "@/lib/supabase/admin";
import Topbar from "@/components/Topbar";
import ModerationList from "./ModerationList";

export default async function ModerationPage() {
  const supabase = createAdminClient();

  const [{ data: args }, { data: reports }] = await Promise.all([
    supabase
      .from("arguments")
      .select("id, body, status, like_count, dislike_count, reply_count, created_at, matchup_id, user_id, option_id, matchup:matchups(title_ht), user:users(username, avatar_url)")
      .order("created_at", { ascending: false })
      .limit(200),
    supabase
      .from("reports")
      .select("id, reported_id, reason, created_at")
      .eq("reported_type", "argument")
      .eq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(500),
  ]);

  const reportsByArgument = new Map<string, { count: number; reasons: string[]; latest?: string }>();
  for (const report of reports ?? []) {
    if (!report.reported_id) continue;
    const current = reportsByArgument.get(report.reported_id) ?? { count: 0, reasons: [] };
    current.count += 1;
    if (report.reason && !current.reasons.includes(report.reason)) current.reasons.push(report.reason);
    current.latest ??= report.created_at;
    reportsByArgument.set(report.reported_id, current);
  }

  const moderationArgs = (args ?? []).map((argument) => {
    const report = reportsByArgument.get(argument.id);
    return {
      ...argument,
      report_count: report?.count ?? 0,
      report_reasons: report?.reasons ?? [],
      latest_report_at: report?.latest ?? null,
    };
  });

  const reportedCount = moderationArgs.filter((a) => a.report_count > 0).length;
  const flaggedCount = moderationArgs.filter((a) => a.status === "flagged").length;

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar
        title="Agiman & Modération"
        subtitle={
          reportedCount > 0
            ? `${reportedCount} agiman rapòte k ap tann revizyon`
            : flaggedCount > 0
              ? `${flaggedCount} flagged`
              : undefined
        }
      />
      <div className="flex-1 p-5">
        <ModerationList args={moderationArgs} />
      </div>
    </div>
  );
}
