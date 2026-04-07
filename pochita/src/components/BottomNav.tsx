"use client";
import { usePathname, useRouter } from "next/navigation";

const TABS = [
  { id: "home",    label: "홈",    icon: "⏱",  href: "/home"   },
  { id: "groups",  label: "그룹",  icon: "👥",  href: "/groups" },
  { id: "ranking", label: "랭킹",  icon: "🏆",  href: "/ranking"},
  { id: "stats",   label: "통계",  icon: "📊",  href: "/stats"  },
  { id: "profile", label: "더보기",icon: "👤",  href: "/profile"},
] as const;

export default function BottomNav() {
  const pathname = usePathname();
  const router = useRouter();

  const active = TABS.find(t => pathname.startsWith(t.href))?.id ?? "home";

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-around"
      style={{
        background: "rgba(255, 255, 255, 0.9)",
        backdropFilter: "blur(20px)",
        borderTop: "1px solid rgba(0, 0, 0, 0.05)",
        paddingBottom: "env(safe-area-inset-bottom, 0px)",
        height: "64px",
      }}
    >
      {TABS.map(tab => {
        const isActive = active === tab.id;
        return (
          <button
            key={tab.id}
            onClick={() => router.push(tab.href)}
            className="flex flex-col items-center justify-center gap-0.5 flex-1 h-full transition-all active:scale-90"
          >
            <span className="text-lg leading-none" style={{ filter: isActive ? "none" : "grayscale(1) opacity(0.4)" }}>
              {tab.icon}
            </span>
            <span
              className="text-[10px] font-bold leading-none"
              style={{ color: isActive ? "var(--pochita-orange)" : "var(--pochita-text-secondary)" }}
            >
              {tab.label}
            </span>
            {isActive && (
              <span className="absolute bottom-0 w-8 h-0.5 rounded-full bg-[var(--pochita-orange)]" />
            )}
          </button>
        );
      })}
    </nav>
  );
}
