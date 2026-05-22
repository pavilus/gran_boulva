import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/admin";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

type MatchupOptionImage = {
  id: string;
  option_label: string;
  image_url?: string | null;
};

const acceptedTypes = new Set(["image/png", "image/jpeg", "image/webp"]);

function imageFile(formData: FormData, name: string) {
  const value = formData.get(name);
  if (!(value instanceof File) || value.size === 0) {
    throw new Error(`${name} image required`);
  }
  if (!acceptedTypes.has(value.type)) {
    throw new Error(`${name} must be PNG, JPEG, or WebP`);
  }
  return value;
}

async function uploadImage(
  supabase: ReturnType<typeof createAdminClient>,
  folder: string,
  file: File,
) {
  const extension =
    file.type === "image/jpeg" ? "jpg" : file.type.split("/")[1];
  const path = `${folder}/${Date.now()}-${crypto.randomUUID()}.${extension}`;
  const { error } = await supabase.storage
    .from("matchup-images")
    .upload(path, Buffer.from(await file.arrayBuffer()), {
      contentType: file.type,
      upsert: false,
    });

  if (error) throw new Error(error.message);
  const {
    data: { publicUrl },
  } = supabase.storage.from("matchup-images").getPublicUrl(path);
  return publicUrl;
}

export async function POST(req: NextRequest) {
  const forbidden = await requireAdmin();
  if (forbidden) return forbidden;

  try {
    const formData = await req.formData();
    const matchupId = formData.get("matchup_id");
    if (typeof matchupId !== "string" || !matchupId) {
      return NextResponse.json({ error: "matchup_id required" }, { status: 400 });
    }

    const poster = imageFile(formData, "poster");
    const share = imageFile(formData, "share");
    const supabase = createAdminClient();
    const { data: matchup, error: matchupLoadError } = await supabase
      .from("matchups")
      .select("id, options:matchup_options(id, option_label, image_url)")
      .eq("id", matchupId)
      .single();

    if (matchupLoadError || !matchup) {
      return NextResponse.json(
        { error: matchupLoadError?.message ?? "Matchup not found" },
        { status: matchupLoadError ? 500 : 404 },
      );
    }

    const options = (matchup.options ?? []) as MatchupOptionImage[];
    const optionA = options.find((option) => option.option_label === "A");
    const optionB = options.find((option) => option.option_label === "B");
    if (!optionA?.image_url || !optionB?.image_url) {
      return NextResponse.json(
        { error: "Generate or upload option A and B images first" },
        { status: 400 },
      );
    }

    const [posterImageUrl, shareImageUrl] = await Promise.all([
      uploadImage(supabase, "manual/posters", poster),
      uploadImage(supabase, "manual/share", share),
    ]);

    const { error: matchupUpdateError } = await supabase
      .from("matchups")
      .update({
        poster_image_url: posterImageUrl,
        share_image_url: shareImageUrl,
      })
      .eq("id", matchupId);

    if (matchupUpdateError) throw new Error(matchupUpdateError.message);

    const { data: imageSet, error: imageSetError } = await supabase
      .from("matchup_image_sets")
      .insert({
        matchup_id: matchupId,
        option_a_image_url: optionA.image_url,
        option_b_image_url: optionB.image_url,
        poster_image_url: posterImageUrl,
        share_image_url: shareImageUrl,
        model: "manual-canva",
      })
      .select()
      .single();

    if (imageSetError) throw new Error(imageSetError.message);

    return NextResponse.json({
      ok: true,
      image_set: imageSet,
      option_a_image_url: optionA.image_url,
      option_b_image_url: optionB.image_url,
      poster_image_url: posterImageUrl,
      share_image_url: shareImageUrl,
    });
  } catch (error) {
    console.error("manual matchup image upload failed", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Upload failed" },
      { status: 500 },
    );
  }
}
