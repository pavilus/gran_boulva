import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

// Load .env.local
const __dir = dirname(fileURLToPath(import.meta.url));
const env = readFileSync(join(__dir, "../.env.local"), "utf8");
for (const line of env.split("\n")) {
  const [k, ...v] = line.split("=");
  if (k?.trim() && !k.startsWith("#")) process.env[k.trim()] = v.join("=").trim();
}

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ─── Data ─────────────────────────────────────────────────────────────────────

const USERS = [
  { full: "Jean-Baptiste Pierre",   user: "jb_pierre",      loc: "Pòtoprens, Ayiti",   score: 620 },
  { full: "Marie-Flore Dumas",      user: "marie_flore",    loc: "Pòtoprens, Ayiti",   score: 450 },
  { full: "Roody Casimir",          user: "roody_cas",      loc: "Jakmel, Ayiti",       score: 310 },
  { full: "Nadège Bélizaire",       user: "nadege_b",       loc: "Okay, Ayiti",         score: 275 },
  { full: "Kensley Fortuné",        user: "kensley_f",      loc: "Gonayiv, Ayiti",      score: 190 },
  { full: "Régine Joseph",          user: "regine_jo",      loc: "Pòtoprens, Ayiti",   score: 540 },
  { full: "Dieula Moise",           user: "dieula_m",       loc: "Kafou, Ayiti",        score: 88  },
  { full: "Edner Alexandre",        user: "edner_alex",     loc: "Tabarre, Ayiti",      score: 720 },
  { full: "Lovenso Théodore",       user: "lovenso_t",      loc: "Cap-Ayisyen, Ayiti",  score: 412 },
  { full: "Cassandra Hyppolite",    user: "cass_hypp",      loc: "Pòtoprens, Ayiti",   score: 350 },
  { full: "Stéphano Lafortune",     user: "steph_lafo",     loc: "Miami, Florida",      score: 880 },
  { full: "Marc-Kervens Antoine",   user: "mk_antoine",     loc: "Boston, MA",          score: 995 },
  { full: "Sheila Charles",         user: "sheila_ch",      loc: "Brooklyn, NY",        score: 760 },
  { full: "Yves-Richard Thermidor", user: "yves_therm",     loc: "Montréal, QC",        score: 640 },
  { full: "Claudette Pierre-Louis", user: "claudette_pl",   loc: "Pòtoprens, Ayiti",   score: 120 },
  { full: "Judelet Beaumont",       user: "jude_beau",      loc: "Pòtoprens, Ayiti",   score: 205 },
  { full: "Frantzy Boursiquot",     user: "frantzy_b",      loc: "Pòtòprens, Ayiti",   score: 330 },
  { full: "Wisly Saintillus",       user: "wisly_s",        loc: "Gonayiv, Ayiti",      score: 170 },
  { full: "Johny Surpris",          user: "johny_surp",     loc: "Okay, Ayiti",         score: 290 },
  { full: "Fabiola Cadet",          user: "fabiola_c",      loc: "Paris, France",       score: 510 },
];

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

const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randDate = (start, end) =>
  new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime())).toISOString();

// ─── Main ─────────────────────────────────────────────────────────────────────

console.log("🌱 Gran Boulva seed script starting…\n");

// 1. Fetch matchups
const { data: matchups, error: mErr } = await supabase
  .from("matchups")
  .select("id, created_at, published_at, options:matchup_options(id, option_label, vote_count)")
  .in("status", ["published", "draft"])
  .limit(30);

if (mErr) { console.error("Error fetching matchups:", mErr.message); process.exit(1); }
console.log(`✓ Found ${matchups.length} matchups`);

// 2. Create users
const profiles = [];
for (const u of USERS) {
  const email = `${u.user}@seed.granboulva.com`;
  process.stdout.write(`  Creating @${u.user}… `);

  // Create auth user (might already exist — that's OK)
  let authId;
  const { data: authData } = await supabase.auth.admin.createUser({
    email,
    password: "BoulvaTest2026!",
    email_confirm: true,
    user_metadata: { full_name: u.full },
  });
  authId = authData?.user?.id;

  // If already exists, find it
  if (!authId) {
    const { data: { users: existing } } = await supabase.auth.admin.listUsers({ perPage: 500 });
    authId = existing?.find((eu) => eu.email === email)?.id;
  }

  if (!authId) { console.log("skip (no auth id)"); continue; }

  const { data: profile, error: pErr } = await supabase
    .from("users")
    .upsert(
      {
        auth_user_id: authId,
        full_name: u.full,
        username: u.user,
        email,
        role: "user",
        location: u.loc,
        language: "ht",
        referral_code: (u.user.slice(0, 8).toUpperCase().replace(/_/g, "") + "2026").slice(0, 12),
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

  if (pErr) { console.log(`error: ${pErr.message}`); continue; }
  profiles.push(profile);
  console.log("✓");
}

console.log(`\n✓ ${profiles.length} user profiles ready\n`);

// 3. Votes + arguments
const now = new Date();
const weekAgo = new Date(now.getTime() - 7 * 86_400_000);

let totalVotes = 0;
let totalArgs = 0;

for (const matchup of matchups) {
  const optA = matchup.options.find((o) => o.option_label === "A");
  const optB = matchup.options.find((o) => o.option_label === "B");
  if (!optA || !optB) continue;

  const matchupStart = matchup.published_at
    ? new Date(Math.max(new Date(matchup.published_at).getTime(), weekAgo.getTime()))
    : weekAgo;

  let countA = 0, countB = 0;

  for (const user of profiles) {
    if (Math.random() > 0.72) continue; // ~72 % voting rate

    const chosenOpt = Math.random() < 0.54 ? optA : optB;
    const voteDate = randDate(matchupStart, now);

    const { error: vErr } = await supabase.from("votes").upsert(
      { user_id: user.id, matchup_id: matchup.id, option_id: chosenOpt.id, vote_changed: false, created_at: voteDate },
      { onConflict: "user_id,matchup_id" }
    );

    if (!vErr) {
      chosenOpt.option_label === "A" ? countA++ : countB++;
      totalVotes++;
    }

    if (Math.random() < 0.28) {
      const body = chosenOpt.option_label === "A" ? rand(ARGS_A) : rand(ARGS_B);
      const { error: aErr } = await supabase.from("arguments").insert({
        user_id: user.id,
        matchup_id: matchup.id,
        option_id: chosenOpt.id,
        body,
        status: "active",
        like_count: Math.floor(Math.random() * 20),
        dislike_count: Math.floor(Math.random() * 6),
        reply_count: Math.floor(Math.random() * 8),
        visibility_score: Math.floor(Math.random() * 100),
        created_at: voteDate,
      });
      if (!aErr) totalArgs++;
    }
  }

  // Update counts
  const total = countA + countB;
  await Promise.all([
    supabase.from("matchup_options").update({ vote_count: (optA.vote_count ?? 0) + countA }).eq("id", optA.id),
    supabase.from("matchup_options").update({ vote_count: (optB.vote_count ?? 0) + countB }).eq("id", optB.id),
    supabase.from("matchups").update({ total_votes: total }).eq("id", matchup.id),
  ]);

  process.stdout.write(".");
}

console.log(`\n\n✓ ${totalVotes} votes inserted`);
console.log(`✓ ${totalArgs} arguments inserted`);
console.log("\n🎉 Seed complete! Refresh the admin panel to see data.\n");
