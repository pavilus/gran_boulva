import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import {
  generateOptionImages,
  type ImageGeneratorMatchup,
} from "@/lib/matchup-images";

export const runtime = "nodejs";

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

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("matchups")
    .select("id, title_ht, description_ht, options:matchup_options(id, option_label, option_name)")
    .eq("id", matchup_id)
    .single();

  if (error || !data) {
    return NextResponse.json(
      { error: error?.message ?? "Matchup not found" },
      { status: error ? 500 : 404 },
    );
  }

  const sessionClient = await createClient();
  const { data: { session } } = await sessionClient.auth.getSession();
  if (!session?.access_token) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Fire-and-forget — image generation takes 2-3 min, don't block the request
  const matchup = data as unknown as ImageGeneratorMatchup;
  const token = session.access_token;
  const userId = session.user?.id ?? null;

  (async () => {
    try {
      // Generate option A + B images via Edge Function
      const generated = await generateOptionImages(matchup, token);

      // Upload both images
      const [optionAImageUrl, optionBImageUrl] = await Promise.all([
        uploadImage(supabase, "generated/options", generated.imageA),
        uploadImage(supabase, "generated/options", generated.imageB),
      ]);

      // Save image URLs to matchup_options + record in gallery table
      await Promise.all([
        supabase.from("matchup_options").update({ image_url: optionAImageUrl }).eq("id", generated.optionA.id).then(),
        supabase.from("matchup_options").update({ image_url: optionBImageUrl }).eq("id", generated.optionB.id).then(),
        supabase.from("matchup_image_sets").insert({
          matchup_id,
          option_a_image_url: optionAImageUrl,
          option_b_image_url: optionBImageUrl,
          poster_image_url: null,
          share_image_url: null,
          model: "gpt-image-1",
          created_by: userId,
        }).then(),
      ]);
    } catch (err) {
      console.error("matchup image generation failed (background)", err);
    }
  })();

  return NextResponse.json({ started: true, message: "Imaj ap jenere… Rafraîchi nan 2-3 minit." });
}
