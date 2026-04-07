import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "포치타 🔥 | 포기한 치타의 타이머",
  description: "열공 말고 딴짓. 당신의 찬란한 타락을 기록합니다. 전국 대학 딴짓 최강자를 가립니다.",
  keywords: "딴짓, 타이머, 대학생, 학점멸망전, 포치타, 시험기간",
  openGraph: {
    title: "포치타 🔥 | 포기한 치타의 타이머",
    description: "열공 말고 딴짓. 당신의 찬란한 타락을 기록합니다.",
    type: "website",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: "#0A0A0A",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@300;400;500;700;900&family=Black+Han+Sans&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="max-w-[430px] mx-auto relative">
        {children}
      </body>
    </html>
  );
}
