import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const adminRoles = new Set(["admin", "owner", "moderator"]);

async function requireAdminRequest(req: Request, supabaseUrl: string, anonKey: string, serviceKey: string) {
  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) {
    return Response.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

  if (token === serviceKey) return null;

  const sessionClient = createClient(supabaseUrl, anonKey);
  const {
    data: { user },
    error: userError,
  } = await sessionClient.auth.getUser(token);

  if (userError || !user) {
    return Response.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: profile, error: profileError } = await admin
    .from("users")
    .select("role")
    .eq("auth_user_id", user.id)
    .maybeSingle();

  if (profileError || !profile || !adminRoles.has(profile.role)) {
    return Response.json({ error: "Forbidden" }, { status: 403, headers: cors });
  }

  return null;
}

// ─── OpenAI helpers ────────────────────────────────────────────────────────────

async function searchWeb(openaiKey: string, query: string): Promise<{ content: string; urls: string[] }> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${openaiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-search-preview",
      messages: [{ role: "user", content: query }],
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI search error: ${err}`);
  }
  const data = await res.json();
  const message = data.choices?.[0]?.message ?? {};
  const content: string = message.content ?? "";
  const urls: string[] = (message.annotations ?? [])
    .filter((a: any) => a.type === "url_citation" && a.url)
    .map((a: any) => a.url as string);
  return { content, urls };
}

async function generateStructured(openaiKey: string, prompt: string): Promise<any> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${openaiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o",
      response_format: { type: "json_object" },
      temperature: 0.7,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!res.ok) throw new Error(`OpenAI error: ${await res.text()}`);
  const data = await res.json();
  return JSON.parse(data.choices?.[0]?.message?.content ?? "{}");
}

// ─── Deduplication ────────────────────────────────────────────────────────────

function titleWords(title: string): Set<string> {
  return new Set(
    title
      .toLowerCase()
      .replace(/[^a-z0-9À-ɏ\s]/g, "")
      .split(/\s+/)
      .filter((w) => w.length > 3)
  );
}

function isTooSimilar(newTitle: string, existingTitles: string[]): boolean {
  const newWords = titleWords(newTitle);
  if (newWords.size === 0) return false;
  for (const existing of existingTitles) {
    const exWords = titleWords(existing);
    let shared = 0;
    for (const w of newWords) if (exWords.has(w)) shared++;
    if (shared / Math.max(newWords.size, exWords.size) > 0.5) return true;
  }
  return false;
}

// ─── Main handler ──────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey      = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const openaiKey   = Deno.env.get("OPENAI_API_KEY") ?? "";

    const forbidden = await requireAdminRequest(req, supabaseUrl, anonKey, serviceKey);
    if (forbidden) return forbidden;

    if (!openaiKey) {
      return Response.json({ error: "OPENAI_API_KEY not set" }, { status: 500, headers: cors });
    }

    const admin = createClient(supabaseUrl, serviceKey);

    // ── Gather context from DB ─────────────────────────────────────────────────
    const [{ data: categories }, { data: existingMatchups }, { data: existingPredictions }, { data: recentDrafts }] = await Promise.all([
      admin.from("categories").select("id, name_ht, name_en").limit(20),
      admin.from("matchups").select("title_ht").order("created_at", { ascending: false }).limit(200),
      admin.from("predictions").select("title_ht").order("created_at", { ascending: false }).limit(200),
      admin.from("ai_generated_drafts").select("title_ht").order("created_at", { ascending: false }).limit(200),
    ]);

    const catList = (categories ?? []).map((c: any) => `${c.name_ht} (${c.name_en})`).join(", ");
    const catMap: Record<string, string> = {};
    for (const c of (categories ?? []) as any[]) {
      catMap[c.name_ht.toLowerCase()] = c.id;
      catMap[(c.name_en ?? "").toLowerCase()] = c.id;
    }

    const allExistingTitles: string[] = [
      ...(existingMatchups ?? []).map((m: any) => m.title_ht),
      ...(existingPredictions ?? []).map((p: any) => p.title_ht),
      ...(recentDrafts ?? []).map((d: any) => d.title_ht),
    ].filter(Boolean);

    // ── Phase 1: 3 parallel real-time web searches ────────────────────────────
    const today = new Date().toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" });

    const [newsSearch, socialSearch, sportsSearch] = await Promise.allSettled([
      searchWeb(openaiKey,
        `As of ${today}, what are the most discussed and controversial news stories, political debates, cultural controversies, and viral topics related to Haiti and Haitians in the last 72 hours? ` +
        `Search: Le Nouvelliste, AyiboPost, Gazette Haiti, Loop Haiti, HaitiLibre, AlterPresse, Juno7, Vant Bèf Info, Haitian Times. ` +
        `Also check X/Twitter Haitian hashtags and Facebook Haitian public pages. ` +
        `List 12 specific, debatable topics with: headline, why it's controversial, engagement level, key people/entities involved, source.`
      ),
      searchWeb(openaiKey,
        `As of ${today}, what are the most trending Haitian music, entertainment, and cultural debates? ` +
        `Search for: new Haitian music releases, artist controversies, kompa vs rap kreyòl debates, viral Haitian TikTok/YouTube content, ` +
        `Haitian celebrity drama, diaspora community discussions on social media. ` +
        `List 10 specific viral topics with entities, engagement, and source.`
      ),
      searchWeb(openaiKey,
        `As of ${today}, what are current Haitian sports news, predictions, and debates? ` +
        `Haiti national football team results and upcoming matches, Haitian players in MLS/international leagues, ` +
        `Haitian athletes in NBA/NFL/boxing, local Haitian league standings, sports rivalries, player transfers, ` +
        `coach decisions, sports controversies, youth sports, kompa vs rap debate in sports circles. ` +
        `Also: political elections timelines, economic predictions, social outcome uncertainties for Haiti. ` +
        `List 15 specific debate-worthy or prediction-worthy topics with context and source.`
      ),
    ]);

    const allContent: string[] = [];
    const allUrls: string[] = [];

    for (const result of [newsSearch, socialSearch, sportsSearch]) {
      if (result.status === "fulfilled") {
        allContent.push(result.value.content);
        allUrls.push(...result.value.urls);
      }
    }

    if (allContent.length === 0) {
      return Response.json({ error: "All web searches failed" }, { status: 500, headers: cors });
    }

    const uniqueUrls = [...new Set(allUrls)].slice(0, 20);
    const combinedResearch = allContent.join("\n\n---\n\n");

    // ── Phase 2: Matchups + Predictions generation (parallel) ─────────────────
    const existingBlock = allExistingTitles.length > 0
      ? `\n\nEXISTING TITLES TO AVOID (check uniqueness against ALL of these):\n${allExistingTitles.slice(0, 150).map((t, i) => `${i + 1}. ${t}`).join("\n")}`
      : "";

    const matchupPrompt = `You are the Boulva Scout AI — a cultural trend radar for Gran Boulva, a Haitian Creole debate platform.

REAL-TIME RESEARCH FINDINGS (from web searches completed ${today}):
${combinedResearch}

AVAILABLE CATEGORIES: ${catList}
${existingBlock}

TASK: Generate exactly 25 matchup debate ideas based on the real research above.

REQUIREMENTS:
- Each matchup MUST be inspired by actual current events/trends from the research
- Exactly 2 options per matchup (A vs B)
- Written in natural, conversational Haitian Creole
- Culturally authentic — not generic or generic AI-sounding
- Fresh: NOT repeating or closely resembling ANY existing title above
- Never defamatory, hateful, or based on rumors

SCORING (0-10 each):
- popularity_score: How widely discussed is this topic right now?
- recency_score: How recent/breaking is this topic? (last 24h = 10, last week = 6, older = lower)
- debate_score: How strongly will people disagree on this?
- virality_score: How fast is engagement growing on this topic?
- uniqueness_score: How different is this from existing matchups? (check the list above strictly)
- relevance_score: How relevant to Haitian/diaspora community?
- safety_score: How safe for moderation? (10 = totally safe, 0 = dangerous)
- prediction_score: Does this have a future outcome people can predict?

combined_score = (popularity_score * 0.15 + recency_score * 0.15 + debate_score * 0.2 + virality_score * 0.1 + uniqueness_score * 0.15 + relevance_score * 0.15 + safety_score * 0.1)

Return a JSON object:
{
  "matchups": [
    {
      "title_ht": "Question in authentic Haitian Creole",
      "title_en": "English translation",
      "option_a": "First option name",
      "option_b": "Second option name",
      "description_ht": "1-2 sentence context in Haitian Creole explaining why this is relevant NOW",
      "category": "exact category name_ht from available list",
      "source_platform": "primary platform where found",
      "trending_keywords": ["keyword1", "keyword2", "keyword3"],
      "detected_entities": ["Person/Place/Org 1", "Person/Place/Org 2"],
      "selection_reason": "1 sentence: why this topic is debate-worthy RIGHT NOW",
      "popularity_score": 8.5,
      "recency_score": 9.0,
      "debate_score": 8.5,
      "virality_score": 7.5,
      "uniqueness_score": 9.0,
      "relevance_score": 9.5,
      "safety_score": 8.5,
      "prediction_score": 6.0,
      "risk_level": "low"
    }
  ]
}`;

    const predictionPrompt = `You are the Boulva Scout AI — a cultural trend radar for Gran Boulva, a Haitian Creole prediction platform.

REAL-TIME RESEARCH FINDINGS (from web searches completed ${today}):
${combinedResearch}

AVAILABLE CATEGORIES: ${catList}
${existingBlock}

TASK: Generate exactly 15 prediction questions based on current Haitian events. A prediction is a question about a FUTURE outcome that users can vote on before a deadline.

REQUIREMENTS:
- Each prediction MUST be grounded in a real current event with an uncertain future outcome
- Written in natural Haitian Creole
- Must have exactly 2 outcome options (option_a and option_b)
- deadline_at: ISO date string (YYYY-MM-DD) — when the outcome will be known; set between 2 weeks and 6 months from ${today}
- Not repeating any existing title above
- Examples of good predictions: election results, sports match outcomes, economic forecasts, celebrity decisions, political moves
- Never defamatory or based on rumors

SCORING (0-10 each): same as matchups but prediction_score should be high (7+) since these are all predictions.

Return a JSON object:
{
  "predictions": [
    {
      "title_ht": "Prediction question in authentic Haitian Creole (e.g. 'Eske Haiti pral...?')",
      "title_en": "English translation",
      "option_a": "First outcome option",
      "option_b": "Second outcome option",
      "description_ht": "1-2 sentence context explaining the situation and why it's uncertain",
      "category": "exact category name_ht from available list",
      "source_platform": "primary platform where found",
      "trending_keywords": ["keyword1", "keyword2"],
      "detected_entities": ["Person/Place/Org 1"],
      "selection_reason": "1 sentence: why this is a meaningful prediction right now",
      "deadline_at": "2026-08-01",
      "popularity_score": 8.0,
      "recency_score": 8.5,
      "debate_score": 7.0,
      "virality_score": 7.0,
      "uniqueness_score": 9.0,
      "relevance_score": 9.0,
      "safety_score": 8.5,
      "prediction_score": 9.0,
      "risk_level": "low"
    }
  ]
}`;

    const [matchupResult, predictionResult] = await Promise.allSettled([
      generateStructured(openaiKey, matchupPrompt),
      generateStructured(openaiKey, predictionPrompt),
    ]);

    // ── Phase 3: Filter, deduplicate, and insert ──────────────────────────────
    const insertedTitles: string[] = [...allExistingTitles];
    const rows: any[] = [];

    // Process matchups
    const matchups: any[] = matchupResult.status === "fulfilled" ? (matchupResult.value.matchups ?? []) : [];
    for (const m of matchups) {
      if ((m.uniqueness_score ?? 0) < 6 || (m.safety_score ?? 0) < 5) continue;
      if (isTooSimilar(m.title_ht, insertedTitles)) continue;
      insertedTitles.push(m.title_ht);

      const catKey = (m.category ?? "").toLowerCase();
      const ps = Number(m.popularity_score ?? 5);
      const rs = Number(m.recency_score ?? 5);
      const ds = Number(m.debate_score ?? 5);
      const vs = Number(m.virality_score ?? 5);
      const us = Number(m.uniqueness_score ?? 5);
      const rels = Number(m.relevance_score ?? 5);
      const ss = Number(m.safety_score ?? 7);
      const preds = Number(m.prediction_score ?? 5);
      const combined = Math.round((ps * 0.15 + rs * 0.15 + ds * 0.2 + vs * 0.1 + us * 0.15 + rels * 0.15 + ss * 0.1) * 10) / 10;

      rows.push({
        type: "matchup",
        category_id: catMap[catKey] ?? null,
        title_ht: m.title_ht,
        title_en: m.title_en ?? null,
        option_a: m.option_a,
        option_b: m.option_b,
        description_ht: m.description_ht ?? null,
        source_links: uniqueUrls.slice(0, 5),
        source_platform: m.source_platform ?? null,
        trending_keywords: m.trending_keywords ?? [],
        detected_entities: m.detected_entities ?? [],
        selection_reason: m.selection_reason ?? null,
        popularity_score: ps,
        trend_score: rs,
        debate_score: ds,
        virality_score: vs,
        uniqueness_score: us,
        relevance_score: rels,
        safety_score: ss,
        prediction_score: preds,
        combined_score: combined,
        risk_level: m.risk_level ?? "low",
        status: "pending",
      });
    }

    // Process predictions
    const predictions: any[] = predictionResult.status === "fulfilled" ? (predictionResult.value.predictions ?? []) : [];
    for (const p of predictions) {
      if ((p.uniqueness_score ?? 0) < 6 || (p.safety_score ?? 0) < 5) continue;
      if (isTooSimilar(p.title_ht, insertedTitles)) continue;
      insertedTitles.push(p.title_ht);

      const catKey = (p.category ?? "").toLowerCase();
      const ps2 = Number(p.popularity_score ?? 5);
      const rs2 = Number(p.recency_score ?? 5);
      const ds2 = Number(p.debate_score ?? 5);
      const vs2 = Number(p.virality_score ?? 5);
      const us2 = Number(p.uniqueness_score ?? 5);
      const rels2 = Number(p.relevance_score ?? 5);
      const ss2 = Number(p.safety_score ?? 7);
      const preds2 = Number(p.prediction_score ?? 7);
      const combined2 = Math.round((ps2 * 0.15 + rs2 * 0.15 + ds2 * 0.2 + vs2 * 0.1 + us2 * 0.15 + rels2 * 0.15 + ss2 * 0.1) * 10) / 10;

      // Parse deadline (YYYY-MM-DD → timestamptz)
      let deadlineAt: string | null = null;
      if (p.deadline_at) {
        const parsed = new Date(`${p.deadline_at}T00:00:00Z`);
        if (!isNaN(parsed.getTime())) deadlineAt = parsed.toISOString();
      }

      rows.push({
        type: "prediction",
        category_id: catMap[catKey] ?? null,
        title_ht: p.title_ht,
        title_en: p.title_en ?? null,
        option_a: p.option_a,
        option_b: p.option_b,
        description_ht: p.description_ht ?? null,
        source_links: uniqueUrls.slice(0, 5),
        source_platform: p.source_platform ?? null,
        trending_keywords: p.trending_keywords ?? [],
        detected_entities: p.detected_entities ?? [],
        selection_reason: p.selection_reason ?? null,
        deadline_at: deadlineAt,
        popularity_score: ps2,
        trend_score: rs2,
        debate_score: ds2,
        virality_score: vs2,
        uniqueness_score: us2,
        relevance_score: rels2,
        safety_score: ss2,
        prediction_score: preds2,
        combined_score: combined2,
        risk_level: p.risk_level ?? "low",
        status: "pending",
      });
    }

    if (rows.length === 0) {
      return Response.json({ error: "All generated topics filtered out by uniqueness/safety/deduplication" }, { status: 422, headers: cors });
    }

    const { data: inserted, error: insertErr } = await admin
      .from("ai_generated_drafts")
      .insert(rows)
      .select();

    if (insertErr) {
      return Response.json({ error: insertErr.message }, { status: 500, headers: cors });
    }

    const insertedMatchups = (inserted ?? []).filter((r: any) => r.type === "matchup");
    const insertedPredictions = (inserted ?? []).filter((r: any) => r.type === "prediction");

    return Response.json({
      matchups_inserted: insertedMatchups.length,
      predictions_inserted: insertedPredictions.length,
      total: inserted?.length ?? 0,
      filtered_out: (matchups.length + predictions.length) - rows.length,
      sources_found: uniqueUrls.length,
      drafts: inserted,
    }, { headers: cors });

  } catch (err) {
    return Response.json(
      { error: err instanceof Error ? err.message : "Unknown error" },
      { status: 500, headers: cors }
    );
  }
});
