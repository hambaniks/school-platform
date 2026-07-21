"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { useState } from "react";
import { Menu, X, Shield, School, GraduationCap, Users, Heart } from "lucide-react";

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
  badge?: string;
}

interface SidebarProps {
  items: NavItem[];
  role: string;
  userName?: string;
  schoolName?: string;
}

const roleIcons: Record<string, React.ReactNode> = {
  SUPERADMIN: <Shield size={20} className="text-neon-cyan" />,
  SCHOOLADMIN: <School size={20} className="text-neon-blue" />,
  TEACHER: <GraduationCap size={20} className="text-neon-green" />,
  PARENT: <Users size={20} className="text-neon-amber" />,
  CLINIC: <Heart size={20} className="text-neon-pink" />,
};

export function Sidebar({ items, role, userName, schoolName }: SidebarProps) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside className={cn("fixed left-0 top-0 h-screen bg-cyber-darker border-r border-cyber-border z-50 transition-all duration-300 flex flex-col", collapsed ? "w-16" : "w-56")}>
      <div className="flex items-center justify-between p-4 border-b border-cyber-border">
        {!collapsed && (
          <div className="flex items-center gap-2">
            {roleIcons[role] || <Shield size={20} className="text-neon-cyan" />}
            <span className="text-xs font-bold text-gray-100 tracking-wider">{role}</span>
          </div>
        )}
        <button onClick={() => setCollapsed(!collapsed)} className="text-gray-500 hover:text-gray-300 cursor-pointer">
          {collapsed ? <Menu size={18} /> : <X size={18} />}
        </button>
      </div>

      <nav className="flex-1 p-2 space-y-1 overflow-y-auto">
        {items.map((item) => {
          const active = pathname === item.href || (item.href !== "/" && pathname.startsWith(item.href));
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-lg text-xs transition-all",
                active
                  ? "bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20"
                  : "text-gray-500 hover:text-gray-300 hover:bg-cyber-mid"
              )}
            >
              <span className="flex-shrink-0">{item.icon}</span>
              {!collapsed && <span className="truncate">{item.label}</span>}
              {!collapsed && item.badge && (
                <span className="ml-auto px-1.5 py-0.5 rounded-full bg-neon-red/10 text-neon-red text-[9px] font-bold">{item.badge}</span>
              )}
            </Link>
          );
        })}
      </nav>

      {!collapsed && (
        <div className="p-3 border-t border-cyber-border">
          {userName && <p className="text-[10px] text-gray-400 font-medium truncate">{userName}</p>}
          {schoolName && <p className="text-[9px] text-gray-600 truncate">{schoolName}</p>}
        </div>
      )}
    </aside>
  );
}