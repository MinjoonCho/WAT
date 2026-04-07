import BottomNav from "@/components/BottomNav";

export default function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="relative min-h-screen bg-[var(--pochita-bg)]">
      <div className="pb-14">{children}</div>
      <BottomNav />
    </div>
  );
}
