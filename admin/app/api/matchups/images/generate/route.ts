import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import {
  generateOptionImages,
  renderCompositeImages,
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
      // 1. Generate option A + B images via Edge Function
      const generated = await generateOptionImages(matchup, token);

      // 2. Render composite poster (1080×1350) and share (1200×630) images locally
      let posterImage: Buffer | null = null;
      let shareImage: Buffer | null = null;
      try {
        const composites = await renderCompositeImages({
          matchup,
          optionA: generated.optionA,
          optionB: generated.optionB,
          imageA: generated.imageA,
          imageB: generated.imageB,
        });
        posterImage = composites.posterImage;
        shareImage = composites.shareImage;
      } catch (compositeErr) {
        console.error("matchup composite render failed (non-fatal)", compositeErr);
      }

      // 3. Upload all available images in parallel
      const uploadTasks: Promise<string>[] = [
        uploadImage(supabase, "generated/options", generated.imageA),
        uploadImage(supabase, "generated/options", generated.imageB),
      ];
      if (posterImage) uploadTasks.push(uploadImage(supabase, "generated/poster", posterImage));
      if (shareImage) uploadTasks.push(uploadImage(supabase, "generated/share", shareImage));

      const urls = await Promise.all(uploadTasks);
      const [optionAImageUrl, optionBImageUrl] = urls;
      const posterImageUrl = posterImage ? urls[2] : null;
      const shareImageUrl = shareImage ? urls[posterImage ? 3 : 2] : null;

      // 4. Write everything to the DB
      await Promise.all([
        supabase.from("matchup_options").update({ image_url: optionAImageUrl }).eq("id", generated.optionA.id).then(),
        supabase.from("matchup_options").update({ image_url: optionBImageUrl }).eq("id", generated.optionB.id).then(),
        posterImageUrl
          ? supabase.from("matchups").update({
              poster_image_url: posterImageUrl,
              share_image_url: shareImageUrl,
            }).eq("id", matchup_id).then()
          : Promise.resolve(),
        // Always insert a gallery row — poster/share are nullable now
        supabase.from("matchup_image_sets").insert({
          matchup_id,
          option_a_image_url: optionAImageUrl,
          option_b_image_url: optionBImageUrl,
          poster_image_url: posterImageUrl ?? null,
          share_image_url: shareImageUrl ?? null,
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
