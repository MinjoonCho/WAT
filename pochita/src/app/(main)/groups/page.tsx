"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore, GroupStore, SessionStore } from "@/lib/store";
import type { User, Group } from "@/lib/types";

export default function GroupsPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [myGroups, setMyGroups] = useState<Group[]>([]);
  const [publicGroups, setPublicGroups] = useState<Group[]>([]);
  const [tab, setTab] = useState<"mine" | "discover">("mine");
  const [inviteCode, setInviteCode] = useState("");
  const [codeError, setCodeError] = useState("");
  const [showJoinSheet, setShowJoinSheet] = useState(false);

  const reload = (u: User) => {
    setMyGroups(GroupStore.getUserGroups(u.id));
    setPublicGroups(GroupStore.getPublicGroups().filter(g => !GroupStore.isMember(g.id, u.id)));
  };

  useEffect(() => {
    const u = AuthStore.getCurrentUser();
    if (!u) { router.replace("/login"); return; }
    setUser(u);
    reload(u);
  }, [router]);

  const handleJoinByCode = () => {
    if (!user) return;
    const g = GroupStore.getByInviteCode(inviteCode.trim());
    if (!g) { setCodeError("유효하지 않은 초대 코드예요"); return; }
    if (GroupStore.isMember(g.id, user.id)) { setCodeError("이미 가입된 그룹이에요"); return; }
    GroupStore.join(g.id, user.id);
    reload(user);
    setShowJoinSheet(false);
    setInviteCode("");
    router.push(`/groups/${g.id}`);
  };

  const handleJoinPublic = (g: Group) => {
    if (!user) return;
    GroupStore.join(g.id, user.id);
    reload(user);
    router.push(`/groups/${g.id}`);
  };

  if (!user) return null;

  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] text-[var(--pochita-text)] font-sans">
      {/* Header */}
      <div className="px-4 pt-10 pb-4 flex items-center justify-between">
        <div>
          <h1 className="text-[26px] font-bold text-[var(--pochita-text)] leading-tight tracking-tight">그룹</h1>
          <p className="text-[13px] text-gray-500 mt-0.5">함께 타락할 동료를 찾아요</p>
        </div>
        <div className="flex gap-2">
          <button onClick={() => setShowJoinSheet(true)}
            className="px-3.5 py-2 rounded-xl text-[13px] font-bold border border-gray-500 text-gray-600 bg-white hover:bg-gray-50 transition-colors">
            코드 입력
          </button>
          <button onClick={() => router.push("/groups/create")}
            className="w-[38px] h-[38px] rounded-xl font-bold text-white flex items-center justify-center text-xl bg-[var(--pochita-orange)] shadow-sm active:bg-[#D44200]">
            +
          </button>
        </div>
      </div>

      {/* Tabs - YPT Style Container */}
      <div className="px-4 mb-5">
        <div className="flex rounded-lg overflow-hidden border border-gray-300 bg-white shadow-sm">
          {[["mine", "내 그룹"], ["discover", "그룹 찾기"]].map(([id, label]) => (
            <button key={id} onClick={() => setTab(id as "mine" | "discover")}
              className="flex-1 py-2 text-[15px] font-bold transition-all"
              style={{
                background: tab === id ? "var(--pochita-orange)" : "transparent",
                color: tab === id ? "white" : "gray"
              }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="px-4 space-y-3 pb-8">
        {tab === "mine" ? (
          myGroups.length === 0 ? (
            <div className="py-16 text-center">
              <p className="text-4xl mb-3">👥</p>
              <p className="text-[15px] font-bold text-gray-700 mb-1">아직 그룹이 없어요</p>
              <p className="text-[13px] text-gray-500 mb-5">그룹을 만들거나 초대 코드로 친구 그룹에 참여하세요</p>
              <div className="flex gap-2 justify-center">
                <button onClick={() => router.push("/groups/create")}
                  className="px-5 py-2.5 rounded-xl text-[13px] font-bold text-white bg-[var(--pochita-orange)] shadow-sm">
                  그룹 만들기
                </button>
                <button onClick={() => setShowJoinSheet(true)}
                  className="px-5 py-2.5 rounded-xl text-[13px] font-bold border border-gray-400 text-gray-600 bg-white">
                  코드로 가입
                </button>
              </div>
            </div>
          ) : (
            myGroups.map(g => <GroupCard key={g.id} group={g} userId={user.id} onClick={() => router.push(`/groups/${g.id}`)} />)
          )
        ) : (
          publicGroups.length === 0 ? (
            <div className="py-16 text-center">
              <p className="text-gray-500 text-[13px]">공개 그룹이 없어요</p>
            </div>
          ) : (
            publicGroups.map(g => (
              <div key={g.id} className="p-4 rounded-[24px] bg-white border border-[var(--pochita-border)] shadow-sm">
                <div className="flex items-center gap-3 mb-4">
                  <span className="text-[32px] shrink-0">{g.emoji}</span>
                  <div className="flex-1 truncate">
                    <p className="text-[15px] font-bold text-[var(--pochita-text)] truncate">{g.name}</p>
                    <p className="text-[12px] text-gray-500 truncate">{g.description}</p>
                  </div>
                  <span className="text-[11px] font-medium px-2 py-1 rounded-lg bg-gray-100 text-gray-600 border border-gray-200">
                    {GroupStore.getMembers(g.id).length}명
                  </span>
                </div>
                <button onClick={() => handleJoinPublic(g)}
                  className="w-full py-2.5 rounded-xl text-[13px] font-bold transition-all bg-orange-50 text-[var(--pochita-orange)] border border-orange-200 active:bg-orange-100">
                  참여하기
                </button>
              </div>
            ))
          )
        )}
      </div>

      {/* Join by code sheet */}
      {showJoinSheet && (
        <div className="fixed inset-0 z-50 flex items-end bg-black/60"
          onClick={() => { setShowJoinSheet(false); setCodeError(""); }}>
          <div className="w-full bg-white rounded-t-3xl pt-2 pb-10 px-5 slide-up shadow-2xl"
            onClick={e => e.stopPropagation()}>
            <div className="w-12 h-1.5 bg-gray-300 rounded-full mx-auto my-3" />
            <h3 className="text-base font-bold text-[var(--pochita-text)] mb-1 tracking-tight">초대 코드 입력</h3>
            <p className="text-[13px] text-gray-500 mb-5">친구에게 받은 6자리 코드를 입력하세요</p>
            <input
              type="text" placeholder="초대 코드 (예: ABC123)"
              value={inviteCode} onChange={e => { setInviteCode(e.target.value.toUpperCase()); setCodeError(""); }}
              className="w-full px-4 py-4 rounded-xl text-sm placeholder-gray-400 outline-none border border-gray-300 focus:border-[var(--pochita-orange)] transition-colors mb-2 font-mono tracking-widest bg-gray-50 uppercase"
              maxLength={6}
            />
            {codeError && <p className="text-[12px] text-red-500 mb-3 px-1">{codeError}</p>}
            <button onClick={handleJoinByCode} disabled={inviteCode.length < 6}
              className="w-full py-4 mt-2 rounded-xl font-bold text-white text-[17px] active:scale-[0.98] transition-all disabled:opacity-40 disabled:bg-gray-300"
              style={{ background: inviteCode.length >= 6 ? "var(--pochita-orange)" : "" }}>
              참여하기
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function GroupCard({ group, userId, onClick }: { group: Group; userId: string; onClick: () => void }) {
  const members = GroupStore.getMembers(group.id);
  const todayTotal = members.reduce((sum, m) => {
    return sum + SessionStore.getTodaySessions(m.userId).reduce((s, sess) => s + (sess.duration ?? 0), 0);
  }, 0);

  return (
    <button onClick={onClick} className="w-full px-4 py-3 rounded-[24px] bg-white border border-[var(--pochita-border)] shadow-sm flex items-center justify-between active:bg-gray-50 transition-colors text-left">
      <div className="flex items-center gap-3">
        <div className="text-[32px] shrink-0">{group.emoji}</div>
        <div className="flex flex-col justify-center">
          <p className="text-[15px] font-bold text-[var(--pochita-text)] truncate max-w-[160px] leading-snug">{group.name}</p>
          <p className="text-[12px] text-gray-500 mt-0.5 truncate max-w-[160px]">{group.description || "포치타 그룹"}</p>
        </div>
      </div>
      <div className="flex flex-col items-end justify-center shrink-0">
         <p className="text-[13px] text-gray-500 leading-snug">{members.length}명</p>
         <p className="text-[13px] font-bold mt-0.5" style={{ color: "var(--pochita-orange)" }}>
            {todayTotal > 0 ? `오늘 ${Math.floor(todayTotal / 60)}분` : "오늘 0분"}
         </p>
      </div>
    </button>
  );
}
