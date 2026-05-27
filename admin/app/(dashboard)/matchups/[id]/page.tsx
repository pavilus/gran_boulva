import { createAdminClient } from "@/lib/supabase/admin";
import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import Topbar from "@/components/Topbar";
import MatchupDetail from "./MatchupDetail";

export default async function MatchupDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const supabase = createAdminClient();
  const { id } = await params;

  const [
    { data: matchup },
    { data: votes },
    { data: args },
  ] = await Promise.all([
    supabase
      .from("matchups")
      .select("*, category:categories(name_ht, name_en), options:matchup_options(id, option_label, option_name, vote_count, image_url)")
      .eq("id", id)
      .single(),
    supabase
      .from("votes")
      .select("option_id, created_at, vote_changed, user:users(username, full_name, email, avatar_url, location, influence_score, role)")
      .eq("matchup_id", id),
    supabase
      .from("arguments")
      .select("id, body, like_count, dislike_count, reply_count, created_at, option_id, status, media_url, media_type, media_duration, user:users(username)")
      .eq("matchup_id", id)
      .order("like_count", { ascending: false })
      .limit(20),
  ]);

  if (!matchup) notFound();

  // Normalise FK joins: Supabase PostgREST returns them as arrays
  const normaliseUser = (v: any) => ({
    ...v,
    user: Array.isArray(v.user) ? v.user[0] ?? null : v.user,
  });

  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title={matchup.title_ht} />
      <div className="px-5 pt-4 pb-1">
        <Link
          href="/matchups"
          className="inline-flex items-center gap-1.5 text-xs font-medium transition-colors"
          style={{ color: "#64748b" }}
        >
          <ArrowLeft size={13} /> Tounen nan Matchups
        </Link>
      </div>
      <div className="flex-1 p-5 pt-3">
        <MatchupDetail
          matchup={matchup as any}
          votes={(votes ?? []).map(normaliseUser) as any}
          args={(args ?? []).map(normaliseUser) as any}
        />
      </div>
    </div>
  );
}
