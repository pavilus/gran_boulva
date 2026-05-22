import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import {
  generateOptionImages,
  matchupImageModel,
  type ImageGeneratorMatchup,
} from "@/lib/matchup-images";

export const runtime = "nodejs";
export const maxDuration = 300;

async function uploadImage(
  supabase: ReturnType<typeof createAdminClient>,
  folder: string,
  buffer: Buffer,
) {
  const path = `${folder}/${Date.now()}-${crypto.randomUUID()}.png`;
  const { error } = await supabase.storage
    .from("matchup-images")
    .upload(path, buffer, { contentType: "image/png", upsert: false });

  if (error) throw new Error(error.message);
  const {
    data: { publicUrl },
  } = supabase.storage.from("matchup-images").getPublicUrl(path);
  return publicUrl;
}

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  const { matchup_id } = (await req.json()) as { matchup_id?: string };
  if (!matchup_id) {
    return NextResponse.json({ error: "matchup_id required" }, { status: 400 });
  }

  try {
    const supabase = createAdminClient();
    const { data, error } = await supabase
      .from("matchups")
      .select(
        "id, title_ht, description_ht, options:matchup_options(id, option_label, option_name)",
      )
      .eq("id", matchup_id)
      .single();

    if (error || !data) {
      return NextResponse.json(
        { error: error?.message ?? "Matchup not found" },
        { status: error ? 500 : 404 },
      );
    }

    const matchup = data as unknown as ImageGeneratorMatchup;
    const sessionClient = await createClient();
    const {
      data: { session },
    } = await sessionClient.auth.getSession();

    if (!session?.access_token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Generate only Option A and B images — composite is added manually
    const generated = await generateOptionImages(matchup, session.access_token);

    const [optionAImageUrl, optionBImageUrl] = await Promise.all([
      uploadImage(supabase, "generated/options", generated.imageA),
      uploadImage(supabase, "generated/options", generated.imageB),
    ]);

    const [{ error: optionAError }, { error: optionBError }] = await Promise.all([
      supabase.from("matchup_options").update({ image_url: optionAImageUrl }).eq("id", generated.optionA.id),
      supabase.from("matchup_options").update({ image_url: optionBImageUrl }).eq("id", generated.optionB.id),
    ]);

    if (optionAError || optionBError) {
      throw new Error(optionAError?.message ?? optionBError?.message);
    }

    return NextResponse.json({
      ok: true,
      option_a_image_url: optionAImageUrl,
      option_b_image_url: optionBImageUrl,
      poster_image_url: null,
      share_image_url: null,
    });
  } catch (error) {
    console.error("matchup image generation failed", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Image generation failed" },
      { status: 500 },
    );
  }
}
