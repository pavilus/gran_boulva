import Topbar from "@/components/Topbar";
import { createAdminClient } from "@/lib/supabase/admin";
import Link from "next/link";

type ImageSet = {
  id: string;
  matchup_id: string;
  option_a_image_url: string;
  option_b_image_url: string;
  poster_image_url: string;
  share_image_url: string;
  model: string;
  created_at: string;
  matchup?: { title_ht?: string } | Array<{ title_ht?: string }> | null;
};

function titleFor(imageSet: ImageSet) {
  const matchup = Array.isArray(imageSet.matchup)
    ? imageSet.matchup[0]
    : imageSet.matchup;
  return matchup?.title_ht ?? "Matchup";
}

export default async function MatchupImagesPage() {
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("matchup_image_sets")
    .select(
      "id, matchup_id, option_a_image_url, option_b_image_url, poster_image_url, share_image_url, model, created_at, matchup:matchups(title_ht)",
    )
    .order("created_at", { ascending: false })
    .limit(100);

  const imageSets = (data ?? []) as ImageSet[];

  return (
    <div
      className="flex flex-col flex-1 min-h-0 overflow-y-auto"
      style={{ background: "#07080f" }}
    >
      <Topbar
        title="Imaj Matchup"
        subtitle={`${imageSets.length} poster jenerasyon resan`}
      />
      <div className="grid gap-4 p-5" style={{ gridTemplateColumns: "repeat(auto-fill,minmax(290px,1fr))" }}>
        {imageSets.map((imageSet) => (
          <article
            key={imageSet.id}
            className="overflow-hidden rounded-xl"
            style={{ background: "#0e0f1e", border: "1px solid #1e2040" }}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={imageSet.poster_image_url}
              alt={titleFor(imageSet)}
              className="w-full"
              style={{ aspectRatio: "4 / 5", objectFit: "cover" }}
            />
            <div className="space-y-3 p-4">
              <div>
                <h2 className="line-clamp-2 text-sm font-semibold text-white">
                  {titleFor(imageSet)}
                </h2>
                <p className="mt-1 text-xs" style={{ color: "#64748b" }}>
                  {new Date(imageSet.created_at).toLocaleString("fr-HT")} ·{" "}
                  {imageSet.model}
                </p>
              </div>
              <div className="flex flex-wrap gap-2">
                <a
                  href={imageSet.poster_image_url}
                  download
                  className="rounded-lg px-3 py-1.5 text-xs font-semibold"
                  style={{
                    color: "#ffffff",
                    background: "linear-gradient(90deg,#7c3aed,#a855f7)",
                  }}
                >
                  Telechaje poster
                </a>
                <a
                  href={imageSet.share_image_url}
                  download
                  className="rounded-lg px-3 py-1.5 text-xs font-semibold"
                  style={{ color: "#a78bfa", border: "1px solid #31205b" }}
                >
                  OG share
                </a>
                <Link
                  href={`/matchups/${imageSet.matchup_id}`}
                  className="rounded-lg px-3 py-1.5 text-xs font-semibold"
                  style={{ color: "#94a3b8", border: "1px solid #1e2040" }}
                >
                  Matchup
                </Link>
              </div>
            </div>
          </article>
        ))}
        {imageSets.length === 0 && (
          <div
            className="rounded-xl p-8 text-sm"
            style={{ color: "#64748b", border: "1px solid #1e2040" }}
          >
            Pa gen poster jenerasyon ankò.
          </div>
        )}
      </div>
    </div>
  );
}
