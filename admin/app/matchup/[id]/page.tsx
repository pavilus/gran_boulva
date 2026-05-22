import { createAdminClient } from "@/lib/supabase/admin";
import type { Metadata } from "next";
import { notFound } from "next/navigation";

type Params = { params: Promise<{ id: string }> };

async function getMatchup(id: string) {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("matchups")
    .select("id, title_ht, description_ht, poster_image_url, share_image_url")
    .eq("id", id)
    .single();
  return data;
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { id } = await params;
  const matchup = await getMatchup(id);
  if (!matchup) return {};

  const title = `${matchup.title_ht} | Gran Boulva`;
  const description =
    matchup.description_ht ?? "Vin di saw panse sou Gran Boulva.";
  const images = matchup.share_image_url ? [matchup.share_image_url] : [];

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "article",
      images,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images,
    },
  };
}

export default async function PublicMatchupPage({ params }: Params) {
  const { id } = await params;
  const matchup = await getMatchup(id);
  if (!matchup) notFound();

  return (
    <main
      className="min-h-screen px-5 py-10 text-white"
      style={{
        background:
          "radial-gradient(circle at top,#26105d 0%,#07030f 48%,#020208 100%)",
      }}
    >
      <div className="mx-auto max-w-3xl">
        <div className="mb-5 text-sm font-semibold" style={{ color: "#c4b5fd" }}>
          Gran Boulva · Vwa ou konte
        </div>
        <h1 className="mb-3 text-3xl font-black leading-tight">
          {matchup.title_ht}
        </h1>
        <p className="mb-7 text-base" style={{ color: "#ddd6fe" }}>
          Vin di saw panse sou Gran Boulva.
        </p>
        {matchup.poster_image_url && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={matchup.poster_image_url}
            alt={matchup.title_ht}
            className="mb-7 w-full rounded-xl"
            style={{ aspectRatio: "4 / 5", objectFit: "cover" }}
          />
        )}
        <div className="flex flex-wrap gap-3">
          <a
            href={`granboulva://matchup/${id}`}
            className="rounded-xl px-5 py-3 text-sm font-bold text-white"
            style={{ background: "linear-gradient(90deg,#7c3aed,#ec4899)" }}
          >
            Louvri nan app la
          </a>
          <a
            href="https://apps.apple.com/app/gran-boulva"
            className="rounded-xl px-5 py-3 text-sm font-semibold"
            style={{ color: "#e9ddff", border: "1px solid #31205b" }}
          >
            Telechaje sou App Store
          </a>
        </div>
      </div>
    </main>
  );
}
