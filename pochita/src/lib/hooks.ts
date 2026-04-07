"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { AuthStore } from "@/lib/store";
import type { User } from "@/lib/types";

export function useRequireAuth(): User | null {
  const router = useRouter();
  const user = AuthStore.getCurrentUser();

  useEffect(() => {
    if (!user) {
      router.replace("/login");
    }
  }, [router, user]);

  return user;
}

export function useRedirectIfAuth(): void {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const user = AuthStore.getCurrentUser();
    if (user && (pathname === "/login" || pathname === "/signup")) {
      router.replace("/home");
    }
  }, [router, pathname]);
}
