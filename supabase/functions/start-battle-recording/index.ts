// ============================================================
// start-battle-recording
// ============================================================
// Called by the app (either debater) once the battle goes 'live'.
// Idempotent — if recording is already running for this battle, returns early.
//
// Flow:
//   1. Acquire Agora Cloud Recording resource
//   2. Start mix recording (both UIDs) → HLS output to S3
//   3. Store Agora resourceId + sid in debate_battles (reused by end-battle)
//   4. Update battle status to 'live' and set started_at
//
// Required secrets:
//   AGORA_APP_ID, AGORA_APP_CERTIFICATE
//   AGORA_CUSTOMER_KEY, AGORA_CUSTOMER_SECRET  (Basic Auth for Cloud Recording API)
//   AWS_S3_BUCKET   (e.g. "gran-boulva-battle-recordings")
//   AWS_S3_ACCESS_KEY, AWS_S3_SECRET_KEY, AWS_S3_REGION
// ============================================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type StartRecordingBody = {
  battle_id?: string;
};

// Agora Cloud Recording base URL
const AGORA_API = "https://api.agora.io/v1/apps";

// Auth helper
async function getAuthUser(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
) {
  const authorization = req.headers.get("Authorization") ?? "";
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: authorization },
  });
  if (!res.ok) return null;
  return await res.json();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Env ─────────────────────────────────────────────
    const supabaseUrl       = Deno.env.get("SUPABASE_URL")              ?? "";
    const anonKey           = Deno.env.get("SUPABASE_ANON_KEY")         ?? "";
    const serviceRoleKey    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const agoraAppId        = Deno.env.get("AGORA_APP_ID")              ?? "";
    const agoraCert         = Deno.env.get("AGORA_APP_CERTIFICATE")     ?? "";
    const agoraCustomerKey  = Deno.env.get("AGORA_CUSTOMER_KEY")        ?? "";
    const agoraCustomerSec  = Deno.env.get("AGORA_CUSTOMER_SECRET")     ?? "";
    const s3Bucket          = Deno.env.get("AWS_S3_BUCKET")             ?? "gran-boulva-battle-recordings";
    const s3AccessKey       = Deno.env.get("AWS_S3_ACCESS_KEY")         ?? "";
    const s3SecretKey       = Deno.env.get("AWS_S3_SECRET_KEY")         ?? "";
    const s3Region          = Deno.env.get("AWS_S3_REGION")             ?? "us-east-1";

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      return Response.json(
        { error: "Missing Supabase secrets" },
        { status: 500, headers: corsHeaders },
      );
    }

    // ── Auth ─────────────────────────────────────────────
    const authUser = await getAuthUser(req, supabaseUrl, anonKey);
    if (!authUser?.id) {
      return Response.json(
        { error: "Not authenticated" },
        { status: 401, headers: corsHeaders },
      );
    }

    const admin = createClient(supabaseUrl, serviceRoleKey);

    // ── Resolve internal user ─────────────────────────────
    const { data: callerUser, error: userErr } = await admin
      .from("users")
      .select("id")
      .eq("auth_user_id", authUser.id)
      .single();

    if (userErr || !callerUser) {
      return Response.json(
        { error: "User not found" },
        { status: 404, headers: corsHeaders },
      );
    }

    // ── Parse body ────────────────────────────────────────
    const body = (await req.json()) as StartRecordingBody;
    const { battle_id } = body;
    if (!battle_id) {
      return Response.json(
        { error: "battle_id is required" },
        { status: 400, headers: corsHeaders },
      );
    }

    // ── Fetch battle ──────────────────────────────────────
    const { data: battle, error: battleErr } = await admin
      .from("debate_battles")
      .select("id, challenger_id, opponent_id, status, agora_channel, recording_url")
      .eq("id", battle_id)
      .single();

    if (battleErr || !battle) {
      return Response.json(
        { error: "Battle not found" },
        { status: 404, headers: corsHeaders },
      );
    }

    // Only challenger or opponent can start recording
    const isParticipant =
      callerUser.id === battle.challenger_id ||
      callerUser.id === battle.opponent_id;
    if (!isParticipant) {
      return Response.json(
        { error: "Only battle participants can start recording" },
        { status: 403, headers: corsHeaders },
      );
    }

    // Must be in lobby (or already live — idempotent)
    if (battle.status === "live") {
      return Response.json(
        { battle_id, status: "live", message: "Recording already started" },
        { headers: corsHeaders },
      );
    }
    if (battle.status !== "lobby") {
      return Response.json(
        { error: `Battle cannot be started from status '${battle.status}'` },
        { status: 409, headers: corsHeaders },
      );
    }

    // ── Agora Cloud Recording ─────────────────────────────
    // If Agora secrets not yet set, skip recording but still mark live.
    if (!agoraAppId || !agoraCustomerKey || !agoraCustomerSec) {
      console.warn("[start-battle-recording] Agora secrets not configured — skipping cloud recording");
      await admin
        .from("debate_battles")
        .update({
          status:     "live",
          started_at: new Date().toISOString(),
        })
        .eq("id", battle_id);

      return Response.json(
        { battle_id, status: "live", recording: false },
        { headers: corsHeaders },
      );
    }

    const agoraAuth = "Basic " +
      btoa(`${agoraCustomerKey}:${agoraCustomerSec}`);

    const channel    = battle.agora_channel;
    const recordUids = [1, 2]; // challenger UID=1, opponent UID=2

    // Step 1: Acquire resource ID
    const acquireRes = await fetch(
      `${AGORA_API}/${agoraAppId}/cloud_recording/acquire`,
      {
        method: "POST",
        headers: {
          Authorization: agoraAuth,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cname:         channel,
          uid:           "0",         // cloud recorder UID
          clientRequest: {
            resourceExpiredHour: 1,
            scene:               1,  // scene 1 = web recording / HLS
          },
        }),
      },
    );

    if (!acquireRes.ok) {
      const err = await acquireRes.text();
      throw new Error(`Agora acquire failed (${acquireRes.status}): ${err}`);
    }

    const { resourceId } = await acquireRes.json();

    // Step 2: Start recording (mix mode → HLS → S3)
    const startRes = await fetch(
      `${AGORA_API}/${agoraAppId}/cloud_recording/resourceid/${resourceId}/mode/mix/start`,
      {
        method: "POST",
        headers: {
          Authorization: agoraAuth,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          cname: channel,
          uid:   "0",
          clientRequest: {
            recordingConfig: {
              channelType:        1,          // 1 = live broadcast
              streamTypes:        2,          // 2 = audio + video
              subscribeUidGroup:  0,
              subscribeVideoUids: recordUids.map(String),
              subscribeAudioUids: recordUids.map(String),
              maxIdleTime:        60,
            },
            recordingFileConfig: {
              avFileType: ["hls"],            // HLS output (.m3u8 + .ts segments)
            },
            storageConfig: {
              vendor:          1,             // 1 = AWS S3
              region:          0,             // 0 = us-east-1 (adjust if needed)
              bucket:          s3Bucket,
              accessKey:       s3AccessKey,
              secretKey:       s3SecretKey,
              fileNamePrefix:  ["battles", battle_id],
            },
          },
        }),
      },
    );

    if (!startRes.ok) {
      const err = await startRes.text();
      throw new Error(`Agora start recording failed (${startRes.status}): ${err}`);
    }

    const { sid } = await startRes.json();

    // Step 3: Mark battle live, store resourceId + sid for end-battle
    // We reuse the recording_url column temporarily to carry resourceId:sid
    // until the real URL is known after the battle ends.
    await admin
      .from("debate_battles")
      .update({
        status:        "live",
        started_at:    new Date().toISOString(),
        recording_url: `agora:${resourceId}:${sid}`,  // placeholder; overwritten by end-battle
      })
      .eq("id", battle_id);

    return Response.json(
      {
        battle_id,
        status:      "live",
        recording:   true,
        resource_id: resourceId,
        sid,
      },
      { headers: corsHeaders },
    );
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : JSON.stringify(error);
    return Response.json(
      { error: message },
      { status: 500, headers: corsHeaders },
    );
  }
});
