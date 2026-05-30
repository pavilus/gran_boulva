import { createAdminClient } from "@/lib/supabase/admin";

function pctChange(curr: number, prev: number): number {
  if (prev === 0) return curr > 0 ? 100 : 0;
  return Math.round(((curr - prev) / prev) * 1000) / 10;
}

export async function getDashboardStats() {
  const supabase = createAdminClient();

  const now = new Date();
  const weekAgo = new Date(now);
  weekAgo.setDate(weekAgo.getDate() - 7);
  const twoWeeksAgo = new Date(now);
  twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
  const isoWeekAgo = weekAgo.toISOString();
  const isoTwoWeeksAgo = twoWeeksAgo.toISOString();

  const [
    { count: userCount },
    { count: matchupCount },
    { count: voteCount },
    { count: argCount },
    { count: reportCount },
    { data: coinData },
    { data: revenueData },
    { data: predictionCount },
    // Week-over-week for real % change
    { count: usersThisWeek },
    { count: usersPrevWeek },
    { count: votesThisWeek },
    { count: votesPrevWeek },
    { count: argsThisWeek },
    { count: argsPrevWeek },
    { data: revThisWeek },
    { data: revPrevWeek },
    { data: supporterData },
    { data: supporterThisWeek },
    { data: supporterPrevWeek },
  ] = await Promise.all([
    supabase.from("users").select("*", { count: "exact", head: true }),
    supabase.from("matchups").select("*", { count: "exact", head: true }).eq("status", "published"),
    supabase.from("votes").select("*", { count: "exact", head: true }),
    supabase.from("arguments").select("*", { count: "exact", head: true }),
    supabase.from("reports").select("*", { count: "exact", head: true }).eq("status", "pending").then((r) => ({ count: r.count ?? 0, data: null })),
    supabase.from("coin_purchases").select("coin_amount").eq("status", "succeeded"),
    supabase.from("coin_purchases").select("usd_cents").eq("status", "succeeded"),
    supabase.from("predictions").select("*", { count: "exact", head: true }).then((r) => ({ data: r.count ?? 0 })),
    supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", isoWeekAgo),
    supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", isoTwoWeeksAgo).lt("created_at", isoWeekAgo),
    supabase.from("votes").select("*", { count: "exact", head: true }).gte("created_at", isoWeekAgo),
    supabase.from("votes").select("*", { count: "exact", head: true }).gte("created_at", isoTwoWeeksAgo).lt("created_at", isoWeekAgo),
    supabase.from("arguments").select("*", { count: "exact", head: true }).gte("created_at", isoWeekAgo),
    supabase.from("arguments").select("*", { count: "exact", head: true }).gte("created_at", isoTwoWeeksAgo).lt("created_at", isoWeekAgo),
    supabase.from("coin_purchases").select("usd_cents").eq("status", "succeeded").gte("created_at", isoWeekAgo),
    supabase.from("coin_purchases").select("usd_cents").eq("status", "succeeded").gte("created_at", isoTwoWeeksAgo).lt("created_at", isoWeekAgo),
    // Founding supporter payments from waitlist
    supabase.from("waitlist").select("amount_cents, created_at").eq("is_supporter", true).not("amount_cents", "is", null),
    supabase.from("waitlist").select("amount_cents, created_at").eq("is_supporter", true).not("amount_cents", "is", null).gte("created_at", isoWeekAgo),
    supabase.from("waitlist").select("amount_cents, created_at").eq("is_supporter", true).not("amount_cents", "is", null).gte("created_at", isoTwoWeeksAgo).lt("created_at", isoWeekAgo),
  ]);

  const totalCoins = (coinData ?? []).reduce(
    (sum: number, r: { coin_amount: number }) => sum + (r.coin_amount ?? 0),
    0
  );
  const coinRevenue = (revenueData ?? []).reduce((sum: number, r: { usd_cents: number }) => sum + (r.usd_cents ?? 0), 0);
  const supporterRevenue = (supporterData ?? []).reduce((sum: number, r: { amount_cents: number }) => sum + (r.amount_cents ?? 0), 0);
  const totalCoinRevenue    = coinRevenue / 100;
  const totalSupporterRevenue = supporterRevenue / 100;
  const totalRevenue        = totalCoinRevenue + totalSupporterRevenue;

  const revThisTotal = (revThisWeek ?? []).reduce((s: number, r: { usd_cents: number }) => s + (r.usd_cents ?? 0), 0)
    + (supporterThisWeek ?? []).reduce((s: number, r: { amount_cents: number }) => s + (r.amount_cents ?? 0), 0);
  const revPrevTotal = (revPrevWeek ?? []).reduce((s: number, r: { usd_cents: number }) => s + (r.usd_cents ?? 0), 0)
    + (supporterPrevWeek ?? []).reduce((s: number, r: { amount_cents: number }) => s + (r.amount_cents ?? 0), 0);

  return {
    users: userCount ?? 0,
    activeMatchups: matchupCount ?? 0,
    totalVotes: voteCount ?? 0,
    totalArguments: argCount ?? 0,
    pendingReports: reportCount ?? 0,
    totalCoins,
    totalRevenue,
    totalCoinRevenue,
    totalSupporterRevenue,
    predictions: typeof predictionCount === "number" ? predictionCount : 0,
    usersChange: pctChange(usersThisWeek ?? 0, usersPrevWeek ?? 0),
    votesChange: pctChange(votesThisWeek ?? 0, votesPrevWeek ?? 0),
    argsChange: pctChange(argsThisWeek ?? 0, argsPrevWeek ?? 0),
    revenueChange: pctChange(revThisTotal, revPrevTotal),
  };
}

export async function getRecentMatchups() {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("matchups")
    .select(`
      id, title_ht, status, published_at,
      category:categories(name_ht),
      options:matchup_options(id, option_name, vote_count)
    `)
    .order("published_at", { ascending: false })
    .limit(5);
  return data ?? [];
}

export async function getScoutDrafts() {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("ai_generated_drafts")
    .select("id, title_ht, combined_score, risk_level, status, category:categories(name_ht)")
    .eq("status", "pending")
    .order("combined_score", { ascending: false })
    .limit(5);
  return data ?? [];
}

export async function getRecentReports() {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("reports")
    .select("id, reported_type, reason, created_at")
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(5);
  return (data ?? []).map((report) => ({
    ...report,
    content_type: report.reported_type,
    reporter: null,
  }));
}

export async function getRevenueSeries() {
  const supabase = createAdminClient();
  const since = new Date();
  since.setDate(since.getDate() - 6);
  const isoSince = since.toISOString();

  const [{ data: coinData }, { data: supporterData }] = await Promise.all([
    supabase.from("coin_purchases").select("usd_cents, created_at").eq("status", "succeeded").gte("created_at", isoSince),
    supabase.from("waitlist").select("amount_cents, created_at").eq("is_supporter", true).not("amount_cents", "is", null).gte("created_at", isoSince),
  ]);

  const days: Record<string, { coinRevenue: number; supporterRevenue: number }> = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    days[key] = { coinRevenue: 0, supporterRevenue: 0 };
  }

  (coinData ?? []).forEach((r: { usd_cents: number; created_at: string }) => {
    const key = new Date(r.created_at).toLocaleDateString("en-US", { month: "short", day: "numeric" });
    if (key in days) days[key].coinRevenue += (r.usd_cents ?? 0) / 100;
  });
  (supporterData ?? []).forEach((r: { amount_cents: number; created_at: string }) => {
    const key = new Date(r.created_at).toLocaleDateString("en-US", { month: "short", day: "numeric" });
    if (key in days) days[key].supporterRevenue += (r.amount_cents ?? 0) / 100;
  });

  return Object.entries(days).map(([day, v]) => ({ day, ...v }));
}

export async function getActivitySeries() {
  const supabase = createAdminClient();
  const since = new Date();
  since.setDate(since.getDate() - 6);
  const isoSince = since.toISOString();

  const [{ data: votes }, { data: args }] = await Promise.all([
    supabase
      .from("votes")
      .select("created_at")
      .gte("created_at", isoSince),
    supabase
      .from("arguments")
      .select("created_at")
      .gte("created_at", isoSince),
  ]);

  const days: Record<string, { votes: number; arguments: number }> = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    days[key] = { votes: 0, arguments: 0 };
  }

  (votes ?? []).forEach((v: { created_at: string }) => {
    const key = new Date(v.created_at).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });
    if (days[key]) days[key].votes++;
  });

  (args ?? []).forEach((a: { created_at: string }) => {
    const key = new Date(a.created_at).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    });
    if (days[key]) days[key].arguments++;
  });

  return Object.entries(days).map(([day, counts]) => ({ day, ...counts }));
}
