"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthStore } from "@/lib/store";

export default function RootPage() {
  const router = useRouter();
  useEffect(() => {
    const user = AuthStore.getCurrentUser();
    router.replace(user ? "/home" : "/login");
  }, [router]);
  return (
    <div className="min-h-screen bg-[var(--pochita-bg)] flex items-center justify-center">
      <div className="w-12 h-12 rounded-full border-4 border-[var(--pochita-orange)] border-t-transparent animate-spin" />
    </div>
  );
}
