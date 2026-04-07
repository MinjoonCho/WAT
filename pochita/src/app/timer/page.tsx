"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { AuthStore, SessionStore, TimerStore, GroupStore } from "@/lib/store";
import { CATEGORIES, formatTime, formatTimeKorean, getRandomMessage, generateAcrosticPoem, SNARKY_MESSAGES, FOCUS_OUT_MESSAGES } from "@/lib/data";
import type { User, Group } from "@/lib/types";

function TimerContent() {
  const router = useRouter();
  const params = useSearchParams();
  const catId = params.get("cat") ?? "lazy";
  const category = CATEGORIES.find(c => c.id === catId) ?? CATEGORIES[7];

  const [user, setUser] = useState<User | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const [showStop, setShowStop] = useState(false);
  const [showResult, setShowResult] = useState(false);
  const [resultSeconds, setResultSeconds] = useState(0);
  const [snarkyMsg, setSnarkyMsg] = useState("");
  const [poem, setPoem] = useState<{ char: string; line: string }[]>([]);
  const [notification, setNotification] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"group" | "strangers">("group");
  const [myGroups, setMyGroups] = useState<Group[]>([]);
  const notifTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Force dark mode
  useEffect(() => {
    document.body.classList.add("dark");
    return () => {
      document.body.classList.remove("dark");
    };
  }, []);

  // Auth + init
  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    setMyGroups(GroupStore.getUserGroups(u.id));

    // Ensure timer is running
    const existing = TimerStore.get();
    if (!existing) {
      const session = SessionStore.create(u.id, catId);
      TimerStore.start(session.id, u.id, catId);
    }
  }, [router, catId]);

  // Blur notification
  useEffect(() => {
    const handleBlur = () => {
      if (!isPaused) {
        const msg = getRandomMessage(FOCUS_OUT_MESSAGES as unknown as string[]);
        setNotification(msg);
        if (notifTimerRef.current) clearTimeout(notifTimerRef.current);
        notifTimerRef.current = setTimeout(() => setNotification(null), 4000);
      }
    };
    window.addEventListener("blur", handleBlur);
    return () => window.removeEventListener("blur", handleBlur);
  }, [isPaused]);

  // Tick
  useEffect(() => {
    const interval = setInterval(() => {
      const t = TimerStore.get();
      if (t) setElapsed(TimerStore.getElapsedSeconds(t));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const handlePause = () => {
    if (isPaused) { TimerStore.resume(); setIsPaused(false); }
    else { TimerStore.pause(); setIsPaused(true); }
  };

  const handleStop = useCallback(() => {
    const t = TimerStore.get();
    if (!t) return;
    const sec = TimerStore.getElapsedSeconds(t);
    SessionStore.finish(t.sessionId);
    TimerStore.clear();
    setResultSeconds(sec);
    setSnarkyMsg(getRandomMessage(SNARKY_MESSAGES as unknown as string[]));
    setPoem(generateAcrosticPoem(category.label, formatTimeKorean(sec)));
    setShowStop(false);
    setShowResult(true);
  }, [category]);

  const radius = 110;
  const circ = 2 * Math.PI * radius;
  const progress = ((elapsed % 3600) / 3600) * circ;

  const demoGroupMembers = user ? [
    ...(myGroups.length > 0 ? GroupStore.getMembers(myGroups[0].id).map(m => {
      const mu = AuthStore.getUserById(m.userId);
      return mu ? { name: mu.nickname, emoji: mu.avatarEmoji, status: Math.random() > 0.4 ? "딴짓중" : "쉬는중", category: CATEGORIES[Math.floor(Math.random() * CATEGORIES.length)] } : null;
    }).filter(Boolean) : []),
  ] : [];

  const demoStrangers = CATEGORIES.map(c => ({
    category: c,
    count: Math.floor(Math.random() * 200) + 10,
  }));

  return (
    <div className="min-h-screen flex flex-col relative overflow-hidden">
      {/* BG glow */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 rounded-full blur-3xl pointer-events-none opacity-10"
        style={{ background: `radial-gradient(circle, ${category.color}, transparent 70%)` }} />

      {/* Notification banner */}
      {notification && (
        <div className="absolute top-4 left-1/2 -translate-x-1/2 z-50 slide-up cursor-pointer w-[90%] max-w-sm"
          onClick={() => setNotification(null)}>
          <div className="px-4 py-3 rounded-2xl text-white text-sm font-bold text-center shadow-xl"
            style={{ background: `linear-gradient(135deg, ${category.color}, var(--pochita-orange-dark))`, boxShadow: `0 0 24px ${category.color}80` }}>
            {notification}
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-12 pb-4">
        <button onClick={() => setShowStop(true)} className="w-9 h-9 rounded-full bg-[var(--pochita-card)] flex items-center justify-center text-[var(--pochita-text-secondary)] border border-[var(--pochita-border)]">
          ←
        </button>
        <div className="text-center">
          <p className="text-xs text-[var(--pochita-text-secondary)]">딴짓 중</p>
          <p className="text-sm font-bold" style={{ color: category.color }}>{category.emoji} {category.label}</p>
        </div>
        <button onClick={handlePause}
          className="px-3 py-1.5 rounded-lg text-xs font-bold transition-all"
          style={{ background: isPaused ? `${category.color}33` : "var(--pochita-card)", color: isPaused ? category.color : "var(--pochita-text-secondary)", border: `1px solid ${isPaused ? category.color : "var(--pochita-border)"}` }}>
          {isPaused ? "▶ 재개" : "⏸ 일시정지"}
        </button>
      </div>

      {/* Circular Timer */}
      <div className="flex flex-col items-center justify-center py-6">
        <div className="relative">
          <svg width="260" height="260" className="-rotate-90">
            <circle cx="130" cy="130" r={radius} fill="none" stroke="var(--pochita-card)" strokeWidth="10" />
            <circle cx="130" cy="130" r={radius} fill="none" stroke={category.color} strokeWidth="10"
              strokeLinecap="round" strokeDasharray={circ} strokeDashoffset={circ - progress}
              style={{ filter: `drop-shadow(0 0 10px ${category.color})`, transition: "stroke-dashoffset 0.8s ease" }} />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className={`text-4xl mb-2 ${!isPaused ? "spin-active" : ""}`}>{category.emoji}</span>
            <p className="text-5xl font-black" style={{ fontFamily: "'Black Han Sans', sans-serif",
              color: isPaused ? "var(--pochita-text-secondary)" : "var(--pochita-text)", textShadow: isPaused ? "none" : `0 0 24px ${category.color}99` }}>
              {formatTime(elapsed)}
            </p>
            {isPaused && <p className="text-xs text-[var(--pochita-text-secondary)] mt-1 animate-pulse">일시정지 중</p>}
          </div>
        </div>

        {/* Stop button */}
        <button onClick={() => setShowStop(true)}
          className="mt-4 px-8 py-3.5 rounded-2xl font-black text-white text-base transition-all active:scale-95"
          style={{ background: `linear-gradient(135deg, ${category.color}, var(--pochita-orange-dark))`, boxShadow: `0 8px 24px ${category.color}66` }}>
          🏁 딴짓 끝내기
        </button>
      </div>

      {/* Activity tabs */}
      <div className="flex-1 px-4">
        <div className="flex rounded-xl overflow-hidden mb-3 bg-[var(--pochita-card)] border border-[var(--pochita-border)]">
          {["group", "strangers"].map(t => (
            <button key={t} onClick={() => setActiveTab(t as "group" | "strangers")}
              className="flex-1 py-2.5 text-sm font-bold transition-all"
              style={{ background: activeTab === t ? "var(--pochita-orange)" : "transparent", color: activeTab === t ? "var(--pochita-text)" : "var(--pochita-text-secondary)" }}>
              {t === "group" ? "👥 그룹원" : "🌍 같은 딴짓"}
            </button>
          ))}
        </div>

        {activeTab === "group" ? (
          <div className="space-y-2">
            {demoGroupMembers.length === 0 ? (
              <div className="py-8 text-center bg-[var(--pochita-card)] rounded-xl border border-[var(--pochita-border)]">
                <p className="text-[var(--pochita-text-secondary)] text-sm">그룹원이 없어요</p>
                <button onClick={() => router.push("/groups")} className="mt-2 text-xs text-[var(--pochita-orange)]">
                  그룹 만들기 →
                </button>
              </div>
            ) : (
              // @ts-expect-error dynamic demo data
              demoGroupMembers.map((m, i) => m && (
                <div key={i} className="flex items-center gap-3 p-3 rounded-xl bg-[var(--pochita-card)] border border-[var(--pochita-border)]">
                  <span className="text-xl">{m.emoji}</span>
                  <div className="flex-1">
                    <p className="text-sm font-bold text-[var(--pochita-text)]">{m.name}</p>
                    <p className="text-xs text-[var(--pochita-text-secondary)]">{m.status}</p>
                  </div>
                  {/* @ts-expect-error dynamic */}
                  <span className="text-xs px-2 py-1 rounded-lg" style={{ background: `${m.category.color}22`, color: m.category.color }}>
                    {/* @ts-expect-error dynamic */}
                    {m.category.emoji} {m.category.label}
                  </span>
                </div>
              ))
            )}
          </div>
        ) : (
          <div className="space-y-2">
            {demoStrangers.sort((a,b) => b.count - a.count).map(s => (
              <div key={s.category.id} className={`flex items-center gap-3 p-3 rounded-xl transition-all ${s.category.id === catId ? "ring-1" : ""}`}
                style={{ background: s.category.id === catId ? `${s.category.color}11` : "var(--pochita-card)", border: `1px solid ${s.category.id === catId ? s.category.color + "44" : "var(--pochita-border)"}` }}>
                <span className="text-xl">{s.category.emoji}</span>
                <div className="flex-1">
                  <p className="text-sm font-bold text-[var(--pochita-text)]">{s.category.label}</p>
                  <div className="h-1.5 mt-1.5 rounded-full overflow-hidden bg-[var(--pochita-bg)] border border-[var(--pochita-border)]">
                    <div className="h-full rounded-full" style={{ width: `${(s.count / 300) * 100}%`, background: s.category.color }} />
                  </div>
                </div>
                <p className="text-sm font-bold" style={{ color: s.category.id === catId ? s.category.color : "var(--pochita-text-secondary)" }}>
                  {s.count}명
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Stop confirm modal */}
      {showStop && (
        <div className="fixed inset-0 z-50 flex items-end justify-center px-4 pb-8" style={{ background: "rgba(0,0,0,0.8)" }}>
          <div className="w-full max-w-sm rounded-3xl p-6 slide-up bg-[var(--pochita-card)] border border-[var(--pochita-border)]">
            <p className="text-lg font-black text-[var(--pochita-text)] text-center mb-1">진짜 끝낼 건가요?</p>
            <p className="text-sm text-[var(--pochita-text-secondary)] text-center mb-6">
              {formatTimeKorean(elapsed)} 동안 열심히 딴짓했습니다 👏
            </p>
            <div className="flex gap-3">
              <button onClick={() => setShowStop(false)} className="flex-1 py-3.5 rounded-xl font-bold bg-[var(--pochita-bg)] text-[var(--pochita-text)] border border-[var(--pochita-border)]">
                계속 딴짓
              </button>
              <button onClick={handleStop} className="flex-1 py-3.5 rounded-xl font-black text-white" style={{ background: `linear-gradient(135deg, ${category.color}, var(--pochita-orange-dark))` }}>
                🏁 종료
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Result modal */}
      {showResult && (
        <div className="fixed inset-0 z-50 flex flex-col bg-[var(--pochita-bg)] overflow-y-auto">
          <div className="flex-1 px-4 py-10">
            <div className="max-w-sm mx-auto">
              {/* Card */}
              <div className="rounded-3xl overflow-hidden mb-6 bounce-in bg-[var(--pochita-card)]"
                style={{ border: `1px solid ${category.color}44`, boxShadow: `0 20px 60px ${category.color}22` }}>
                <div className="px-6 py-5" style={{ background: `linear-gradient(135deg,${category.color}22,${category.color}11)`, borderBottom: `1px solid ${category.color}22` }}>
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl" style={{ background: `${category.color}22` }}>
                      {category.emoji}
                    </div>
                    <div>
                      <p className="text-xs text-[var(--pochita-text-secondary)]">딴짓 완료</p>
                      <p className="text-base font-black text-[var(--pochita-text)]">{category.label} 딴짓</p>
                      {user && <p className="text-xs text-[var(--pochita-text-secondary)]">{user.nickname} · {user.university}</p>}
                    </div>
                  </div>
                </div>
                <div className="px-6 py-5 text-center">
                  <p className="text-xs text-[var(--pochita-text-secondary)] mb-1">총 딴짓 시간</p>
                  <p className="text-5xl font-black mb-1" style={{ fontFamily: "'Black Han Sans', sans-serif", color: category.color, textShadow: `0 0 20px ${category.color}66` }}>
                    {formatTime(resultSeconds)}
                  </p>
                  <p className="text-sm text-[var(--pochita-text-secondary)]">{formatTimeKorean(resultSeconds)}</p>
                </div>
                <div className="mx-4 mb-4 px-4 py-3 rounded-xl bg-[var(--pochita-bg)] border border-[var(--pochita-border)]">
                  <p className="text-sm text-[var(--pochita-text)] text-center leading-relaxed">{snarkyMsg}</p>
                </div>
                <div className="mx-4 mb-4">
                  <p className="text-xs text-[var(--pochita-text-secondary)] text-center mb-3">✨ 오늘의 포/치/타 삼행시</p>
                  <div className="space-y-2">
                    {poem.map((l, i) => (
                      <div key={i} className="flex items-start gap-3">
                        <span className="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-black flex-shrink-0"
                          style={{ background: `${category.color}22`, color: category.color }}>{l.char}</span>
                        <p className="text-sm text-[var(--pochita-text)] pt-1.5 leading-relaxed">{l.line}</p>
                      </div>
                    ))}
                  </div>
                </div>
                <div className="mx-4 mb-5 py-2.5 rounded-xl text-center text-xs font-bold"
                  style={{ background: `${category.color}11`, border: `1px solid ${category.color}33`, color: category.color }}>
                  🏅 딴짓 {Math.floor(resultSeconds / 60) >= 60 ? "마스터" : Math.floor(resultSeconds / 60) >= 30 ? "달인" : "입문자"} 달성
                </div>
              </div>

              {/* Actions */}
              <div className="space-y-3">
                <button onClick={() => {
                  const text = `🔥 포치타 딴짓 기록\n${user?.nickname}이 ${category.emoji}${category.label}을(를) ${formatTimeKorean(resultSeconds)} 딴짓!\n\n${poem.map(p => `${p.char}: ${p.line}`).join("\n")}\n\n#포치타 #딴짓타이머 #학점멸망전`;
                  navigator.clipboard?.writeText(text);
                }}
                  className="w-full py-4 rounded-2xl font-black text-white text-base transition-all active:scale-95"
                  style={{ background: `linear-gradient(135deg, ${category.color}, var(--pochita-orange-dark))`, boxShadow: `0 8px 24px ${category.color}66` }}>
                  📤 자랑하기 (공유)
                </button>
                <div className="grid grid-cols-2 gap-3">
                  <button onClick={() => router.push("/groups")} className="py-3.5 rounded-2xl text-sm font-bold border border-[var(--pochita-border)] text-[var(--pochita-text-secondary)] hover:border-[var(--pochita-orange)] hover:text-[var(--pochita-orange)] bg-[var(--pochita-card)] transition-colors">
                    🏆 랭킹 보기
                  </button>
                  <button onClick={() => router.replace("/home")} className="py-3.5 rounded-2xl text-sm font-bold border border-[var(--pochita-border)] text-[var(--pochita-text-secondary)] hover:border-[var(--pochita-orange)] hover:text-[var(--pochita-orange)] bg-[var(--pochita-card)] transition-colors">
                    🔥 또 딴짓
                  </button>
                </div>
                <button onClick={() => router.replace("/home")} className="w-full py-3 text-sm text-[var(--pochita-text-secondary)] hover:text-[var(--pochita-text)] transition-colors">홈으로</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function TimerPage() {
  return <Suspense fallback={<div className="min-h-screen bg-[var(--pochita-bg)] flex items-center justify-center"><div className="w-10 h-10 rounded-full border-4 border-[var(--pochita-orange)] border-t-transparent animate-spin" /></div>}><TimerContent /></Suspense>;
}
