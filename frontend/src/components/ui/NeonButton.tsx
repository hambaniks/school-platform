"use client";
import { cn } from "@/lib/utils";

interface NeonButtonProps {
  children: React.ReactNode;
  variant?: "primary" | "secondary" | "green" | "purple" | "pink" | "amber" | "red";
  size?: "sm" | "md" | "lg";
  icon?: React.ReactNode;
  className?: string;
  onClick?: () => void;
  disabled?: boolean;
}

const variants: Record<string, string> = {
  primary: "bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30 hover:bg-neon-cyan/20 hover:shadow-[0_0_12px_rgba(0,240,255,0.15)]",
  secondary: "bg-cyber-mid text-gray-300 border border-cyber-border hover:bg-cyber-light hover:text-gray-100",
  green: "bg-neon-green/10 text-neon-green border border-neon-green/30 hover:bg-neon-green/20",
  purple: "bg-neon-purple/10 text-neon-purple border border-neon-purple/30 hover:bg-neon-purple/20",
  pink: "bg-neon-pink/10 text-neon-pink border border-neon-pink/30 hover:bg-neon-pink/20",
  amber: "bg-neon-amber/10 text-neon-amber border border-neon-amber/30 hover:bg-neon-amber/20",
  red: "bg-neon-red/10 text-neon-red border border-neon-red/30 hover:bg-neon-red/20",
};

export function NeonButton({ children, variant = "primary", size = "md", icon, className, onClick, disabled }: NeonButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-all duration-200 cursor-pointer",
        size === "sm" && "px-3 py-1.5 text-[11px]",
        size === "md" && "px-4 py-2 text-xs",
        size === "lg" && "px-6 py-3 text-sm",
        variants[variant],
        disabled && "opacity-50 cursor-not-allowed",
        className
      )}
    >
      {icon && <span>{icon}</span>}
      {children}
    </button>
  );
}