"use client";
import Image from "next/image";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { AuthStore } from "@/lib/store";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [pw, setPw] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (!email || !pw) { setError("이메일과 비밀번호를 입력해주세요."); return; }
    setLoading(true);
    setTimeout(() => {
      const user = AuthStore.login(email, pw);
      if (user) { router.replace("/home"); }
      else { setError("이메일 또는 비밀번호가 올바르지 않습니다."); setLoading(false); }
    }, 400);
  };

  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6">
      <div className="w-full max-w-sm flex flex-col pb-10">
        
        {/* Logo and Title */}
        <div className="mb-12 text-center">
          <div className="relative w-20 h-20 mx-auto mb-4">
            <Image src="/pochita-logo.png" alt="포치타" fill className="object-contain" />
          </div>
          <h1 className="text-3xl font-black mb-1" style={{ fontFamily: "'Black Han Sans', sans-serif", color: "var(--pochita-orange)" }}>
            포치타
          </h1>
          <p className="text-[13px] text-gray-500 font-medium">단호한 대학생 타이머</p>
        </div>

        {/* Form Inputs */}
        <div className="space-y-3 mb-6">
          <input
            type="email" placeholder="이메일" value={email}
            onChange={e => setEmail(e.target.value)}
            onKeyDown={e => e.key === "Enter" && handleLogin()}
            className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all"
          />
          <input
            type="password" placeholder="비밀번호" value={pw}
            onChange={e => setPw(e.target.value)}
            onKeyDown={e => e.key === "Enter" && handleLogin()}
            className="w-full px-5 py-4 rounded-xl text-[15px] font-medium text-[var(--pochita-text)] placeholder-gray-400 outline-none bg-[#F2F4F6] focus:bg-white focus:ring-2 focus:ring-[var(--pochita-orange)] transition-all"
          />
          {error && <p className="text-[13px] text-red-500 font-medium pt-1 px-1">{error}</p>}
        </div>

        {/* Login Button */}
        <button
          onClick={handleLogin} disabled={loading}
          className="w-full py-4 rounded-xl font-bold text-white text-[16px] transition-all active:scale-[0.98] disabled:opacity-40"
          style={{ background: "var(--pochita-orange)" }}
        >
          {loading ? "로그인 중..." : "로그인"}
        </button>

        {/* Divider */}
        <div className="flex items-center gap-3 my-8">
          <div className="flex-1 h-[1px] bg-gray-100" />
          <span className="text-[12px] font-medium text-gray-400">계정이 없으신가요?</span>
          <div className="flex-1 h-[1px] bg-gray-100" />
        </div>

        {/* Signup Link */}
        <button
          onClick={() => router.push("/signup")}
          className="w-full py-4 rounded-xl font-bold text-[16px] border border-gray-200 text-gray-700 bg-white hover:bg-gray-50 active:bg-gray-100 transition-colors"
        >
          회원가입
        </button>
      </div>
    </div>
  );
}
