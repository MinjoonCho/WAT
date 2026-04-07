"use client";
import Image from "next/image";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, SessionStore, GroupStore } from "@/lib/store";
import { UNIVERSITIES, YEARS, AVATAR_EMOJIS } from "@/lib/types";
import { formatTimeKorean } from "@/lib/data";
import type { User } from "@/lib/types";

export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [editing, setEditing] = useState(false);
  const [nickname, setNickname] = useState("");
  const [university, setUniversity] = useState("");
  const [uniInput, setUniInput] = useState("");
  const [year, setYear] = useState("");
  const [avatarEmoji, setAvatarEmoji] = useState("");
  const [uniOpen, setUniOpen] = useState(false);
  const [saved, setSaved] = useState(false);

  const filteredUnis = UNIVERSITIES.filter(u => u.includes(uniInput)).slice(0, 5);

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    setNickname(u.nickname);
    setUniversity(u.university);
    setUniInput(u.university);
    setYear(u.year);
    setAvatarEmoji(u.avatarEmoji);
  }, [router]);

  const handleSave = () => {
    if (!user) return;
    const updated = AuthStore.updateCurrentUser({ nickname, university, year, avatarEmoji });
    if (updated) {
      setUser(updated);
      setEditing(false);
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    }
  };

  const handleLogout = () => {
    AuthStore.logout();
    router.replace("/login");
  };

  if (!user) return null;

  const totalSessions = SessionStore.getUserSessions(user.id);
  const totalSec = totalSessions.reduce((s, x) => s + (x.duration ?? 0), 0);
  const myGroups = GroupStore.getUserGroups(user.id);

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] font-sans pb-20">
      {/* Header */}
      <div className="px-5 pt-10 pb-4 flex items-center justify-between">
        <h1 className="text-[26px] font-black text-[var(--pochita-text)] leading-tight tracking-tight">더보기</h1>
        <button onClick={() => setEditing(v => !v)}
          className="px-4 py-2 rounded-xl text-[14px] font-bold bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 transition-colors shadow-sm">
          {editing ? "취소" : "편집"}
        </button>
      </div>

      {/* Toast */}
      {saved && (
        <div className="fixed top-10 left-1/2 -translate-x-1/2 z-50 px-6 py-3 rounded-full text-[14px] font-bold text-white shadow-lg slide-up" style={{ background: "var(--pochita-orange)" }}>
          ✓ 안전하게 저장되었어요
        </div>
      )}

      <div className="px-4 space-y-4">
        {/* Profile card */}
        <div className="p-6 rounded-[24px] bg-white border border-gray-200 shadow-sm">
          {editing ? (
            <div className="space-y-5">
              {/* Avatar */}
              <div className="grid grid-cols-5 gap-2">
                {AVATAR_EMOJIS.slice(0,10).map(e => (
                  <button key={e} onClick={() => setAvatarEmoji(e)}
                    className="aspect-square rounded-xl text-[24px] flex items-center justify-center transition-all bg-gray-50"
                    style={{ 
                      background: avatarEmoji === e ? "rgba(255,107,0,0.1)" : "#F9FAFB", 
                      boxShadow: avatarEmoji === e ? "0 0 0 2px var(--pochita-orange) inset" : "0 0 0 1px #F2F4F6 inset" 
                    }}>
                    {e}
                  </button>
                ))}
              </div>

              {/* Nicckname */}
              <div>
                <p className="text-[12px] text-gray-500 font-bold mb-1.5 px-1">닉네임</p>
                <input value={nickname} onChange={e => setNickname(e.target.value)} placeholder="단호한 딴짓러"
                  className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
              </div>

              {/* University */}
              <div className="relative">
                <p className="text-[12px] text-gray-500 font-bold mb-1.5 px-1">대학교</p>
                <input value={uniInput} onChange={e => { setUniInput(e.target.value); setUniOpen(true); }}
                  onFocus={() => setUniOpen(true)} onBlur={() => setTimeout(() => setUniOpen(false), 150)}
                  placeholder="학교명 검색"
                  className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
                {uniOpen && uniInput && filteredUnis.length > 0 && (
                  <div className="absolute z-20 w-full mt-2 rounded-xl overflow-hidden shadow-lg bg-white border border-gray-100 p-1">
                    {filteredUnis.map(u => (
                      <button key={u} onMouseDown={() => { setUniversity(u); setUniInput(u); setUniOpen(false); }}
                        className="w-full px-4 py-3 text-left text-[14px] font-medium text-gray-700 hover:bg-gray-50 rounded-lg transition-colors">
                        {u}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Year */}
              <div>
                <p className="text-[12px] text-gray-500 font-bold mb-1.5 px-1">학년</p>
                <div className="grid grid-cols-4 gap-2">
                  {YEARS.map(y => (
                    <button key={y} onClick={() => setYear(y)}
                      className="py-3 rounded-xl text-[14px] font-bold transition-all"
                      style={{ 
                        background: year === y ? "var(--pochita-orange)" : "#F2F4F6", 
                        color: year === y ? "white" : "#8B95A1" 
                      }}>
                      {y.replace("학년","")}
                    </button>
                  ))}
                </div>
              </div>
              
              <button onClick={handleSave}
                className="w-full py-4 mt-2 rounded-xl font-bold text-white text-[16px] transition-all active:scale-[0.98]"
                style={{ background: "var(--pochita-orange)" }}>
                프로필 저장
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-5">
              <div className="w-[72px] h-[72px] rounded-[24px] flex items-center justify-center text-[36px] bg-gray-50 border border-gray-100 shadow-sm">
                {user.avatarEmoji}
              </div>
              <div className="flex-1">
                <p className="text-[18px] font-bold text-[var(--pochita-text)] mb-1">{user.nickname}</p>
                <p className="text-[13px] text-gray-500 font-medium">{user.university || "학교 미설정"}</p>
                <p className="text-[12px] text-gray-400 mt-1">{user.year} · {user.email}</p>
              </div>
            </div>
          )}
        </div>

        {/* Stats summary */}
        {!editing && (
          <div className="grid grid-cols-3 gap-3">
            {[
              { label: "총 딴짓", value: totalSec > 0 ? formatTimeKorean(totalSec) : "0초" },
              { label: "누적 세션", value: `${totalSessions.length}회` },
              { label: "참여 그룹", value: `${myGroups.length}개` },
            ].map(s => (
              <div key={s.label} className="py-4 rounded-[20px] text-center bg-white border border-gray-200 shadow-sm">
                <p className="text-[15px] font-bold text-[var(--pochita-text)] mb-1 tracking-tight">{s.value}</p>
                <p className="text-[12px] font-bold text-gray-400">{s.label}</p>
              </div>
            ))}
          </div>
        )}

        {/* App logo + branding */}
        {!editing && (
          <div className="p-6 rounded-[24px] text-center bg-white border border-gray-200 shadow-sm">
            <div className="relative w-16 h-16 mx-auto mb-3">
              <Image src="/pochita-logo.png" alt="포치타" fill className="object-contain" />
            </div>
            <p className="text-[16px] font-bold mb-0.5" style={{ color: "var(--pochita-orange)" }}>포치타</p>
            <p className="text-[12px] font-medium text-gray-400">오직 대학생들을 위한 단호한 타이머</p>
          </div>
        )}

        {/* Menu items */}
        {!editing && (
          <div className="rounded-[24px] bg-white border border-gray-200 shadow-sm overflow-hidden list-none">
            {[
              { label: "내 그룹 관리", emoji: "👥", action: () => router.push("/groups") },
              { label: "상세 통계", emoji: "📊", action: () => router.push("/stats") },
              { label: "전국 실시간 랭킹", emoji: "🏆", action: () => router.push("/ranking") },
            ].map((item, i) => (
              <button key={item.label} onClick={item.action}
                className="w-full flex items-center gap-3 px-5 py-4 transition-colors hover:bg-gray-50 active:bg-gray-100 text-left border-b border-gray-100 last:border-b-0">
                <span className="text-[20px] w-6 text-center shadow-sm rounded-md bg-gray-50 pb-0.5">{item.emoji}</span>
                <span className="text-[15px] font-bold text-[var(--pochita-text)] flex-1">{item.label}</span>
                <span className="text-gray-400 text-lg font-light leading-none mb-1">›</span>
              </button>
            ))}
          </div>
        )}

        {/* Logout */}
        {!editing && (
          <button onClick={handleLogout}
            className="w-full py-4 mt-2 rounded-[20px] text-[15px] font-bold bg-white text-red-500 border border-gray-200 shadow-sm hover:bg-gray-50 transition-colors">
            로그아웃
          </button>
        )}
      </div>
    </div>
  );
}
