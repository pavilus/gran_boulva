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

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const forbidden = await requireAdminRequest(req, supabaseUrl, anonKey, serviceKey);
    if (forbidden) return forbidden;

    const admin = createClient(supabaseUrl, serviceKey);

    const body = await req.json();
    const { draft_id, action, edits, notes } = body as {
      draft_id: string;
      action: "approve" | "reject";
      edits?: { title_ht?: string; option_a?: string; option_b?: string; description_ht?: string };
      notes?: string;
    };

    if (!draft_id || !action) {
      return Response.json({ error: "draft_id and action required" }, { status: 400, headers: cors });
    }

    if (action === "reject") {
      const { error } = await admin
        .from("ai_generated_drafts")
        .update({ status: "rejected", ...(notes ? { rejection_notes: notes } : {}) })
        .eq("id", draft_id);
      if (error) return Response.json({ error: error.message }, { status: 500, headers: cors });
      return Response.json({ ok: true }, { headers: cors });
    }

    if (action === "approve") {
      const { data: draft, error: draftErr } = await admin
        .from("ai_generated_drafts")
        .select("*")
        .eq("id", draft_id)
        .single();

      if (draftErr || !draft) {
        return Response.json({ error: "Draft not found" }, { status: 404, headers: cors });
      }

      const titleHt = edits?.title_ht ?? draft.title_ht;
      const optionA = edits?.option_a ?? draft.option_a;
      const optionB = edits?.option_b ?? draft.option_b;
      const descHt = edits?.description_ht ?? draft.description_ht;

      // ── Prediction approval ──────────────────────────────────────────────────
      if (draft.type === "prediction") {
        const { data: prediction, error: predErr } = await admin
          .from("predictions")
          .insert({
            category_id: draft.category_id,
            title_ht: titleHt,
            title_en: draft.title_en ?? null,
            option_a: optionA,
            option_b: optionB,
            deadline_at: draft.deadline_at ?? null,
            status: "active",
            total_votes: 0,
          })
          .select()
          .single();

        if (predErr || !prediction) {
          return Response.json({ error: predErr?.message ?? "Failed to create prediction" }, { status: 500, headers: cors });
        }

        await admin.from("ai_generated_drafts").update({ status: "approved" }).eq("id", draft_id);
        return Response.json({ prediction_id: prediction.id }, { headers: cors });
      }

      // ── Matchup approval ─────────────────────────────────────────────────────
      const now = new Date().toISOString();
      const { data: matchup, error: matchupErr } = await admin
        .from("matchups")
        .insert({
          category_id: draft.category_id,
          title_ht: titleHt,
          title_en: draft.title_en ?? null,
          description_ht: descHt ?? null,
          status: "published",
          published_at: now,
          total_votes: 0,
          engagement_score: 0,
        })
        .select()
        .single();

      if (matchupErr || !matchup) {
        return Response.json({ error: matchupErr?.message ?? "Failed to create matchup" }, { status: 500, headers: cors });
      }

      const { error: optsErr } = await admin.from("matchup_options").insert([
        { matchup_id: matchup.id, option_label: "A", option_name: optionA, vote_count: 0, image_url: draft.image_url_a ?? null },
        { matchup_id: matchup.id, option_label: "B", option_name: optionB, vote_count: 0, image_url: draft.image_url_b ?? null },
      ]);

      if (optsErr) {
        // Rollback the matchup
        await admin.from("matchups").delete().eq("id", matchup.id);
        return Response.json({ error: optsErr.message }, { status: 500, headers: cors });
      }

      await admin
        .from("ai_generated_drafts")
        .update({ status: "approved" })
        .eq("id", draft_id);

      return Response.json({ matchup_id: matchup.id }, { headers: cors });
    }

    return Response.json({ error: "Invalid action. Use 'approve' or 'reject'" }, { status: 400, headers: cors });
  } catch (err) {
    return Response.json(
      { error: err instanceof Error ? err.message : "Unknown error" },
      { status: 500, headers: cors }
    );
  }
});
