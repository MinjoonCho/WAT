"use client";
import Image from "next/image";
import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, SessionStore, TimerStore, GroupStore } from "@/lib/store";
import { CATEGORIES, formatTime, formatTimeKorean } from "@/lib/data";
import type { User, Group } from "@/lib/types";

export default function HomePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [activeTimer, setActiveTimer] = useState(TimerStore.get());
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [showCategorySheet, setShowCategorySheet] = useState(false);
  const [selectedCat, setSelectedCat] = useState<string | null>(null);
  const [myGroups, setMyGroups] = useState<Group[]>([]);
  const [todaySeconds, setTodaySeconds] = useState(0);

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    const groups = GroupStore.getUserGroups(u.id);
    setMyGroups(groups);
    const todaySessions = SessionStore.getTodaySessions(u.id);
    setTodaySeconds(todaySessions.reduce((sum, s) => sum + (s.duration ?? 0), 0));
  }, [router]);

  useEffect(() => {
    const timer = TimerStore.get();
    setActiveTimer(timer);
    if (!timer) return;
    const interval = setInterval(() => {
      const t = TimerStore.get();
      if (t) setElapsedSeconds(TimerStore.getElapsedSeconds(t));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const handleStartDanit = useCallback(() => {
    if (!selectedCat || !user) return;
    const session = SessionStore.create(user.id, selectedCat);
    TimerStore.start(session.id, user.id, selectedCat);
    router.push(`/timer?cat=${selectedCat}`);
  }, [selectedCat, user, router]);

  if (!user) return (
    <div className="min-h-screen bg-[var(--pochita-bg)] flex items-center justify-center">
      <div className="w-8 h-8 flex items-center justify-center text-2xl animate-spin">🤔</div>
    </div>
  );

  const activeCat = CATEGORIES.find(c => c.id === activeTimer?.categoryId);

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] font-sans">
      {/* Header */}
      <div className="px-4 py-3 flex items-center justify-between bg-white border-b border-gray-200">
        <div className="flex items-center gap-2">
          <div className="relative w-7 h-7">
            <Image src="/pochita-logo.png" alt="포치타" fill className="object-contain" />
          </div>
          <h1 className="text-lg font-bold" style={{ color: "var(--pochita-orange)", fontFamily: "'Black Han Sans', sans-serif" }}>포치타</h1>
        </div>
        <button onClick={() => router.push("/profile")}
          className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center text-sm bg-white overflow-hidden shadow-sm">
          {user.avatarEmoji}
        </button>
      </div>

      <div className="px-3 py-4 space-y-4">
        {/* Main CTA Section (Dark Card + Orange Button) */}
        <div className="rounded-2xl overflow-hidden shadow-sm border border-[var(--pochita-border)]">
          {activeTimer && activeCat ? (
            <div className="bg-[var(--pochita-text)] p-4 flex items-center gap-3">
               <div className="w-12 h-12 rounded-xl flex items-center justify-center text-3xl spin-active bg-gray-800">
                {activeCat.emoji}
               </div>
               <div className="flex-1 text-white">
                 <p className="text-base font-bold text-white">{activeCat.label} 딴짓 중!</p>
                 <p className="text-sm text-gray-300">현재 <span style={{ color: "var(--pochita-orange)" }}>{formatTimeKorean(elapsedSeconds)}</span> 진행</p>
               </div>
            </div>
          ) : (
            <div className="bg-[var(--pochita-text)] p-4 flex items-center gap-3">
              <div className="relative w-12 h-12 bg-white rounded-xl p-1 shrink-0 shadow-inner">
                <Image src="/pochita-logo.png" alt="포치타" fill className="object-contain" />
              </div>
              <div>
                <p className="text-base font-bold text-white">오늘도 열심히 딴짓하자!</p>
                <p className="text-sm text-gray-300 mt-1">오늘 누적: <span className="font-bold" style={{ color: "var(--pochita-orange)" }}>{formatTimeKorean(todaySeconds)}</span></p>
              </div>
            </div>
          )}

          {activeTimer && activeCat ? (
            <button onClick={() => router.push(`/timer?cat=${activeTimer.categoryId}`)}
              className="w-full py-3.5 bg-[var(--pochita-orange)] text-white font-bold text-[17px] active:bg-[#D44200] transition-colors">
              🔥 앱으로 돌아가기
            </button>
          ) : (
            <button onClick={() => setShowCategorySheet(true)}
              className="w-full py-3.5 bg-[var(--pochita-orange)] text-white font-bold text-[17px] active:bg-[#D44200] transition-colors shadow-inner">
              🔥 포기하기
            </button>
          )}
        </div>

        {/* 3 Info Cards */}
        <div className="flex w-full gap-2">
          {[
            { label: "오늘 딴짓", value: formatTimeKorean(todaySeconds) || "0초", bold: true },
            { label: "누적 세션", value: `${SessionStore.getTodaySessions(user.id).length}회` },
            { label: "내 그룹", value: `${myGroups.length}개` },
          ].map(s => (
            <div key={s.label} className="flex-1 py-2.5 rounded-xl text-center bg-white border border-[var(--pochita-border)] shadow-sm">
              <p className="text-[11px] text-gray-500 mb-0.5 font-medium">{s.label}</p>
              <p className={`text-sm tracking-tight ${s.bold ? 'font-bold' : 'font-bold'}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Groups Section */}
        <div>
          <div className="flex items-center justify-between px-1 mb-1.5 border-b border-gray-300 pb-1">
            <h2 className="text-sm font-bold text-[var(--pochita-text)] tracking-tight">그룹 활동</h2>
            <button onClick={() => router.push("/groups")} className="text-xs text-[var(--pochita-orange)] flex items-center gap-0.5">전체보기 <span className="font-light">›</span></button>
          </div>
          
          <div className="space-y-2">
            {myGroups.length > 0 ? myGroups.slice(0, 3).map(g => {
              const members = GroupStore.getMembers(g.id);
              return (
                <button key={g.id} onClick={() => router.push(`/groups/${g.id}`)}
                  className="w-full px-4 py-3 rounded-[24px] bg-white border border-[var(--pochita-border)] shadow-sm flex items-center justify-between active:bg-gray-50 transition-colors text-left"
                >
                  <div className="flex items-center gap-3">
                    <div className="text-3xl shrink-0">{g.emoji}</div>
                    <div className="flex flex-col justify-center">
                      <p className="text-sm font-bold truncate max-w-[140px] leading-snug">{g.name}</p>
                      <p className="text-xs text-gray-400 mt-0.5 truncate max-w-[140px]">{g.description || "포치타 그룹"}</p>
                    </div>
                  </div>
                  <div className="flex flex-col items-end justify-center shrink-0">
                     <p className="text-xs text-gray-400 leading-snug">{members.length}명</p>
                     <p className="text-xs font-bold mt-0.5" style={{ color: "var(--pochita-orange)" }}>오늘 0분</p>
                  </div>
                </button>
              );
            }) : (
              <button onClick={() => router.push("/groups")}
                className="w-full py-6 rounded-[24px] bg-white border border-dashed border-gray-400 text-center flex flex-col items-center gap-2 active:bg-gray-50"
              >
                <span className="text-2xl">👥</span>
                <span className="text-sm font-bold text-gray-600">아직 그룹이 없어요</span>
                <span className="text-xs text-blue-500 border border-blue-500 rounded px-2 py-0.5">그룹 가입하기</span>
              </button>
            )}
          </div>
        </div>

        {/* University Ranking Section */}
        <div className="mt-6">
          <div className="flex items-center justify-between px-1 mb-1.5 border-b border-gray-300 pb-1">
            <h2 className="text-sm font-bold text-[var(--pochita-text)] tracking-tight">🏫 학교 딴짓 랭킹</h2>
            <button onClick={() => router.push("/ranking")} className="text-xs text-[var(--pochita-orange)] flex items-center gap-0.5">전체보기 <span className="font-light">›</span></button>
          </div>
          
          <div className="px-2 py-1 w-full bg-white border border-[var(--pochita-border)] rounded-[20px] shadow-sm flex items-center">
             <div className="px-2 w-full flex items-center h-12 justify-between">
                <div className="flex items-center gap-2">
                  <span className="text-xl">🥇</span>
                  <span className="text-[15px] font-bold text-[var(--pochita-text)]">연세대학교</span>
                  <span className="text-[13px] ml-1" style={{ color: "var(--pochita-orange)" }}>8,547분</span>
                </div>
             </div>
          </div>
          <p className="text-[11px] text-gray-500 mt-2 px-2">
            연세대학교의 랭킹을 확인해보세요
          </p>
        </div>
      </div>

      {/* Category Selection Bottom Sheet */}
      {showCategorySheet && (
        <div className="fixed inset-0 z-50 flex items-end bg-black/60"
          onClick={() => setShowCategorySheet(false)}>
          <div className="w-full bg-white rounded-t-3xl pt-2 pb-8 slide-up shadow-2xl"
            onClick={e => e.stopPropagation()}>
            <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto my-3" />
            <div className="px-5">
              <h3 className="text-base font-bold text-[var(--pochita-text)] mb-1 tracking-tight">오늘의 딴짓 종류는?</h3>
              <p className="text-[13px] text-gray-500 mb-4">어떤 방식으로 망할 예정인가요?</p>
              
              <div className="grid grid-cols-4 gap-2.5 mb-6">
                {CATEGORIES.map(cat => {
                  const sel = selectedCat === cat.id;
                  return (
                    <button key={cat.id} onClick={() => setSelectedCat(sel ? null : cat.id)}
                      className="aspect-square rounded-2xl flex flex-col items-center justify-center gap-1.5 transition-all"
                      style={{ 
                        background: sel ? `${cat.color}11` : "white", 
                        border: `1px solid ${sel ? cat.color : "#E5E5E5"}`,
                        boxShadow: sel ? `0 0 0 1px ${cat.color}` : "none"
                      }}>
                      <span className="text-2xl">{cat.emoji}</span>
                      <span className="text-[11px] font-bold" style={{ color: sel ? cat.color : "#555" }}>{cat.label}</span>
                    </button>
                  );
                })}
              </div>
              
              <button onClick={handleStartDanit} disabled={!selectedCat}
                className="w-full py-4 rounded-xl font-bold text-white text-[17px] active:scale-[0.98] transition-all disabled:opacity-40 disabled:bg-gray-300"
                style={{ background: selectedCat ? "var(--pochita-orange)" : "" }}>
                {selectedCat ? "🔥 딴짓 시작" : "선택해주세요"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
