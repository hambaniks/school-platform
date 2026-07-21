"use client";
import { cn } from "@/lib/utils";

interface StatusBadgeProps {
  label: string;
  variant?: "cyan" | "green" | "amber" | "red" | "purple" | "pink" | "blue";
  dot?: boolean;
  pulsing?: boolean;
  size?: "sm" | "md";
}

const variants: Record<string, string> = {
  cyan: "bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20",
  green: "bg-neon-green/10 text-neon-green border border-neon-green/20",
  amber: "bg-neon-amber/10 text-neon-amber border border-neon-amber/20",
  red: "bg-neon-red/10 text-neon-red border border-neon-red/20",
  purple: "bg-neon-purple/10 text-neon-purple border border-neon-purple/20",
  pink: "bg-neon-pink/10 text-neon-pink border border-neon-pink/20",
  blue: "bg-neon-blue/10 text-neon-blue border border-neon-blue/20",
};

const dotColors: Record<string, string> = {
  cyan: "bg-neon-cyan", green: "bg-neon-green", amber: "bg-neon-amber",
  red: "bg-neon-red", purple: "bg-neon-purple", pink: "bg-neon-pink", blue: "bg-neon-blue",
};

export function StatusBadge({ label, variant = "cyan", dot, pulsing, size = "sm" }: StatusBadgeProps) {
  return (
    <span className={cn("inline-flex items-center gap-1.5 rounded-full font-medium", variants[variant], size === "sm" ? "px-2 py-0.5 text-[10px]" : "px-3 py-1 text-xs")}>
      {dot && <span className={cn("w-1.5 h-1.5 rounded-full", dotColors[variant], pulsing && "animate-pulse")} />}
      {label}
    </span>
  );
}