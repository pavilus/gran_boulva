"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Swords,
  TrendingUp,
  Bot,
  Tag,
  Users,
  BadgeCheck,
  Award,
  Medal,
  Flag,
  MessageSquare,
  Zap,
  BarChart3,
  Bell,
  CreditCard,
  Settings,
  ScrollText,
  Mail,
  Images,
  Sparkles,
  ChevronLeft,
  ChevronRight,
  Shield,
  LogOut,
  ClipboardList,
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";

const NAV = [
  { href: "/overview", icon: LayoutDashboard, label: "Dashboard" },
  { href: "/matchups", icon: Swords, label: "Matchups" },
  { href: "/matchup-images", icon: Images, label: "Galri Imaj" },
  { href: "/predictions", icon: TrendingUp, label: "Prediksyon" },
  { href: "/scout", icon: Bot, label: "AI Boulva Scout" },
  { href: "/categories", icon: Tag, label: "Kategori" },
  { href: "/users", icon: Users, label: "Itilizatè" },
  { href: "/waitlist", icon: ClipboardList, label: "Lis Datant" },
  { href: "/verification", icon: BadgeCheck, label: "Verifikasyon" },
  { href: "/creators", icon: Award, label: "Kreyatè" },
  { href: "/badges", icon: Medal, label: "Badj" },
  { href: "/reports", icon: Flag, label: "Rapò" },
  { href: "/moderation", icon: MessageSquare, label: "Agiman & Moderasyon" },
  { href: "/boosts", icon: Zap, label: "Boosts" },
  { href: "/cosmetics", icon: Sparkles, label: "Kosmetik" },
  { href: "/analytics", icon: BarChart3, label: "Analytics" },
  { href: "/notifications", icon: Bell, label: "Notifikasyon" },
  { href: "/email", icon: Mail, label: "Email" },
  { href: "/payments", icon: CreditCard, label: "Pèman & Referans" },
  { href: "/team", icon: Shield, label: "Ekip & Pèmisyon" },
  { href: "/settings", icon: Settings, label: "Paramèt" },
  { href: "/audit", icon: ScrollText, label: "CMS Logs" },
];

function getInitials(name: string): string {
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? "")
    .join("");
}

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [collapsed, setCollapsed] = useState(false);
  const [displayName, setDisplayName] = useState("");
  const [userInitials, setUserInitials] = useState("?");
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);

  const handleLogout = async () => {
    const supabase = createClient();
    const { error } = await supabase.auth.signOut();
    if (error) {
      console.error(error);
      return;
    }
    router.push("/login");
  };

  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getUser().then(async ({ data, error }) => {
      if (error || !data?.user) return;
      const user = data.user;
      const name =
        user.user_metadata?.full_name ||
        user.user_metadata?.name ||
        user.email?.split("@")[0] ||
        user.email ||
        "Admin";
      setDisplayName(name);
      setUserInitials(getInitials(name) || name.slice(0, 2).toUpperCase());

      const { data: profile, error: profileError } = await supabase
        .from("users")
        .select("avatar_url")
        .eq("auth_user_id", user.id)
        .maybeSingle();
      if (!profileError && profile?.avatar_url) setAvatarUrl(profile.avatar_url);
    });
  }, []);

  return (
    <aside
      className="relative flex flex-col h-screen transition-all duration-300 shrink-0"
      style={{ width: collapsed ? 60 : 220, background: "#0a0b18", borderRight: "1px solid #1e2040" }}
    >
      {/* Logo + collapse toggle */}
      <div
        className="flex items-center gap-2 px-4 py-5 shrink-0"
        style={{ borderBottom: "1px solid #1e2040", minHeight: 64 }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.png" alt="Gran Boulva" style={{ width: 32, height: 32, objectFit: "contain", borderRadius: 6, flexShrink: 0 }} />
        {!collapsed && (
          <div className="flex-1 min-w-0">
            <div className="text-white font-bold text-sm leading-tight">Gran Boulva</div>
            <div style={{ color: "#6366f1", fontSize: 10 }}>Admin Panel</div>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex items-center justify-center rounded-lg transition-colors hover:bg-white/5 shrink-0"
          style={{ width: 24, height: 24, color: "#475569", marginLeft: collapsed ? "auto" : undefined }}
        >
          {collapsed ? <ChevronRight size={14} /> : <ChevronLeft size={14} />}
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-0.5">
        {NAV.map(({ href, icon: Icon, label }) => {
          const active = pathname === href || pathname.startsWith(href + "/");
          return (
            <Link key={href} href={href}>
              <div
                className="flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium transition-all cursor-pointer"
                style={{
                  color: active ? "#a78bfa" : "#64748b",
                  background: active ? "linear-gradient(90deg,rgba(124,58,237,0.25),rgba(124,58,237,0.05))" : "transparent",
                  borderLeft: active ? "2px solid #7c3aed" : "2px solid transparent",
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                }}
              >
                <Icon size={15} className="shrink-0" />
                {!collapsed && <span>{label}</span>}
              </div>
            </Link>
          );
        })}
      </nav>

      {/* User + Logout */}
      <div
        className="flex items-center gap-3 px-4 py-4 shrink-0"
        style={{ borderTop: "1px solid #1e2040" }}
      >
        <div
          style={{
            width: 32, height: 32, borderRadius: "50%", overflow: "hidden", flexShrink: 0,
            background: "linear-gradient(135deg,#7c3aed,#ec4899)",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
        >
          {avatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={avatarUrl}
              alt="Profile"
              onError={() => setAvatarUrl(null)}
              style={{ width: "100%", height: "100%", objectFit: "cover", display: "block", borderRadius: "50%" }}
            />
          ) : (
            <span style={{ color: "#D4D4D4", fontSize: 12, fontWeight: "bold" }}>{userInitials}</span>
          )}
        </div>

        {!collapsed && (
          <div className="overflow-hidden flex-1 min-w-0">
            <div className="text-white text-xs font-semibold truncate">{displayName || "…"}</div>
            <div style={{ color: "#a78bfa", fontSize: 10 }}>Admin</div>
          </div>
        )}

        <button
          onClick={handleLogout}
          title="Dekonekte"
          className="shrink-0 p-1.5 rounded-lg transition-colors hover:bg-red-500/10"
          style={{ color: "#64748b" }}
        >
          <LogOut size={14} />
        </button>
      </div>

    </aside>
  );
}
