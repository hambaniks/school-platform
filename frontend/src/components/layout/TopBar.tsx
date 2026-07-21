"use client";
import { cn } from "@/lib/utils";
import { Bell, Search, LogOut } from "lucide-react";

interface TopBarProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  showSearch?: boolean;
}

export function TopBar({ title, subtitle, actions, showSearch }: TopBarProps) {
  return (
    <header className="sticky top-0 z-40 bg-cyber-darker/80 backdrop-blur-xl border-b border-cyber-border px-6 py-3">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-gray-100 tracking-tight">{title}</h1>
          {subtitle && <p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}
        </div>
        <div className="flex items-center gap-3">
          {showSearch && (
            <div className="relative hidden md:block">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600" />
              <input placeholder="Search..." className="pl-8 pr-4 h-8 text-xs bg-cyber-dark border border-cyber-border rounded-lg w-48 focus:w-64 transition-all" />
            </div>
          )}
          {actions}
        </div>
      </div>
    </header>
  );
}