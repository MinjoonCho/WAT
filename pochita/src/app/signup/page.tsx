"use client";
import Image from "next/image";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { AuthStore } from "@/lib/store";
import { UNIVERSITIES, YEARS, AVATAR_EMOJIS } from "@/lib/types";

export default function SignupPage() {
  const router = useRouter();
  const [step, setStep] = useState<1 | 2>(1);
  const [email, setEmail] = useState("");
  const [pw, setPw] = useState("");
  const [pw2, setPw2] = useState("");
  const [nickname, setNickname] = useState("");
  const [university, setUniversity] = useState("");
  const [uniInput, setUniInput] = useState("");
  const [year, setYear] = useState("");
  const [avatarEmoji, setAvatarEmoji] = useState("😤");
  const [error, setError] = useState("");
  const [uniOpen, setUniOpen] = useState(false);

  const filteredUnis = UNIVERSITIES.filter(u => u.includes(uniInput)).slice(0, 6);

  const handleStep1 = () => {
    if (!email || !pw) { setError("이메일과 비밀번호를 입력해주세요."); return; }
    if (pw.length < 6) { setError("비밀번호는 6자 이상이어야 합니다."); return; }
    if (pw !== pw2) { setError("비밀번호가 일치하지 않습니다."); return; }
    setError(""); setStep(2);
  };

  const handleRegister = () => {
    const finalNickname = nickname || `딴꾼_${Math.floor(Math.random() * 9999)}`;
    const finalUniversity = university || uniInput || "소속 없음";
    const finalYear = year || "1학년";
    const user = AuthStore.register(email, pw, { nickname: finalNickname, university: finalUniversity, year: finalYear, avatarEmoji });
    if (!user) { setError("이미 가입된 이메일입니다."); setStep(1); return; }
    AuthStore.login(email, pw);
    router.replace("/home");
  };

  return (
    <div className="min-h-screen bg-white flex flex-col items-center px-6 pt-12 pb-8">
      {/* Header */}
      <div className="w-full max-w-sm mb-8">
        <div className="flex items-center gap-3 mb-8">
          {step === 2 && (
            <button onClick={() => setStep(1)} className="w-10 h-10 rounded-full bg-gray-50 hover:bg-gray-100 flex items-center justify-center text-gray-500 font-bold transition-colors">←</button>
          )}
          <div className="flex gap-2 flex-1 pt-1">
            <div className="flex-1 h-1.5 rounded-full" style={{ background: "var(--pochita-orange)" }} />
            <div className="flex-1 h-1.5 rounded-full transition-colors" style={{ background: step === 2 ? "var(--pochita-orange)" : "#F2F4F6" }} />
          </div>
        </div>
        <div>
          <h2 className="text-2xl font-black text-[var(--pochita-text)] mb-1.5 leading-snug">{step === 1 ? "로그인 정보 입력" : "프로필 설정"}</h2>
          <p className="text-[14px] text-gray-500 font-medium">{step === 1 ? "포치타에서 사용할 계정을 만들어주세요" : "딴짓 기록에 남을 멋진 프로필을 완성해주세요"}</p>
        </div>
      </div>

      {/* Step 1: Credentials */}
      {step === 1 && (
        <div className="w-full max-w-sm space-y-3">
          <input type="email" placeholder="이메일" value={email} onChange={e => setEmail(e.target.value)}
            className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
          <input type="password" placeholder="비밀번호 (6자 이상)" value={pw} onChange={e => setPw(e.target.value)}
            className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
          <input type="password" placeholder="비밀번호 확인" value={pw2} onChange={e => setPw2(e.target.value)}
            onKeyDown={e => e.key === "Enter" && handleStep1()}
            className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
          
          {error && <p className="text-[13px] text-red-500 font-medium pt-1 px-1">{error}</p>}
          
          <button onClick={handleStep1}
            className="w-full py-4 rounded-xl font-bold text-white text-[16px] transition-all active:scale-[0.98] mt-4"
            style={{ background: "var(--pochita-orange)" }}>
            다음
          </button>
        </div>
      )}

      {/* Step 2: Profile */}
      {step === 2 && (
        <div className="w-full max-w-sm space-y-5">
          {/* Avatar picker */}
          <div>
            <p className="text-[13px] text-gray-500 font-bold mb-3 px-1">아바타 선택</p>
            <div className="grid grid-cols-5 gap-2">
              {AVATAR_EMOJIS.slice(0,10).map(e => (
                <button key={e} onClick={() => setAvatarEmoji(e)}
                  className="aspect-square rounded-xl text-2xl flex items-center justify-center transition-all bg-gray-50"
                  style={{ 
                    background: avatarEmoji === e ? "rgba(255,107,0,0.1)" : "#F9FAFB", 
                    boxShadow: avatarEmoji === e ? "0 0 0 2px var(--pochita-orange) inset" : "0 0 0 1px #F2F4F6 inset" 
                  }}>
                  {e}
                </button>
              ))}
            </div>
          </div>

          <div>
             <p className="text-[13px] text-gray-500 font-bold mb-2 px-1">닉네임</p>
             <input placeholder="단호한 딴짓러" value={nickname} onChange={e => setNickname(e.target.value)}
               className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
          </div>

          {/* University autocomplete */}
          <div className="relative">
            <p className="text-[13px] text-gray-500 font-bold mb-2 px-1">소속 대학교</p>
            <input placeholder="학교 검색 (예: 서울대학교)" value={uniInput}
              onChange={e => { setUniInput(e.target.value); setUniOpen(true); }}
              onFocus={() => setUniOpen(true)}
              onBlur={() => setTimeout(() => setUniOpen(false), 150)}
              className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all" />
            
            {university && (
              <div className="absolute right-4 top-[38px]">
                <span className="text-[12px] px-2 py-1 rounded bg-orange-50 text-[var(--pochita-orange)] font-bold">✓ 선택됨</span>
              </div>
            )}
            
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
            <p className="text-[13px] text-gray-500 font-bold mb-2 px-1">학년</p>
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

          {error && <p className="text-[13px] text-red-500 font-medium pt-1 px-1">{error}</p>}
          <button onClick={handleRegister}
            className="w-full py-4 mt-6 rounded-xl font-bold text-white text-[16px] transition-all active:scale-[0.98]"
            style={{ background: "var(--pochita-orange)" }}>
            포치타 가입하기
          </button>
        </div>
      )}
    </div>
  );
}
