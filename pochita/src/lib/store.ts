// ==============================
// LocalStorage Data Store
// ==============================
import type { User, Session, Group, GroupMember, ActiveTimer } from "./types";

const KEYS = {
  USERS: "pochita_users",
  CURRENT_USER: "pochita_current_user",
  SESSIONS: "pochita_sessions",
  GROUPS: "pochita_groups",
  GROUP_MEMBERS: "pochita_group_members",
  ACTIVE_TIMER: "pochita_active_timer",
};

function get<T>(key: string): T[] {
  if (typeof window === "undefined") return [];
  try {
    return JSON.parse(localStorage.getItem(key) ?? "[]") as T[];
  } catch {
    return [];
  }
}

function set<T>(key: string, data: T[]): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(key, JSON.stringify(data));
}

function getSingle<T>(key: string): T | null {
  if (typeof window === "undefined") return null;
  try {
    const v = localStorage.getItem(key);
    return v ? (JSON.parse(v) as T) : null;
  } catch {
    return null;
  }
}

function setSingle<T>(key: string, data: T | null): void {
  if (typeof window === "undefined") return;
  if (data === null) localStorage.removeItem(key);
  else localStorage.setItem(key, JSON.stringify(data));
}

// Simple hash for demo purposes
function hashPassword(pw: string): string {
  let hash = 0;
  for (let i = 0; i < pw.length; i++) {
    const char = pw.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash;
  }
  return hash.toString(36);
}

function generateId(): string {
  return Math.random().toString(36).substring(2, 10) + Date.now().toString(36);
}

function generateInviteCode(): string {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
}

// ---- Auth ----
export const AuthStore = {
  register(email: string, password: string, profile: Omit<User, "id" | "email" | "passwordHash" | "createdAt">): User | null {
    const users = get<User>(KEYS.USERS);
    if (users.find((u) => u.email === email)) return null;
    const user: User = {
      id: generateId(),
      email,
      passwordHash: hashPassword(password),
      createdAt: Date.now(),
      ...profile,
    };
    set(KEYS.USERS, [...users, user]);
    return user;
  },

  login(email: string, password: string): User | null {
    // Test account injection
    if ((email === "test@test.com" || email === "test") && password === "123456") {
      const users = get<User>(KEYS.USERS);
      let user = users.find((u) => u.email === "test@test.com");
      if (!user) {
        user = {
          id: "test", email: "test@test.com", passwordHash: hashPassword(password),
          nickname: "테스트계정", university: "포치타대학교", year: "4학년", avatarEmoji: "🦊", createdAt: Date.now()
        };
        set(KEYS.USERS, [...users, user]);
      }
      setSingle(KEYS.CURRENT_USER, user);
      return user;
    }

    const users = get<User>(KEYS.USERS);
    const user = users.find((u) => u.email === email && u.passwordHash === hashPassword(password));
    if (user) {
      setSingle(KEYS.CURRENT_USER, user);
      return user;
    }
    return null;
  },

  logout(): void {
    setSingle(KEYS.CURRENT_USER, null);
    setSingle(KEYS.ACTIVE_TIMER, null);
  },

  getCurrentUser(): User | null {
    return getSingle<User>(KEYS.CURRENT_USER);
  },

  updateCurrentUser(updates: Partial<User>): User | null {
    const current = getSingle<User>(KEYS.CURRENT_USER);
    if (!current) return null;
    const updated = { ...current, ...updates };
    const users = get<User>(KEYS.USERS).map((u) => (u.id === updated.id ? updated : u));
    set(KEYS.USERS, users);
    setSingle(KEYS.CURRENT_USER, updated);
    return updated;
  },

  getUserById(id: string): User | null {
    const users = get<User>(KEYS.USERS);
    return users.find((u) => u.id === id) ?? null;
  },

  getAllUsers(): User[] {
    return get<User>(KEYS.USERS);
  },
};

// ---- Sessions ----
export const SessionStore = {
  create(userId: string, categoryId: string): Session {
    const session: Session = {
      id: generateId(),
      userId,
      categoryId,
      startTime: Date.now(),
    };
    const sessions = get<Session>(KEYS.SESSIONS);
    set(KEYS.SESSIONS, [...sessions, session]);
    return session;
  },

  finish(sessionId: string): Session | null {
    const sessions = get<Session>(KEYS.SESSIONS);
    const idx = sessions.findIndex((s) => s.id === sessionId);
    if (idx === -1) return null;
    const endTime = Date.now();
    const session = sessions[idx];
    const duration = Math.floor((endTime - session.startTime) / 1000);
    const updated = { ...session, endTime, duration };
    sessions[idx] = updated;
    set(KEYS.SESSIONS, sessions);
    return updated;
  },

  getUserSessions(userId: string): Session[] {
    return get<Session>(KEYS.SESSIONS).filter((s) => s.userId === userId && s.endTime);
  },

  getTodaySessions(userId: string): Session[] {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return get<Session>(KEYS.SESSIONS).filter(
      (s) => s.userId === userId && s.endTime && s.startTime >= today.getTime()
    );
  },

  getAllSessions(): Session[] {
    return get<Session>(KEYS.SESSIONS);
  },
};

// ---- Active Timer ----
export const TimerStore = {
  start(sessionId: string, userId: string, categoryId: string): ActiveTimer {
    const timer: ActiveTimer = {
      sessionId,
      userId,
      categoryId,
      startTime: Date.now(),
      isPaused: false,
      totalPausedSeconds: 0,
    };
    setSingle(KEYS.ACTIVE_TIMER, timer);
    return timer;
  },

  get(): ActiveTimer | null {
    return getSingle<ActiveTimer>(KEYS.ACTIVE_TIMER);
  },

  pause(): void {
    const timer = getSingle<ActiveTimer>(KEYS.ACTIVE_TIMER);
    if (!timer || timer.isPaused) return;
    setSingle(KEYS.ACTIVE_TIMER, { ...timer, isPaused: true, pausedAt: Date.now() });
  },

  resume(): void {
    const timer = getSingle<ActiveTimer>(KEYS.ACTIVE_TIMER);
    if (!timer || !timer.isPaused) return;
    const pausedSeconds = timer.pausedAt ? Math.floor((Date.now() - timer.pausedAt) / 1000) : 0;
    setSingle(KEYS.ACTIVE_TIMER, {
      ...timer,
      isPaused: false,
      pausedAt: undefined,
      totalPausedSeconds: timer.totalPausedSeconds + pausedSeconds,
    });
  },

  clear(): void {
    setSingle(KEYS.ACTIVE_TIMER, null);
  },

  getElapsedSeconds(timer: ActiveTimer): number {
    const now = Date.now();
    const raw = Math.floor((now - timer.startTime) / 1000);
    const paused = timer.isPaused
      ? timer.totalPausedSeconds + (timer.pausedAt ? Math.floor((now - timer.pausedAt) / 1000) : 0)
      : timer.totalPausedSeconds;
    return Math.max(0, raw - paused);
  },
};

// ---- Groups ----
export const GroupStore = {
  create(name: string, description: string, emoji: string, createdBy: string, isPublic: boolean): Group {
    const group: Group = {
      id: generateId(),
      name,
      description,
      emoji,
      createdBy,
      inviteCode: generateInviteCode(),
      createdAt: Date.now(),
      isPublic,
    };
    const groups = get<Group>(KEYS.GROUPS);
    set(KEYS.GROUPS, [...groups, group]);

    // Add creator as owner
    const members = get<GroupMember>(KEYS.GROUP_MEMBERS);
    set(KEYS.GROUP_MEMBERS, [
      ...members,
      { groupId: group.id, userId: createdBy, joinedAt: Date.now(), role: "owner" },
    ]);

    return group;
  },

  getAll(): Group[] {
    return get<Group>(KEYS.GROUPS);
  },

  getById(id: string): Group | null {
    return get<Group>(KEYS.GROUPS).find((g) => g.id === id) ?? null;
  },

  getByInviteCode(code: string): Group | null {
    return get<Group>(KEYS.GROUPS).find((g) => g.inviteCode === code.toUpperCase()) ?? null;
  },

  getUserGroups(userId: string): Group[] {
    const memberRecords = get<GroupMember>(KEYS.GROUP_MEMBERS).filter((m) => m.userId === userId);
    const groupIds = new Set(memberRecords.map((m) => m.groupId));
    return get<Group>(KEYS.GROUPS).filter((g) => groupIds.has(g.id));
  },

  getPublicGroups(): Group[] {
    return get<Group>(KEYS.GROUPS).filter((g) => g.isPublic);
  },

  getMembers(groupId: string): GroupMember[] {
    return get<GroupMember>(KEYS.GROUP_MEMBERS).filter((m) => m.groupId === groupId);
  },

  isMember(groupId: string, userId: string): boolean {
    return get<GroupMember>(KEYS.GROUP_MEMBERS).some(
      (m) => m.groupId === groupId && m.userId === userId
    );
  },

  join(groupId: string, userId: string): boolean {
    if (GroupStore.isMember(groupId, userId)) return false;
    const members = get<GroupMember>(KEYS.GROUP_MEMBERS);
    set(KEYS.GROUP_MEMBERS, [...members, { groupId, userId, joinedAt: Date.now(), role: "member" }]);
    return true;
  },

  leave(groupId: string, userId: string): void {
    const members = get<GroupMember>(KEYS.GROUP_MEMBERS).filter(
      (m) => !(m.groupId === groupId && m.userId === userId)
    );
    set(KEYS.GROUP_MEMBERS, members);
  },

  regenerateInviteCode(groupId: string): string {
    const groups = get<Group>(KEYS.GROUPS);
    const code = generateInviteCode();
    set(KEYS.GROUPS, groups.map((g) => (g.id === groupId ? { ...g, inviteCode: code } : g)));
    return code;
  },
};
