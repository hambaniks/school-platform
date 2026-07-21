"use client";
import { cn } from "@/lib/utils";
import { ReactNode } from "react";

interface ShellProps {
  children: ReactNode;
  className?: string;
}

export function Shell({ children, className }: ShellProps) {
  return (
    <main className={cn("ml-56 min-h-screen bg-cyber-black", className)}>
      {children}
    </main>
  );
}