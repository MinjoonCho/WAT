"use client";
import { useState, useEffect, use } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, GroupStore, SessionStore } from "@/lib/store";
import { CATEGORIES, formatTimeKorean } from "@/lib/data";
import type { User, Group, GroupMember } from "@/lib/types";

export default function GroupDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [group, setGroup] = useState<Group | null>(null);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [tab, setTab] = useState<"ranking" | "info">("ranking");
  const [showInvite, setShowInvite] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isMember, setIsMember] = useState(false);

  const reload = (u: User) => {
    const g = GroupStore.getById(id);
    setGroup(g);
    if (g) {
      setMembers(GroupStore.getMembers(id));
      setIsMember(GroupStore.isMember(id, u.id));
    }
  };

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    reload(u);
  }, [id, router]);

  const handleJoin = () => {
    if (!user) return;
    GroupStore.join(id, user.id);
    reload(user);
  };

  const handleLeave = () => {
    if (!user) return;
    GroupStore.leave(id, user.id);
    router.replace("/groups");
  };

  const handleCopyInvite = () => {
    if (!group) return;
    const msg = `포치타 그룹 초대! 아래 코드를 입력하세요 🔥\n그룹: ${group.emoji} ${group.name}\n코드: ${group.inviteCode}`;
    navigator.clipboard?.writeText(msg);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleNewCode = () => {
    if (!group || !user || group.createdBy !== user.id) return;
    GroupStore.regenerateInviteCode(id);
    reload(user);
  };

  if (!user || !group) return (
    <div className="min-h-screen bg-[var(--pochita-bg)] flex items-center justify-center">
      <div className="w-10 h-10 rounded-full border-4 border-[var(--pochita-orange)] border-t-transparent animate-spin" />
    </div>
  );

  // Build ranking data
  interface MemberStat { user: User | null; member: GroupMember; todaySec: number; totalSec: number; topCat: string }
  const rankData: MemberStat[] = members.map(m => {
    const mu = AuthStore.getUserById(m.userId);
    const todaySessions = SessionStore.getTodaySessions(m.userId);
    const allSessions = SessionStore.getUserSessions(m.userId);
    const todaySec = todaySessions.reduce((s, x) => s + (x.duration ?? 0), 0);
    const totalSec = allSessions.reduce((s, x) => s + (x.duration ?? 0), 0);
    const catCounts: Record<string, number> = {};
    allSessions.forEach(s => { catCounts[s.categoryId] = (catCounts[s.categoryId] ?? 0) + (s.duration ?? 0); });
    const topCat = Object.entries(catCounts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "lazy";
    return { user: mu, member: m, todaySec, totalSec, topCat };
  }).sort((a, b) => b.todaySec - a.todaySec);

  const isOwner = group.createdBy === user.id;

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)]">
      {/* Header */}
      <div className="px-4 pt-12 pb-4">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={() => router.back()} className="w-9 h-9 rounded-full bg-[var(--pochita-card)] flex items-center justify-center text-[var(--pochita-text-secondary)] border border-[var(--pochita-border)]">←</button>
          <div className="flex-1">
            <p className="text-xs text-[var(--pochita-text-secondary)]">그룹</p>
            <h1 className="text-xl font-bold text-[var(--pochita-text)]">{group.emoji} {group.name}</h1>
          </div>
          <button onClick={() => setShowInvite(true)} className="px-3 py-2 rounded-xl text-sm font-bold border border-[#333] text-[var(--pochita-text-secondary)] hover:border-[var(--pochita-orange)] hover:text-[var(--pochita-orange)] transition-colors">
            초대
          </button>
        </div>

        {group.description && (
          <p className="text-xs text-[var(--pochita-text-secondary)] px-1 mb-3">{group.description}</p>
        )}

        <div className="flex gap-2 mb-4">
          <div className="flex-1 p-3 rounded-xl text-center" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
            <p className="text-lg font-bold text-[var(--pochita-text)]">{members.length}</p>
            <p className="text-xs text-[var(--pochita-text-secondary)]">멤버</p>
          </div>
          <div className="flex-1 p-3 rounded-xl text-center" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
            <p className="text-lg font-bold" style={{ color: "#FF6B00" }}>
              {Math.floor(rankData.reduce((s, m) => s + m.todaySec, 0) / 60)}
            </p>
            <p className="text-xs text-[var(--pochita-text-secondary)]">오늘 합계(분)</p>
          </div>
          <div className="flex-1 p-3 rounded-xl text-center" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
            <p className="text-xs font-mono font-bold text-[var(--pochita-text)]">{group.inviteCode}</p>
            <p className="text-xs text-[var(--pochita-text-secondary)]">초대코드</p>
          </div>
        </div>

        {/* Join/Leave */}
        {!isMember ? (
          <button onClick={handleJoin}
            className="w-full py-3 rounded-xl font-bold text-white text-sm mb-4"
            style={{ background: "var(--pochita-orange)" }}>
            그룹 참여하기
          </button>
        ) : !isOwner ? (
          <button onClick={handleLeave}
            className="w-full py-2.5 rounded-xl text-sm font-bold border border-[#333] text-[var(--pochita-text-secondary)] mb-4">
            그룹 나가기
          </button>
        ) : null}
      </div>

      {/* Tabs */}
      <div className="px-4 mb-4">
        <div className="flex rounded-xl overflow-hidden" style={{ background: "var(--pochita-card)" }}>
          {[["ranking", "🏆 랭킹"], ["info", "ℹ️ 정보"]].map(([t, label]) => (
            <button key={t} onClick={() => setTab(t as "ranking" | "info")}
              className="flex-1 py-2.5 text-sm font-bold transition-all"
              style={{ background: tab === t ? "#FF6B00" : "transparent", color: tab === t ? "white" : "#666" }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="px-4 space-y-2 pb-8">
        {tab === "ranking" ? (
          rankData.length === 0 ? (
            <div className="py-12 text-center text-gray-600 text-sm">아직 딴짓 기록이 없어요</div>
          ) : (
            rankData.map((d, i) => {
              const topCatData = CATEGORIES.find(c => c.id === d.topCat);
              const maxSec = rankData[0]?.todaySec || 1;
              const isMe = d.member.userId === user.id;
              return (
                <div key={d.member.userId}
                  className="p-4 rounded-2xl flex items-center gap-3"
                  style={{ background: isMe ? "#FF6B0011" : "var(--pochita-card)", border: `1px solid ${isMe ? "#FF6B0044" : "var(--pochita-border)"}` }}>
                  <span className="text-xl font-bold w-7 text-center" style={{ color: i === 0 ? "#FFD700" : i === 1 ? "#C0C0C0" : i === 2 ? "#CD7F32" : "#555" }}>
                    {i === 0 ? "🥇" : i === 1 ? "🥈" : i === 2 ? "🥉" : `${i+1}`}
                  </span>
                  <span className="text-xl">{d.user?.avatarEmoji ?? "👤"}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-sm font-bold text-[var(--pochita-text)] truncate">{d.user?.nickname ?? "알 수 없음"}{isMe ? " (나)" : ""}</p>
                      {topCatData && <span className="text-xs px-1.5 py-0.5 rounded-md flex-shrink-0" style={{ background: `${topCatData.color}22`, color: topCatData.color }}>{topCatData.emoji}</span>}
                    </div>
                    <div className="h-1.5 rounded-full overflow-hidden" style={{ background: "var(--pochita-border)" }}>
                      <div className="h-full rounded-full transition-all" style={{ width: `${(d.todaySec / maxSec) * 100}%`, background: "#FF6B00" }} />
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-sm font-bold" style={{ color: d.todaySec > 0 ? "#FF6B00" : "#555" }}>
                      {d.todaySec > 0 ? formatTimeKorean(d.todaySec) : "-"}
                    </p>
                    <p className="text-xs text-gray-600">{d.user?.university ?? ""}</p>
                  </div>
                </div>
              );
            })
          )
        ) : (
          <div className="space-y-3">
            <div className="p-4 rounded-2xl space-y-3" style={{ background: "var(--pochita-card)", border: "1px solid #1F1F1F" }}>
              <div className="flex justify-between">
                <span className="text-xs text-[var(--pochita-text-secondary)]">공개 여부</span>
                <span className="text-xs font-bold" style={{ color: group.isPublic ? "#FF6B00" : "#666" }}>{group.isPublic ? "공개" : "비공개"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-[var(--pochita-text-secondary)]">초대 코드</span>
                <span className="text-xs font-mono font-bold text-[var(--pochita-text)]">{group.inviteCode}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-xs text-[var(--pochita-text-secondary)]">생성일</span>
                <span className="text-xs text-[var(--pochita-text-secondary)]">{new Date(group.createdAt).toLocaleDateString("ko-KR")}</span>
              </div>
            </div>
            {isOwner && (
              <button onClick={handleNewCode} className="w-full py-3 rounded-xl text-sm font-bold border border-[#333] text-[var(--pochita-text-secondary)] hover:border-[var(--pochita-orange)] hover:text-[var(--pochita-orange)] transition-colors">
                초대 코드 재생성
              </button>
            )}
            {!isMember && (
              <button onClick={handleJoin}
                className="w-full py-4 rounded-2xl font-bold text-white"
                style={{ background: "var(--pochita-orange)" }}>
                그룹 참여하기
              </button>
            )}
          </div>
        )}
      </div>

      {/* Invite sheet */}
      {showInvite && (
        <div className="fixed inset-0 z-50 flex items-end" style={{ background: "rgba(0,0,0,0.75)" }}
          onClick={() => setShowInvite(false)}>
          <div className="w-full rounded-t-3xl px-4 pt-4 pb-10 slide-up" style={{ background: "var(--pochita-card)" }}
            onClick={e => e.stopPropagation()}>
            <div className="w-10 h-1 bg-[var(--pochita-border)] rounded-full mx-auto mb-5" />
            <h3 className="text-base font-bold text-[var(--pochita-text)] mb-1">친구 초대하기</h3>
            <p className="text-xs text-[var(--pochita-text-secondary)] mb-5">아래 코드를 친구에게 공유하거나 링크를 복사하세요</p>
            <div className="p-4 rounded-2xl text-center mb-5" style={{ background: "var(--pochita-card)", border: "1px solid #2A2A2A" }}>
              <p className="text-xs text-[var(--pochita-text-secondary)] mb-2">초대 코드</p>
              <p className="text-4xl font-mono font-bold tracking-widest" style={{ color: "#FF6B00" }}>{group.inviteCode}</p>
            </div>
            <button onClick={handleCopyInvite}
              className="w-full py-4 rounded-2xl font-bold text-white text-base transition-all active:scale-95"
              style={{ background: copied ? "linear-gradient(135deg,#22C55E,#16A34A)" : "var(--pochita-orange)", boxShadow: "0 8px 24px none" }}>
              {copied ? "✓ 복사 완료!" : "📋 코드 복사하기"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
