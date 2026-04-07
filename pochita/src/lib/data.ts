export const CATEGORIES = [
  { id: "game",      emoji: "🎮", label: "게임",       color: "#FF4444", description: "롤, 배그, 스팀…" },
  { id: "shortform", emoji: "📱", label: "숏폼",       color: "#FF6B00", description: "릴스, 틱톡, 쇼츠" },
  { id: "ott",       emoji: "📺", label: "OTT",        color: "#E50914", description: "넷플, 왓챠, 티빙" },
  { id: "community", emoji: "💬", label: "커뮤니티",   color: "#FF8C00", description: "에브리타임, 에펨코" },
  { id: "drink",     emoji: "🍺", label: "술 마시기",  color: "#FFB800", description: "홈술, 편의점 치맥" },
  { id: "fandom",    emoji: "💜", label: "덕질",       color: "#8B5CF6", description: "아이돌, 웹툰, 소설" },
  { id: "hangout",   emoji: "👥", label: "친구랑 놀기",color: "#10B981", description: "카페, 당구장, 노래방" },
  { id: "lazy",      emoji: "😴", label: "무기력",     color: "#6B7280", description: "그냥 누워있기" },
] as const;

export type CategoryId = typeof CATEGORIES[number]["id"];

export const SNARKY_MESSAGES = [
  "역시... 오늘도 당신은 위대하십니다 👑",
  "교수님이 우는 소리가 들리시나요? 🎶",
  "학점 멸망전 참가 확인 완료 ✅",
  "당신의 취업문은 지금 닫히는 중... 🚪",
  "시험은 나중에 봐도 되잖아요? 🤷",
  "오늘 딴짓한 시간, 내일 후회로 돌아옵니다 😌",
  "포치타가 당신을 응원합니다 (진심으로)",
  "이 정도면 딴짓 장학금 신청해봐요",
  "학사경고? 그거 훈장이죠 🏅",
  "지금쯤 도서관 친구들은 공부 중... 🤫",
];

export const FOCUS_OUT_MESSAGES = [
  "공부하러 가시는 거 아니죠? 딴짓 마저 하세요! 🔥",
  "잠깐, 도망가지 말고 더 타락하세요 😤",
  "어디 가세요?? 아직 더 눌러야죠 📱",
  "포치타가 지켜보고 있습니다 👀",
  "지금 공부하면 진다! 돌아와요~ 🙏",
];

export const DEMO_UNIVERSITY_RANKING = [
  { name: "연세대학교",   totalMinutes: 8547 },
  { name: "고려대학교",   totalMinutes: 7923 },
  { name: "서울대학교",   totalMinutes: 6891 },
  { name: "성균관대학교", totalMinutes: 6234 },
  { name: "한양대학교",   totalMinutes: 5876 },
  { name: "중앙대학교",   totalMinutes: 5543 },
  { name: "경희대학교",   totalMinutes: 5102 },
  { name: "이화여자대학교",totalMinutes: 4987 },
  { name: "서강대학교",   totalMinutes: 4765 },
  { name: "건국대학교",   totalMinutes: 4321 },
];

export function formatTime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${String(h).padStart(2,"0")}:${String(m).padStart(2,"0")}:${String(s).padStart(2,"0")}`;
  return `${String(m).padStart(2,"0")}:${String(s).padStart(2,"0")}`;
}

export function formatTimeKorean(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}시간 ${m}분 ${s}초`;
  if (m > 0) return `${m}분 ${s}초`;
  return `${s}초`;
}

export function getRandomMessage(arr: readonly string[]): string {
  return arr[Math.floor(Math.random() * arr.length)];
}

export function generateAcrosticPoem(
  categoryLabel: string,
  timeStr: string
): { char: string; line: string }[] {
  const sets = [
    [
      { char: "포", line: `포기한 순간부터 시작되는 진짜 인생` },
      { char: "치", line: `치열하게 ${categoryLabel}한 ${timeStr}의 역사` },
      { char: "타", line: `타락의 끝에서 빛나는 당신의 자유` },
    ],
    [
      { char: "포", line: `포기가 패배가 아닌 용기임을 알았다` },
      { char: "치", line: `치솟는 즐거움, ${categoryLabel}의 황홀경` },
      { char: "타", line: `타임라인에 새겨질 오늘의 전설` },
    ],
    [
      { char: "포", line: `포기란 새로운 시작의 다른 이름` },
      { char: "치", line: `치열한 딴짓으로 쌓은 ${timeStr}의 내공` },
      { char: "타", line: `타락했지만 후회 없는 오늘이 좋다` },
    ],
  ];
  return sets[Math.floor(Math.random() * sets.length)];
}
