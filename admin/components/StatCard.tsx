import Link from "next/link";
import { TrendingUp, TrendingDown, LucideIcon } from "lucide-react";

interface StatCardProps {
  label: string;
  value: string;
  change: number;
  changeLabel: string;
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  prefix?: string;
  href?: string;
}

export default function StatCard({
  label,
  value,
  change,
  changeLabel,
  icon: Icon,
  iconColor,
  iconBg,
  prefix,
  href,
}: StatCardProps) {
  const positive = change >= 0;

  const inner = (
    <div
      className="flex flex-col gap-3 p-4 rounded-xl"
      style={{
        background: "#0e0f1e",
        border: "1px solid #1e2040",
        cursor: href ? "pointer" : "default",
        transition: "border-color 0.15s",
        height: "100%",
      }}
    >
      {/* Top row */}
      <div className="flex items-start justify-between">
        <div>
          <div style={{ color: "#64748b", fontSize: 11, fontWeight: 500, marginBottom: 4 }}>
            {label}
          </div>
          <div className="text-white font-bold" style={{ fontSize: 22, lineHeight: 1 }}>
            {prefix}{value}
          </div>
        </div>
        <div
          className="flex items-center justify-center rounded-lg shrink-0"
          style={{ width: 36, height: 36, background: iconBg }}
        >
          <Icon size={18} color={iconColor} />
        </div>
      </div>

      {/* Change */}
      <div className="flex items-center gap-1">
        <span
          className="flex items-center gap-0.5 text-xs font-semibold"
          style={{ color: positive ? "#10b981" : "#ef4444" }}
        >
          {positive ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
          {positive ? "+" : ""}{change}%
        </span>
        <span style={{ color: "#475569", fontSize: 11 }}>{changeLabel}</span>
      </div>
    </div>
  );

  if (href) {
    return (
      <Link href={href} style={{ flex: 1, minWidth: 0, textDecoration: "none" }}>
        {inner}
      </Link>
    );
  }
  return <div style={{ flex: 1, minWidth: 0 }}>{inner}</div>;
}
