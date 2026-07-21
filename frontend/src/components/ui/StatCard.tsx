"use client";
import { cn } from "@/lib/utils";

interface StatCardProps {
  label: string;
  value: string;
  change?: string;
  changeType?: "increase" | "decrease" | "neutral";
  accent?: "cyan" | "green" | "amber" | "red" | "purple" | "pink";
  trend?: number;
}

const accentBorders: Record<string, string> = {
  cyan: "border-l-neon-cyan", green: "border-l-neon-green", amber: "border-l-neon-amber",
  red: "border-l-neon-red", purple: "border-l-neon-purple", pink: "border-l-neon-pink",
};

const changeColors: Record<string, string> = {
  increase: "text-neon-green", decrease: "text-neon-red", neutral: "text-gray-500",
};

export function StatCard({ label, value, change, changeType = "neutral", accent = "cyan", trend }: StatCardProps) {
  return (
    <div className={cn("rounded-xl border border-cyber-border bg-cyber-card p-5 border-l-4 transition-all duration-300 hover:border-l-neon-cyan", accentBorders[accent])}>
      <p className="text-[11px] text-gray-500 uppercase tracking-widest font-medium mb-1">{label}</p>
      <p className="text-2xl font-bold font-mono text-gray-100 mb-1">{value}</p>
      {change && <p className={cn("text-[11px]", changeColors[changeType])}>{change}</p>}
      {trend !== undefined && (
        <div className="mt-3 h-1 rounded-full bg-cyber-mid overflow-hidden">
          <div
            className={cn(
              "h-full rounded-full transition-all duration-500",
              trend > 66 ? "bg-neon-green" : trend > 33 ? "bg-neon-amber" : "bg-neon-red"
            )}
            style={{ width: `${Math.min(100, trend)}%` }}
          />
        </div>
      )}
    </div>
  );
}