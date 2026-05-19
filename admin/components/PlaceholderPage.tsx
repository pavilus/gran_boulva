import { LucideIcon } from "lucide-react";
import Topbar from "@/components/Topbar";

export default function PlaceholderPage({
  title,
  subtitle,
  icon: Icon,
}: {
  title: string;
  subtitle: string;
  icon: LucideIcon;
}) {
  return (
    <div className="flex flex-col flex-1 min-h-0 overflow-y-auto" style={{ background: "#07080f" }}>
      <Topbar title={title} />
      <div className="flex-1 flex items-center justify-center p-10">
        <div className="text-center space-y-4">
          <div
            className="mx-auto flex items-center justify-center rounded-2xl"
            style={{ width: 64, height: 64, background: "rgba(124,58,237,0.15)" }}
          >
            <Icon size={28} color="#a78bfa" />
          </div>
          <div className="text-white font-semibold text-lg">{title}</div>
          <div style={{ color: "#475569", fontSize: 13 }}>{subtitle}</div>
          <div
            className="inline-block px-4 py-2 rounded-lg text-xs font-medium"
            style={{
              background: "rgba(124,58,237,0.12)",
              border: "1px solid rgba(124,58,237,0.25)",
              color: "#a78bfa",
            }}
          >
            Ap vini byento
          </div>
        </div>
      </div>
    </div>
  );
}
