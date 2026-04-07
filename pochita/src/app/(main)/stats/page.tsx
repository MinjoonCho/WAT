"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, SessionStore } from "@/lib/store";
import { CATEGORIES, formatTimeKorean } from "@/lib/data";
import type { User, Session } from "@/lib/types";

export default function StatsPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [sessions, setSessions] = useState<Session[]>([]);

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    setSessions(SessionStore.getUserSessions(u.id));
  }, [router]);

  if (!user) return null;

  const todaySessions = SessionStore.getTodaySessions(user.id);
  const todaySec = todaySessions.reduce((s, x) => s + (x.duration ?? 0), 0);
  const totalSec = sessions.reduce((s, x) => s + (x.duration ?? 0), 0);
  const avgSec = sessions.length > 0 ? Math.floor(totalSec / sessions.length) : 0;

  // Category breakdown
  const catSecs: Record<string, number> = {};
  sessions.forEach(s => { catSecs[s.categoryId] = (catSecs[s.categoryId] ?? 0) + (s.duration ?? 0); });
  const catBreakdown = CATEGORIES.map(c => ({ ...c, sec: catSecs[c.id] ?? 0 })).filter(c => c.sec > 0).sort((a, b) => b.sec - a.sec);
  const maxCatSec = catBreakdown[0]?.sec || 1;

  // Last 7 days
  const days: { label: string; sec: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(); d.setDate(d.getDate() - i); d.setHours(0,0,0,0);
    const dEnd = new Date(d); dEnd.setDate(dEnd.getDate() + 1);
    const sec = sessions.filter(s => s.startTime >= d.getTime() && s.startTime < dEnd.getTime()).reduce((acc, s) => acc + (s.duration ?? 0), 0);
    days.push({ label: ["일","월","화","수","목","금","토"][d.getDay()], sec });
  }
  const maxDaySec = Math.max(...days.map(d => d.sec), 1);

  const achievements = [
    { label: "딴짓 입문자", desc: "첫 세션", emoji: "🏅", done: sessions.length >= 1 },
    { label: "1시간 딴짓", desc: "한 번에 1시간 이상", emoji: "⏰", done: sessions.some(s => (s.duration ?? 0) >= 3600) },
    { label: "꾸준히 타락 중", desc: "7일 연속 딴짓", emoji: "🔥", done: days.filter(d => d.sec > 0).length >= 7 },
    { label: "딴짓 달인", desc: "총 10시간", emoji: "💀", done: totalSec >= 36000 },
    { label: "전업 딴짓러", desc: "하루 5시간 이상", emoji: "👑", done: todaySec >= 18000 },
  ];

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] font-sans pb-20">
      <div className="px-5 pt-10 pb-4">
        <h1 className="text-[26px] font-black text-[var(--pochita-text)] leading-tight tracking-tight">나의 통계</h1>
        <p className="text-[13px] text-gray-500 mt-0.5">{user.nickname}의 찬란한 타락 기록</p>
      </div>

      <div className="px-4 space-y-4">
        {/* Summary cards */}
        <div className="grid grid-cols-2 gap-3">
          {[
            { label: "오늘 딴짓", value: todaySec > 0 ? formatTimeKorean(todaySec) : "0초", sub: `${todaySessions.length}회 세션`, color: "var(--pochita-orange)" },
            { label: "누적 딴짓", value: totalSec > 0 ? formatTimeKorean(totalSec) : "0초", sub: `총 ${sessions.length}회`, color: "var(--pochita-orange)" },
            { label: "세션 평균", value: avgSec > 0 ? formatTimeKorean(avgSec) : "-", sub: "세션당 평균", color: "var(--pochita-orange)" },
            { label: "최장 기록", value: sessions.length > 0 ? formatTimeKorean(Math.max(...sessions.map(s => s.duration ?? 0))) : "-", sub: "단일 세션", color: "var(--pochita-orange)" },
          ].map(s => (
            <div key={s.label} className="p-4 rounded-[20px] bg-white border border-gray-200 shadow-sm flex flex-col justify-between h-[100px]">
              <p className="text-[13px] font-bold text-gray-500">{s.label}</p>
              <div>
                 <p className="text-[18px] font-bold mt-1" style={{ color: s.color, letterSpacing: "-0.02em" }}>{s.value}</p>
                 <p className="text-[12px] text-gray-400 mt-0.5 font-medium">{s.sub}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Weekly chart */}
        <div className="p-5 rounded-[24px] bg-white border border-gray-200 shadow-sm">
          <p className="text-[15px] font-bold text-[var(--pochita-text)] mb-5">최근 7일</p>
          <div className="flex items-end gap-2 h-28">
            {days.map((d, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-1.5">
                <div className="w-full rounded-t-lg transition-all"
                  style={{ height: `${(d.sec / maxDaySec) * 90}px`, background: d.sec > 0 ? "var(--pochita-orange)" : "#F2F4F6", minHeight: "6px", opacity: i === 6 ? 1 : 0.4 }} />
                <span className="text-[11px] font-bold text-gray-500">{d.label}</span>
              </div>
            ))}
          </div>
          <div className="mt-4 pt-3 border-t border-gray-100 flex justify-between items-center">
            <p className="text-[12px] font-bold text-gray-500">이번 주 총합</p>
            <p className="text-[14px] font-bold text-[var(--pochita-text)]">{formatTimeKorean(days.reduce((s, d) => s + d.sec, 0))}</p>
          </div>
        </div>

        {/* Category breakdown */}
        {catBreakdown.length > 0 && (
          <div className="rounded-[24px] bg-white border border-gray-200 shadow-sm overflow-hidden">
            <div className="p-5 pb-2">
              <p className="text-[15px] font-bold text-[var(--pochita-text)]">카테고리별 딴짓</p>
            </div>
            <div className="px-5 pb-5 pt-3 space-y-4">
              {catBreakdown.map(c => (
                <div key={c.id} className="flex items-center gap-3">
                  <span className="text-2xl w-8 text-center">{c.emoji}</span>
                  <div className="flex-1">
                    <div className="flex justify-between text-[13px] mb-1 font-bold">
                      <span className="text-gray-600">{c.label}</span>
                      <span style={{ color: c.color }}>{formatTimeKorean(c.sec)}</span>
                    </div>
                    <div className="h-2 rounded-full overflow-hidden bg-gray-100">
                      <div className="h-full rounded-full transition-all" style={{ width: `${(c.sec / maxCatSec) * 100}%`, background: c.color }} />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Achievements */}
        <div className="rounded-[24px] bg-white border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-5 pb-2 border-b border-gray-100">
            <p className="text-[15px] font-bold text-[var(--pochita-text)]">업적</p>
          </div>
          <div>
            {achievements.map((a, i) => (
              <div key={a.label} className={`flex items-center gap-4 p-4 ${i !== achievements.length - 1 ? 'border-b border-gray-100' : ''}`} style={{ opacity: a.done ? 1 : 0.6 }}>
                <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl bg-gray-50 border border-gray-100 shadow-sm" style={{ filter: a.done ? "none" : "grayscale(1)" }}>
                  {a.emoji}
                </div>
                <div className="flex-1">
                  <p className="text-[15px] font-bold" style={{ color: "var(--pochita-text)" }}>{a.label}</p>
                  <p className="text-[12px] text-gray-500 font-medium mt-0.5">{a.desc}</p>
                </div>
                {a.done && <span className="text-[11px] px-2.5 py-1 rounded-lg font-bold bg-orange-50 text-[var(--pochita-orange)] border border-orange-100">달성</span>}
              </div>
            ))}
          </div>
        </div>

        {sessions.length === 0 && (
          <div className="py-12 mt-6 text-center bg-white rounded-[24px] border border-gray-200 shadow-sm">
            <p className="text-4xl mb-3">📊</p>
            <p className="text-[15px] font-bold text-gray-700">아직 딴짓 기록이 없어요</p>
            <p className="text-[13px] text-gray-500 mt-1 mb-5">타이머를 시작해 첫 기록을 남겨보세요</p>
            <button onClick={() => router.push("/home")}
              className="px-6 py-3 rounded-xl text-[14px] font-bold text-white shadow-sm"
              style={{ background: "var(--pochita-orange)" }}>
              딴짓 시작하기
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
