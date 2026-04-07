"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, GroupStore } from "@/lib/store";
import type { User } from "@/lib/types";

const GROUP_EMOJIS = ["🔥","💀","😭","🎮","📺","🍺","💜","⚡","🌙","🎯","💩","🤡"];

export default function CreateGroupPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [emoji, setEmoji] = useState("🔥");
  const [isPublic, setIsPublic] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
  }, [router]);

  const handleCreate = () => {
    if (!user) return;
    if (!name.trim()) { setError("그룹 이름을 입력해주세요."); return; }
    if (name.trim().length < 2) { setError("그룹 이름은 2자 이상이어야 해요."); return; }
    setLoading(true);
    setTimeout(() => {
      const group = GroupStore.create(name.trim(), desc.trim(), emoji, user.id, isPublic);
      router.replace(`/groups/${group.id}`);
    }, 400);
  };

  if (!user) return null;

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] px-4 pt-12 pb-10">
      {/* Header */}
      <div className="flex items-center gap-3 mb-8">
        <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-[var(--pochita-card)] flex items-center justify-center text-[var(--pochita-text-secondary)] border border-[var(--pochita-border)]">
          ←
        </button>
        <div>
          <h1 className="text-xl font-bold text-[var(--pochita-text)]">그룹 만들기</h1>
          <p className="text-xs text-[var(--pochita-text-secondary)]">같이 타락할 공간을 만들어요</p>
        </div>
      </div>

      <div className="space-y-5">
        {/* Emoji picker */}
        <div>
          <p className="text-xs font-bold text-[var(--pochita-text-secondary)] mb-2 uppercase tracking-wider">그룹 아이콘</p>
          <div className="flex gap-2 flex-wrap">
            {GROUP_EMOJIS.map(e => (
              <button key={e} onClick={() => setEmoji(e)}
                className="w-11 h-11 rounded-xl text-2xl flex items-center justify-center transition-all"
                style={{ background: emoji === e ? "#FF6B0033" : "var(--pochita-card)", border: `2px solid ${emoji === e ? "#FF6B00" : "var(--pochita-border)"}` }}>
                {e}
              </button>
            ))}
          </div>
        </div>

        {/* Name */}
        <div>
          <p className="text-xs font-bold text-[var(--pochita-text-secondary)] mb-2 uppercase tracking-wider">그룹 이름 *</p>
          <input
            placeholder="예: 경영학과 시험기간 멸망단"
            value={name} onChange={e => { setName(e.target.value); setError(""); }}
            maxLength={20}
            className="w-full px-5 py-4 rounded-2xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] focus:border-transparent transition-all"
          />
          <p className="text-right text-xs text-gray-600 mt-1">{name.length}/20</p>
        </div>

        {/* Description */}
        <div>
          <p className="text-xs font-bold text-[var(--pochita-text-secondary)] mb-2 uppercase tracking-wider">소개 (선택)</p>
          <textarea
            placeholder="우리 그룹은 어떤 사람들인가요?"
            value={desc} onChange={e => setDesc(e.target.value)}
            maxLength={80} rows={3}
            className="w-full px-5 py-4 rounded-2xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] focus:border-transparent transition-all resize-none"
          />
          <p className="text-right text-xs text-gray-600 mt-1">{desc.length}/80</p>
        </div>

        {/* Public toggle */}
        <div className="flex items-center justify-between p-4 rounded-2xl" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
          <div>
            <p className="text-sm font-bold text-[var(--pochita-text)]">공개 그룹</p>
            <p className="text-xs text-[var(--pochita-text-secondary)]">누구나 검색하고 참여할 수 있어요</p>
          </div>
          <button onClick={() => setIsPublic(v => !v)}
            className="w-12 h-6 rounded-full transition-all relative"
            style={{ background: isPublic ? "#FF6B00" : "var(--pochita-border)" }}>
            <div className="absolute top-1 w-4 h-4 rounded-full bg-white transition-all"
              style={{ left: isPublic ? "calc(100% - 20px)" : "4px" }} />
          </button>
        </div>

        {/* Preview */}
        <div className="p-4 rounded-2xl" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
          <p className="text-xs text-[var(--pochita-text-secondary)] mb-3">미리보기</p>
          <div className="flex items-center gap-3">
            <span className="text-2xl">{emoji}</span>
            <div>
              <p className="text-sm font-bold text-[var(--pochita-text)]">{name || "그룹 이름"}</p>
              <p className="text-xs text-[var(--pochita-text-secondary)]">{desc || "소개가 없어요"}</p>
            </div>
            <div className="ml-auto">
              <span className="text-xs px-2 py-1 rounded-lg" style={{ background: isPublic ? "#FF6B0022" : "var(--pochita-border)", color: isPublic ? "#FF6B00" : "#666" }}>
                {isPublic ? "공개" : "비공개"}
              </span>
            </div>
          </div>
        </div>

        {error && <p className="text-xs text-red-400 text-center">{error}</p>}

        <button onClick={handleCreate} disabled={loading}
          className="w-full py-4 rounded-2xl font-bold text-white text-base transition-all active:scale-95 disabled:opacity-60"
          style={{ background: "var(--pochita-orange)", boxShadow: "0 8px 24px none" }}>
          {loading ? "만드는 중..." : "🔥 그룹 만들기"}
        </button>
      </div>
    </div>
  );
}
