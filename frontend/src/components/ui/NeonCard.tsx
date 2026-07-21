"use client";
import { cn } from "@/lib/utils";

interface NeonCardProps {
  title?: string;
  subtitle?: string;
  children: React.ReactNode;
  accent?: "cyan" | "blue" | "purple" | "pink" | "green" | "amber" | "red" | "teal";
  interactive?: boolean;
  className?: string;
  onClick?: () => void;
}

const accentMap: Record<string, string> = {
  cyan: "border-neon-cyan/20 hover:border-neon-cyan/40",
  blue: "border-neon-blue/20 hover:border-neon-blue/40",
  purple: "border-neon-purple/20 hover:border-neon-purple/40",
  pink: "border-neon-pink/20 hover:border-neon-pink/40",
  green: "border-neon-green/20 hover:border-neon-green/40",
  amber: "border-neon-amber/20 hover:border-neon-amber/40",
  red: "border-neon-red/20 hover:border-neon-red/40",
  teal: "border-neon-teal/20 hover:border-neon-teal/40",
};

export function NeonCard({ title, subtitle, children, accent = "cyan", interactive, className, onClick }: NeonCardProps) {
  return (
    <div
      onClick={onClick}
      className={cn(
        "relative rounded-xl border bg-cyber-card p-5 transition-all duration-300",
        accentMap[accent] || accentMap.cyan,
        interactive && "cursor-pointer",
        className
      )}
    >
      {title && (
        <div className="mb-4">
          <h3 className="text-sm font-semibold text-gray-100 tracking-wide">{title}</h3>
          {subtitle && <p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}
        </div>
      )}
      {children}
    </div>
  );
}