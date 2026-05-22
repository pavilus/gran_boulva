import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const adminRoles = new Set(["admin", "owner", "moderator"]);

async function requireAdminRequest(
  req: Request,
  supabaseUrl: string,
  anonKey: string,
  serviceKey: string,
) {
  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) {
    return Response.json({ error: "Unauthorized" }, { status: 401, headers: cors });
  }

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
    const openaiKey = Deno.env.get("OPENAI_API_KEY") ?? "";

    const forbidden = await requireAdminRequest(
      req,
      supabaseUrl,
      anonKey,
      serviceKey,
    );
    if (forbidden) return forbidden;

    if (!openaiKey) {
      return Response.json(
        { error: "OPENAI_API_KEY not set" },
        { status: 500, headers: cors },
      );
    }

    const { prompt } = (await req.json()) as { prompt?: string };
    if (!prompt?.trim()) {
      return Response.json(
        { error: "prompt required" },
        { status: 400, headers: cors },
      );
    }

    const imageResponse = await fetch("https://api.openai.com/v1/images/generations", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-image-1.5",
        prompt,
        size: "1024x1536",
        quality: "high",
        output_format: "png",
      }),
    });

    if (!imageResponse.ok) {
      return Response.json(
        { error: `OpenAI image generation failed: ${await imageResponse.text()}` },
        { status: 500, headers: cors },
      );
    }

    const image = await imageResponse.json();
    const base64 = image.data?.[0]?.b64_json;
    if (!base64) {
      return Response.json(
        { error: "OpenAI image generation returned no image" },
        { status: 500, headers: cors },
      );
    }

    return Response.json(
      { image_b64: base64, model: "gpt-image-1.5" },
      { headers: cors },
    );
  } catch (error) {
    console.error("generate-matchup-option-image failed", error);
    return Response.json(
      {
        error:
          error instanceof Error ? error.message : "Image generation failed",
      },
      { status: 500, headers: cors },
    );
  }
});
