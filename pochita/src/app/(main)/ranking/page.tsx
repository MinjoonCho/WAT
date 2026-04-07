"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, SessionStore } from "@/lib/store";
import { CATEGORIES, DEMO_UNIVERSITY_RANKING, formatTimeKorean } from "@/lib/data";
import type { User, Session } from "@/lib/types";

export default function RankingPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [tab, setTab] = useState<"university" | "category">("university");
  const [sessions, setSessions] = useState<Session[]>([]);

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    setSessions(SessionStore.getAllSessions());
  }, [router]);

  if (!user) return null;

  // Build university ranking from real sessions
  const uniMap: Record<string, number> = {};
  sessions.filter(s => s.duration).forEach(s => {
    const su = AuthStore.getUserById(s.userId);
    if (su?.university) {
      uniMap[su.university] = (uniMap[su.university] ?? 0) + (s.duration ?? 0);
    }
  });
  // Merge with demo data
  DEMO_UNIVERSITY_RANKING.forEach(d => {
    uniMap[d.name] = (uniMap[d.name] ?? 0) + d.totalMinutes * 60;
  });
  const uniRanking = Object.entries(uniMap).map(([name, sec]) => ({ name, totalMinutes: Math.floor(sec / 60) }))
    .sort((a, b) => b.totalMinutes - a.totalMinutes);

  // Category ranking
  const catMap: Record<string, number> = {};
  sessions.filter(s => s.duration).forEach(s => {
    catMap[s.categoryId] = (catMap[s.categoryId] ?? 0) + (s.duration ?? 0);
  });
  const catRanking = CATEGORIES.map(c => ({ ...c, totalSec: catMap[c.id] ?? Math.floor(Math.random() * 100000) + 10000 }))
    .sort((a, b) => b.totalSec - a.totalSec);

  const myUniRank = uniRanking.findIndex(u => u.name === user.university);
  const top3 = uniRanking.slice(0, 3);

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] font-sans">
      <div className="px-5 pt-10 pb-4">
        <h1 className="text-[26px] font-black text-[var(--pochita-text)] leading-tight tracking-tight">랭킹</h1>
        <p className="text-[13px] text-gray-500 mt-0.5">학점 멸망전 실시간 순위</p>
      </div>

      {/* My university rank CTA */}
      {user.university && myUniRank >= 0 && (
        <div className="mx-4 mb-5 px-5 py-4 rounded-[20px] bg-orange-50 border border-orange-100 shadow-sm flex items-center justify-between">
          <div>
             <p className="text-[12px] text-gray-500 font-bold mb-1">우리 학교 랭킹</p>
             <div className="flex items-center gap-2">
               <span className="text-xl">{myUniRank < 3 ? ["🥇","🥈","🥉"][myUniRank] : `👑`}</span>
               <p className="text-[16px] font-bold text-[var(--pochita-text)]">{user.university}</p>
             </div>
          </div>
          <div className="text-right">
             <p className="text-[18px] font-black" style={{ color: "var(--pochita-orange)" }}>{myUniRank+1}<span className="text-[14px]">위</span></p>
             <p className="text-[12px] font-bold text-gray-400 mt-0.5">{uniRanking[myUniRank]?.totalMinutes?.toLocaleString()}분</p>
          </div>
        </div>
      )}

      {/* Modern Tabs */}
      <div className="px-4 mb-6">
        <div className="flex p-1 rounded-xl bg-gray-200">
          {[["university","🏫 최악의 대학"],["category","🎮 최악의 딴짓"]].map(([t, label]) => (
            <button key={t} onClick={() => setTab(t as "university" | "category")}
              className={`flex-1 py-2 text-[14px] font-bold rounded-lg transition-all ${tab === t ? "bg-white shadow-sm text-[var(--pochita-text)]" : "text-gray-500"}`}>
              {label}
            </button>
          ))}
        </div>
      </div>

      {tab === "university" ? (
        <div className="px-4 space-y-3 pb-10">
          {/* Podium */}
          <div className="flex items-end justify-center gap-2.5 mb-8 pt-4 px-2">
            {[top3[1], top3[0], top3[2]].map((u, i) => {
              if (!u) return <div key={i} className="w-[88px]" />;
              const heights = ["h-[96px]", "h-[128px]", "h-[72px]"];
              const ranks = [2, 1, 3];
              return (
                <div key={u.name} className="flex flex-col items-center flex-1 max-w-[100px]">
                  <div className="w-8 h-8 rounded-full bg-white shadow-sm flex items-center justify-center text-sm border border-gray-100 mb-2 font-bold text-gray-700">
                     {ranks[i]}
                  </div>
                  <p className="text-[13px] font-bold text-[var(--pochita-text)] text-center mb-0.5 truncate w-full px-1 leading-snug">{u.name.replace("대학교","")}</p>
                  <p className="text-[11px] text-gray-500 font-bold mb-2">{u.totalMinutes.toLocaleString()}분</p>
                  <div className={`w-full ${heights[i]} rounded-t-2xl shadow-sm`}
                    style={{ background: i === 1 ? "var(--pochita-orange)" : i === 0 ? "#E5E7EB" : "#F3F4F6", opacity: i===1 ? 1 : 0.8 }} />
                </div>
              );
            })}
          </div>

          <div className="bg-white rounded-[24px] border border-gray-200 shadow-sm overflow-hidden">
            {uniRanking.map((u, i) => (
              <div key={u.name}
                className="flex items-center gap-3 p-4 border-b border-gray-100 last:border-b-0"
                style={{ background: u.name === user.university ? "rgba(255,107,0,0.05)" : "transparent" }}>
                <span className="w-7 text-center font-bold text-[15px]" style={{ color: i === 0 ? "#EAB308" : i === 1 ? "#9CA3AF" : i === 2 ? "#D97706" : "#6B7280" }}>
                  {i+1}
                </span>
                <div className="flex-1">
                  <p className="text-[14px] font-bold text-[var(--pochita-text)]">{u.name}</p>
                  <p className="text-[12px] font-bold text-gray-400 mt-0.5" style={{ color: u.name === user.university ? "var(--pochita-orange)" : "" }}>
                    {u.totalMinutes.toLocaleString()}분
                  </p>
                </div>
                <div className="w-20 h-1.5 rounded-full overflow-hidden bg-gray-100 flex justify-end">
                  <div className="h-full rounded-full" style={{ width: `${(u.totalMinutes / (uniRanking[0]?.totalMinutes || 1)) * 100}%`, background: u.name === user.university ? "var(--pochita-orange)" : "#D1D5DB" }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="px-4 space-y-3 pb-8">
           <div className="bg-white rounded-[24px] border border-gray-200 shadow-sm overflow-hidden">
            {catRanking.map((c, i) => (
              <div key={c.id} className="flex items-center gap-4 p-4 border-b border-gray-100 last:border-b-0">
                <span className="w-5 text-center text-[15px] font-bold" style={{ color: i < 3 ? "var(--pochita-orange)" : "#9CA3AF" }}>{i+1}</span>
                <span className="text-[28px]">{c.emoji}</span>
                <div className="flex-1">
                  <p className="text-[15px] font-bold text-[var(--pochita-text)]">{c.label}</p>
                  <p className="text-[13px] font-bold mt-0.5" style={{ color: c.color }}>{formatTimeKorean(c.totalSec)}</p>
                </div>
                <div className="w-16 h-1.5 rounded-full overflow-hidden bg-gray-100 flex justify-end">
                  <div className="h-full rounded-full" style={{ width: `${(c.totalSec / (catRanking[0]?.totalSec || 1)) * 100}%`, background: c.color }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
