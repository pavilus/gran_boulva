import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

// ─── Test data ────────────────────────────────────────────────────────────────

const USERS = [
  { full: "Jean-Baptiste Pierre",   user: "jb_pierre",      loc: "Pòtoprens, Ayiti",    score: 620 },
  { full: "Marie-Flore Dumas",      user: "marie_flore",    loc: "Pòtoprens, Ayiti",    score: 450 },
  { full: "Roody Casimir",          user: "roody_cas",      loc: "Jakmel, Ayiti",        score: 310 },
  { full: "Nadège Bélizaire",       user: "nadege_b",       loc: "Okay, Ayiti",          score: 275 },
  { full: "Kensley Fortuné",        user: "kensley_f",      loc: "Gonayiv, Ayiti",       score: 190 },
  { full: "Régine Joseph",          user: "regine_jo",      loc: "Pòtoprens, Ayiti",    score: 540 },
  { full: "Dieula Moise",           user: "dieula_m",       loc: "Kafou, Ayiti",         score: 88  },
  { full: "Edner Alexandre",        user: "edner_alex",     loc: "Tabarre, Ayiti",       score: 720 },
  { full: "Lovenso Théodore",       user: "lovenso_t",      loc: "Cap-Ayisyen, Ayiti",   score: 412 },
  { full: "Cassandra Hyppolite",    user: "cass_hypp",      loc: "Pòtoprens, Ayiti",    score: 350 },
  { full: "Stéphano Lafortune",     user: "steph_lafo",     loc: "Miami, Florida",       score: 880 },
  { full: "Marc-Kervens Antoine",   user: "mk_antoine",     loc: "Boston, MA",           score: 995 },
  { full: "Sheila Charles",         user: "sheila_ch",      loc: "Brooklyn, NY",         score: 760 },
  { full: "Yves-Richard Thermidor", user: "yves_therm",     loc: "Montréal, QC",         score: 640 },
  { full: "Claudette Pierre-Louis", user: "claudette_pl",   loc: "Pòtoprens, Ayiti",    score: 120 },
  { full: "Judelet Beaumont",       user: "jude_beau",      loc: "Pòtoprens, Ayiti",    score: 205 },
  { full: "Frantzy Boursiquot",     user: "frantzy_b",      loc: "Pòtòprens, Ayiti",    score: 330 },
  { full: "Wisly Saintillus",       user: "wisly_s",        loc: "Gonayiv, Ayiti",       score: 170 },
  { full: "Johny Surpris",          user: "johny_surp",     loc: "Okay, Ayiti",          score: 290 },
  { full: "Fabiola Cadet",          user: "fabiola_c",      loc: "Paris, France",        score: 510 },
];

// Generic Haitian Creole arguments — two sets (favor A, favor B)
const ARGS_A = [
  "Mwen soutni premye opsyon an nèt, paske li reprezante vrè reyalite nou kòm Ayisyen.",
  "Pa gen dout nan mwen, premye chwa a pi solid e pi rezonab pou sitiyasyon nou an.",
  "Kòm yon moun ki grandi nan Ayiti, mwen wè klèman poukisa opsyon A a pi bon.",
  "Eksperyans m te montre m ke chwa premye a bay pi bon rezilta nan kominote nou.",
  "Mwen te reflechi lontan sou sa, e premye opsyon an se sèl chwa ki gen sans.",
  "Lòt opsyon an ka sanble atiran, men premye a pi pratik epi pi reèl pou nou.",
  "Mwen vote pou premye a poutèt li gen plis sipò nan kominote diaspora a tou.",
];

const ARGS_B = [
  "Dezyèm opsyon an pi fò e pi konplè. Mwen dakò ak li san ezitasyon.",
  "Moun ki chwazi lòt la pa wè gwo piblik la vrèman. Dezyèm nan pi enpòtan.",
  "Aprè mwen analize tout bagay, dezyèm opsyon an klèman pi avantageu pou Ayiti.",
  "Kominote a bezwen pran dezyèm chwa a oserye. Li pi solid epi pi adapte.",
  "Nou dwe panse a lavni. Se pou sa mwen chwazi dezyèm opsyon an san ezitasyon.",
  "Premye opsyon an pa mal, men dezyèm nan pi reyèl pou nou ki viv reyalite sa chak jou.",
  "Vwa mwen ale pou dezyèm nan. Li pote plis valè pou kominote nou an.",
];

function randomFrom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomDate(start: Date, end: Date): string {
  const t = start.getTime() + Math.random() * (end.getTime() - start.getTime());
  return new Date(t).toISOString();
}

// ─── Handler ──────────────────────────────────────────────────────────────────

export async function POST() {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const supabase = createAdminClient();
  const results: string[] = [];

  // 1 ── Fetch existing matchups (published + draft)
  const { data: matchups } = await supabase
    .from("matchups")
    .select("id, created_at, published_at, options:matchup_options(id, option_label, vote_count)")
    .in("status", ["published", "draft"])
    .limit(30);

  if (!matchups?.length) {
    return NextResponse.json({ error: "No matchups found. Publish some matchups first." }, { status: 400 });
  }

  results.push(`Found ${matchups.length} matchups`);

  const now = new Date();
  const weekAgo = new Date(now.getTime() - 7 * 86_400_000);

  // 2 ── Create / upsert users (create auth user first, then profile)
  const userProfiles: { id: string }[] = [];

  for (const u of USERS) {
    const email = `${u.user}@seed.granboulva.com`;

    // Try to create auth user (ignore error if already exists)
    const { data: authData } = await supabase.auth.admin.createUser({
      email,
      password: "BoulvaTest2026!",
      email_confirm: true,
      user_metadata: { full_name: u.full },
    });

    const authId = authData?.user?.id;

    // If auth user already exists, look it up
    let resolvedAuthId = authId;
    if (!resolvedAuthId) {
      const { data: { users: existing } } = await supabase.auth.admin.listUsers();
      resolvedAuthId = existing.find((eu) => eu.email === email)?.id;
    }
    if (!resolvedAuthId) continue;

    const { data: profile, error: profileErr } = await supabase
      .from("users")
      .upsert(
        {
          auth_user_id: resolvedAuthId,
          full_name: u.full,
          username: u.user,
          email,
          role: "user",
          location: u.loc,
          language: "ht",
          referral_code: u.user.slice(0, 8).toUpperCase().replace(/_/g, ""),
          influence_score: u.score,
          participation_count: 0,
          victory_count: 0,
          followers_count: Math.floor(Math.random() * 80),
          following_count: Math.floor(Math.random() * 60),
          free_boost_credits: 3,
          coin_balance: Math.floor(Math.random() * 400) + 20,
          total_support_given: 0,
          total_support_received: 0,
          total_coins_spent: 0,
          total_coins_transferred: 0,
          total_boosts_used: 0,
        },
        { onConflict: "username" }
      )
      .select("id")
      .single();

    if (profile && !profileErr) {
      userProfiles.push(profile);
    }
  }

  results.push(`Created/upserted ${userProfiles.length} user profiles`);
  if (userProfiles.length === 0) {
    return NextResponse.json({ error: "No user profiles created", results }, { status: 500 });
  }

  // 3 ── Create votes + arguments per matchup
  let totalVotes = 0;
  let totalArgs = 0;

  for (const matchup of matchups) {
    const optA = (matchup.options as any[]).find((o: any) => o.option_label === "A");
    const optB = (matchup.options as any[]).find((o: any) => o.option_label === "B");
    if (!optA || !optB) continue;

    const matchupStart = matchup.published_at
      ? new Date(Math.max(new Date(matchup.published_at).getTime(), weekAgo.getTime()))
      : weekAgo;

    const voteCountA: Record<string, number> = { [optA.id]: 0, [optB.id]: 0 };

    for (const user of userProfiles) {
      // 70 % chance of voting on each matchup
      if (Math.random() > 0.7) continue;

      // Slight A bias (55 %)
      const chosenOpt = Math.random() < 0.55 ? optA : optB;
      const voteDate = randomDate(matchupStart, now);

      const { error: voteErr } = await supabase.from("votes").upsert(
        {
          user_id: user.id,
          matchup_id: matchup.id,
          option_id: chosenOpt.id,
          vote_changed: false,
          created_at: voteDate,
        },
        { onConflict: "user_id,matchup_id" }
      );

      if (!voteErr) {
        voteCountA[chosenOpt.id]++;
        totalVotes++;
      }

      // 25 % chance of arguing
      if (Math.random() < 0.25) {
        const argBody = chosenOpt.option_label === "A"
          ? randomFrom(ARGS_A)
          : randomFrom(ARGS_B);

        const { error: argErr } = await supabase.from("arguments").insert({
          user_id: user.id,
          matchup_id: matchup.id,
          option_id: chosenOpt.id,
          body: argBody,
          status: "active",
          like_count: Math.floor(Math.random() * 18),
          dislike_count: Math.floor(Math.random() * 5),
          reply_count: Math.floor(Math.random() * 7),
          visibility_score: Math.floor(Math.random() * 100),
          created_at: voteDate,
        });

        if (!argErr) totalArgs++;
      }
    }

    // Update vote_count per option + total_votes on matchup
    const totalForMatchup = voteCountA[optA.id] + voteCountA[optB.id];
    await Promise.all([
      supabase.from("matchup_options")
        .update({ vote_count: (optA.vote_count ?? 0) + voteCountA[optA.id] })
        .eq("id", optA.id),
      supabase.from("matchup_options")
        .update({ vote_count: (optB.vote_count ?? 0) + voteCountA[optB.id] })
        .eq("id", optB.id),
      supabase.from("matchups")
        .update({ total_votes: totalForMatchup })
        .eq("id", matchup.id),
    ]);
  }

  results.push(`Inserted ${totalVotes} votes`);
  results.push(`Inserted ${totalArgs} arguments`);

  return NextResponse.json({ ok: true, results });
}

// Allow GET so it's easy to trigger from the browser address bar too
export async function GET() {
  return POST();
}
