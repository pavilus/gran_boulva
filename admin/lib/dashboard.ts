import { createAdminClient } from "@/lib/supabase/admin";

export async function getDashboardStats() {
  const supabase = createAdminClient();

  const [
    { count: userCount },
    { count: matchupCount },
    { count: voteCount },
    { count: argCount },
    { count: reportCount },
    { data: coinData },
    { data: revenueData },
    { data: predictionCount },
  ] = await Promise.all([
    supabase.from("users").select("*", { count: "exact", head: true }),
    supabase
      .from("matchups")
      .select("*", { count: "exact", head: true })
      .eq("status", "published"),
    supabase.from("votes").select("*", { count: "exact", head: true }),
    supabase.from("arguments").select("*", { count: "exact", head: true }),
    supabase
      .from("reports")
      .select("*", { count: "exact", head: true })
      .eq("status", "pending")
      .then((r) => ({ count: r.count ?? 0, data: null })),
    supabase
      .from("coin_transactions")
      .select("amount")
      .eq("type", "purchase"),
    supabase
      .from("payments")
      .select("amount")
      .eq("status", "succeeded"),
    supabase
      .from("predictions")
      .select("*", { count: "exact", head: true })
      .then((r) => ({ data: r.count ?? 0 })),
  ]);

  const totalCoins = (coinData ?? []).reduce(
    (sum: number, r: { amount: number }) => sum + (r.amount ?? 0),
    0
  );
  const totalRevenue = (revenueData ?? []).reduce(
    (sum: number, r: { amount: number }) => sum + (r.amount ?? 0),
    0
  );

  return {
    users: userCount ?? 0,
    activeMatchups: matchupCount ?? 0,
    totalVotes: voteCount ?? 0,
    totalArguments: argCount ?? 0,
    pendingReports: reportCount ?? 0,
    totalCoins,
    totalRevenue,
    predictions: typeof predictionCount === "number" ? predictionCount : 0,
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
    .select("id, content_type, reason, reporter:users!reporter_id(username), created_at")
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(5);
  return data ?? [];
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
