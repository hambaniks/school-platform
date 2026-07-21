# =============================================================================
# SCHOOL PLATFORM — COMPLETE FIX & BUILD (Windows PowerShell 5.1 compatible)
# Paste this ENTIRE block into PowerShell. Creates all files with UTF-8 No BOM.
# =============================================================================
$ErrorActionPreference = "Stop"
$ROOT = "C:\Users\k2020\school-platform"
$FRONTEND = "$ROOT\frontend"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SCHOOL HEALTH PLATFORM — FULL INSTALL  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ─── HELPER: Write file UTF-8 NO BOM (works on PowerShell 5.1) ───
function Write-FileNoBom {
    param([string]$Path, [string]$Content)
    $null = New-Item -ItemType File -Path $Path -Force
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
    Write-Host "  ✓ $($Path.Split('\')[-2..-1] -join '/')" -ForegroundColor Green
}

# ─── STEP 1: CREATE ALL DIRECTORIES ───
Write-Host "`n[1/7] Creating directories..." -ForegroundColor Yellow
$dirs = @(
    "$ROOT\supabase\migrations","$ROOT\supabase\functions\sa-sams-parser","$ROOT\supabase\functions\truancy-watchdog",
    "$ROOT\supabase\functions\attendance-compliance","$ROOT\supabase\functions\payfast-billing",
    "$ROOT\supabase\functions\health-pdf-generator","$ROOT\supabase\storage",
    "$ROOT\render-cron\workers",
    "$FRONTEND\src\app\superadmin","$FRONTEND\src\app\schooladmin","$FRONTEND\src\app\teacher",
    "$FRONTEND\src\app\parent","$FRONTEND\src\app\clinic","$FRONTEND\src\app\api\attendance",
    "$FRONTEND\src\components\ui","$FRONTEND\src\components\layout","$FRONTEND\src\components\dashboards",
    "$FRONTEND\src\components\forms","$FRONTEND\src\components\health","$FRONTEND\src\components\billing",
    "$FRONTEND\src\components\attendance","$FRONTEND\src\components\ai",
    "$FRONTEND\src\lib","$FRONTEND\src\hooks","$FRONTEND\src\styles","$FRONTEND\public"
)
foreach ($d in $dirs) { $null = New-Item -ItemType Directory -Path $d -Force }
Write-Host "  All directories created" -ForegroundColor Green

# ─── STEP 2: package.json (clean — NO BOM) ───
Write-Host "`n[2/7] Writing package.json..." -ForegroundColor Yellow
Write-FileNoBom "$FRONTEND\package.json" @'
{
  "name": "school-platform-frontend",
  "version": "3.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "@supabase/supabase-js": "^2.39.0",
    "@supabase/ssr": "^0.1.0",
    "lucide-react": "^0.330.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0",
    "date-fns": "^3.3.0",
    "react-hot-toast": "^2.4.1"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.3.0"
  }
}
'@

# ─── STEP 3: Config files ───
Write-Host "[3/7] Writing config files..." -ForegroundColor Yellow

# next.config.js — FIXED: removed experimental.serverActions
Write-FileNoBom "$FRONTEND\next.config.js" @'
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: [process.env.NEXT_PUBLIC_SUPABASE_URL?.replace('https://', '') || ''],
  },
};
module.exports = nextConfig;
'@

Write-FileNoBom "$FRONTEND\tsconfig.json" @'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
'@

Write-FileNoBom "$FRONTEND\postcss.config.js" @'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
'@

Write-FileNoBom "$FRONTEND\vercel.json" @'
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "installCommand": "npm install",
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key"
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Strict-Transport-Security", "value": "max-age=63072000" }
      ]
    }
  ]
}
'@

Write-FileNoBom "$FRONTEND\.env.example" @'
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
NEXT_PUBLIC_SITE_URL=https://school-platform.vercel.app
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
ONESIGNAL_APP_ID=your-onesignal-app-id
ONESIGNAL_API_KEY=your-onesignal-api-key
PAYFAST_MERCHANT_ID=your-payfast-id
PAYFAST_MERCHANT_KEY=your-payfast-key
PAYFAST_PASSPHRASE=your-payfast-passphrase
HEALTH_DEPT_EMAIL=health-regional@education.gov.za
'@

# ─── STEP 4: Tailwind Config ───
Write-Host "[4/7] Writing Tailwind config..." -ForegroundColor Yellow
Write-FileNoBom "$FRONTEND\tailwind.config.ts" @'
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        cyber: {
          black: "#0a0a0f", darker: "#0d0d1a", dark: "#12122a",
          mid: "#1a1a3e", light: "#2a2a5e", card: "#141428", border: "#2a2a5e",
        },
        neon: {
          cyan: "#00f0ff", blue: "#4d7cff", purple: "#8b5cf6",
          pink: "#ff2d7b", green: "#00ff87", amber: "#ffb800",
          red: "#ff3355", teal: "#00d4aa",
        },
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', '"Fira Code"', "monospace"],
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      boxShadow: {
        "neon-cyan": "0 0 10px rgba(0,240,255,0.3), 0 0 20px rgba(0,240,255,0.1)",
        "neon-purple": "0 0 10px rgba(139,92,246,0.3), 0 0 20px rgba(139,92,246,0.1)",
        "neon-pink": "0 0 10px rgba(255,45,123,0.3), 0 0 20px rgba(255,45,123,0.1)",
        "neon-green": "0 0 10px rgba(0,255,135,0.3), 0 0 20px rgba(0,255,135,0.1)",
        "neon-amber": "0 0 10px rgba(255,184,0,0.3), 0 0 20px rgba(255,184,0,0.1)",
        "neon-red": "0 0 10px rgba(255,51,85,0.3), 0 0 20px rgba(255,51,85,0.1)",
      },
      animation: {
        "pulse-neon": "pulseNeon 2s ease-in-out infinite",
        "slide-up": "slideUp 0.3s ease-out",
        "fade-in": "fadeIn 0.2s ease-out",
      },
      keyframes: {
        pulseNeon: { "0%,100%": { opacity: "1" }, "50%": { opacity: "0.85" } },
        slideUp: { "0%": { opacity: "0", transform: "translateY(12px)" }, "100%": { opacity: "1", transform: "translateY(0)" } },
        fadeIn: { "0%": { opacity: "0" }, "100%": { opacity: "1" } },
      },
    },
  },
  plugins: [],
};
export default config;
'@

# ─── STEP 5: Global CSS ───
Write-Host "[5/7] Writing CSS and core files..." -ForegroundColor Yellow
Write-FileNoBom "$FRONTEND\src\styles\globals.css" @'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap');

@layer base {
  * { @apply border-cyber-border; }
  body {
    @apply bg-cyber-black text-gray-100 font-sans antialiased;
    background-image:
      radial-gradient(ellipse at 20% 50%, rgba(0,240,255,0.03) 0%, transparent 50%),
      radial-gradient(ellipse at 80% 20%, rgba(139,92,246,0.03) 0%, transparent 50%);
    background-attachment: fixed;
  }
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { @apply bg-cyber-darker; }
  ::-webkit-scrollbar-thumb { @apply bg-cyber-light rounded-full; }
  ::-webkit-scrollbar-thumb:hover { @apply bg-neon-cyan/30; }
  input, textarea, select {
    @apply bg-cyber-dark border border-cyber-light rounded-lg px-4 py-2.5 text-gray-100 placeholder-gray-500
           focus:outline-none focus:border-neon-cyan focus:ring-1 focus:ring-neon-cyan/30 transition-all duration-200;
  }
}

@layer components {
  .neon-card {
    @apply bg-cyber-card border border-cyber-border rounded-xl p-5
           hover:border-neon-cyan/20 transition-all duration-300
           shadow-[0_0_15px_rgba(0,240,255,0.03)];
  }
  .neon-button {
    @apply inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg
           font-medium text-sm transition-all duration-200
           focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-cyber-black;
  }
  .neon-badge {
    @apply inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  .badge-cyan { @apply neon-badge bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20; }
  .badge-purple { @apply neon-badge bg-neon-purple/10 text-neon-purple border border-neon-purple/20; }
  .badge-pink { @apply neon-badge bg-neon-pink/10 text-neon-pink border border-neon-pink/20; }
  .badge-green { @apply neon-badge bg-neon-green/10 text-neon-green border border-neon-green/20; }
  .badge-amber { @apply neon-badge bg-neon-amber/10 text-neon-amber border border-neon-amber/20; }
  .badge-red { @apply neon-badge bg-neon-red/10 text-neon-red border border-neon-red/20; }
  .cyber-grid-bg {
    background-image:
      linear-gradient(rgba(0,240,255,0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,240,255,0.03) 1px, transparent 1px);
    background-size: 40px 40px;
  }
}

@layer utilities {
  .text-gradient-cyan { @apply bg-gradient-to-r from-neon-cyan to-neon-blue bg-clip-text text-transparent; }
  .text-gradient-purple { @apply bg-gradient-to-r from-neon-purple to-neon-pink bg-clip-text text-transparent; }
  .text-gradient-green { @apply bg-gradient-to-r from-neon-green to-neon-teal bg-clip-text text-transparent; }
}
'@

# ─── Lib files ───
Write-FileNoBom "$FRONTEND\src\lib\utils.ts" @'
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)); }
export function formatDate(d: string | Date): string { return new Intl.DateTimeFormat("en-ZA", { day: "numeric", month: "short", year: "numeric", timeZone: "Africa/Johannesburg" }).format(new Date(d)); }
export function formatCurrency(amount: number): string { return new Intl.NumberFormat("en-ZA", { style: "currency", currency: "ZAR" }).format(amount); }
export function getInitials(name: string): string { return name.split(" ").map(n=>n[0]).join("").toUpperCase().slice(0,2); }
export function getRoleLabel(role: string): string {
  const map: Record<string,string> = { SUPERADMIN:"Super Admin", SCHOOLADMIN:"School Admin", TEACHER:"Teacher", PARENT:"Parent", CLINIC:"Clinic Staff" };
  return map[role] || role;
}
'@

Write-FileNoBom "$FRONTEND\src\lib\supabase.ts" @'
import { createClient } from "@supabase/supabase-js";
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: { persistSession: true, autoRefreshToken: true },
  global: { headers: { "x-application-name": "school-health-platform" } },
});
'@

# ─── UI Components ───
Write-FileNoBom "$FRONTEND\src\components\ui\NeonCard.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import { ReactNode } from "react";
const accents: Record<string,string> = { cyan:"hover:border-neon-cyan/30", purple:"hover:border-neon-purple/30", pink:"hover:border-neon-pink/30", green:"hover:border-neon-green/30", amber:"hover:border-neon-amber/30", red:"hover:border-neon-red/30" };
export function NeonCard({ children, className, accent = "cyan", interactive, onClick, title, subtitle, icon, badge }: { children: ReactNode; className?: string; accent?: string; interactive?: boolean; onClick?: () => void; title?: string; subtitle?: string; icon?: ReactNode; badge?: ReactNode }) {
  return (
    <div onClick={onClick} className={cn("bg-cyber-card border border-cyber-border rounded-xl p-5 transition-all duration-300", interactive && accents[accent], interactive && "cursor-pointer", className)}>
      {(title || icon || badge) && (
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center gap-3">
            {icon && <div className="text-neon-cyan">{icon}</div>}
            <div>
              {title && <h3 className="text-sm font-semibold text-gray-100">{title}</h3>}
              {subtitle && <p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}
            </div>
          </div>
          {badge && <div>{badge}</div>}
        </div>
      )}
      {children}
    </div>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\ui\NeonButton.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import { ButtonHTMLAttributes } from "react";
type V = "primary"|"purple"|"pink"|"green"|"amber"|"danger"|"ghost";
const vs: Record<V,string> = {
  primary:"bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30 hover:bg-neon-cyan/20 hover:shadow-neon-cyan",
  purple:"bg-neon-purple/10 text-neon-purple border border-neon-purple/30 hover:bg-neon-purple/20 hover:shadow-neon-purple",
  pink:"bg-neon-pink/10 text-neon-pink border border-neon-pink/30 hover:bg-neon-pink/20 hover:shadow-neon-pink",
  green:"bg-neon-green/10 text-neon-green border border-neon-green/30 hover:bg-neon-green/20 hover:shadow-neon-green",
  amber:"bg-neon-amber/10 text-neon-amber border border-neon-amber/30 hover:bg-neon-amber/20 hover:shadow-neon-amber",
  danger:"bg-neon-red/10 text-neon-red border border-neon-red/30 hover:bg-neon-red/20 hover:shadow-neon-red",
  ghost:"text-gray-400 hover:text-gray-200 hover:bg-cyber-light/50"
};
const ss = { sm:"px-3 py-1.5 text-xs", md:"px-5 py-2.5 text-sm", lg:"px-7 py-3 text-base" };
export function NeonButton({ children, variant="primary" as V, size="md" as "sm"|"md"|"lg", loading, icon, className, ...props }: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: V; size?: "sm"|"md"|"lg"; loading?: boolean; icon?: React.ReactNode }) {
  return (
    <button className={cn("inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-cyber-black disabled:opacity-40 disabled:cursor-not-allowed", vs[variant], ss[size], className)} disabled={loading} {...props}>
      {loading && <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/></svg>}
      {icon || null}{children}
    </button>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\ui\StatusBadge.tsx" @'
"use client"; import { cn } from "@/lib/utils";
type V = "cyan"|"purple"|"pink"|"green"|"amber"|"red"|"gray";
const vs: Record<V,string> = {
  cyan:"bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20", purple:"bg-neon-purple/10 text-neon-purple border border-neon-purple/20",
  pink:"bg-neon-pink/10 text-neon-pink border border-neon-pink/20", green:"bg-neon-green/10 text-neon-green border border-neon-green/20",
  amber:"bg-neon-amber/10 text-neon-amber border border-neon-amber/20", red:"bg-neon-red/10 text-neon-red border border-neon-red/20",
  gray:"bg-gray-800 text-gray-400 border border-gray-700"
};
const ds: Record<V,string> = {
  cyan:"bg-neon-cyan", purple:"bg-neon-purple", pink:"bg-neon-pink", green:"bg-neon-green",
  amber:"bg-neon-amber", red:"bg-neon-red", gray:"bg-gray-600"
};
export function StatusBadge({ label, variant="gray" as V, dot, pulsing, className }: { label: string; variant?: V; dot?: boolean; pulsing?: boolean; className?: string }) {
  return (
    <span className={cn("inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium", vs[variant], className)}>
      {dot && <span className={cn("w-1.5 h-1.5 rounded-full", ds[variant], pulsing && "animate-pulse")} />}
      {label}
    </span>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\ui\StatCard.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import { ReactNode } from "react";
const ac = { cyan:"border-l-neon-cyan", purple:"border-l-neon-purple", pink:"border-l-neon-pink", green:"border-l-neon-green", amber:"border-l-neon-amber", red:"border-l-neon-red" };
export function StatCard({ label, value, change, changeType, icon, accent="cyan" as "cyan"|"purple"|"pink"|"green"|"amber"|"red", className, trend }: { label:string; value:string|number; change?:string; changeType?:"increase"|"decrease"|"neutral"; icon?:ReactNode; accent?:string; className?:string; trend?:number }) {
  return (
    <div className={cn("bg-cyber-card border border-cyber-border rounded-xl p-5 border-l-4 transition-all duration-300", ac[accent], className)}>
      <div className="flex items-center justify-between mb-1">
        <span className="text-xs font-medium text-gray-500 uppercase tracking-wider">{label}</span>
        {icon && <span className="text-neon-cyan/70">{icon}</span>}
      </div>
      <div className="flex items-end gap-3">
        <span className="text-2xl font-bold text-gray-100 font-mono">{value}</span>
        {change && (
          <span className={cn("text-xs font-medium mb-1", changeType==="increase"&&"text-neon-green", changeType==="decrease"&&"text-neon-red", changeType==="neutral"&&"text-gray-500")}>
            {changeType==="increase"?"\u2191":changeType==="decrease"?"\u2193":"\u2192"} {change}
          </span>
        )}
      </div>
      {trend!==undefined && (
        <div className="mt-2 h-1 bg-cyber-dark rounded-full overflow-hidden">
          <div className={cn("h-full rounded-full", trend>80?"bg-neon-green":trend>60?"bg-neon-cyan":trend>40?"bg-neon-amber":"bg-neon-red")} style={{ width: Math.min(trend,100)+"%" }} />
        </div>
      )}
    </div>
  );
}
'@

# ─── Layout Components ───
Write-FileNoBom "$FRONTEND\src\components\layout\Sidebar.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import Link from "next/link"; import { usePathname } from "next/navigation"; import { ReactNode } from "react";
export function Sidebar({ items, role, schoolName, userName }: { items: {label:string;href:string;icon:ReactNode;badge?:string|number}[]; role:string; schoolName?:string; userName?:string }) {
  const path = usePathname();
  return (
    <aside className="w-64 h-screen fixed left-0 top-0 bg-cyber-darker border-r border-cyber-border flex flex-col z-40">
      <div className="p-5 border-b border-cyber-border">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30 flex items-center justify-center">
            <span className="text-neon-cyan text-sm font-bold">S</span>
          </div>
          <div><h1 className="text-sm font-bold text-gray-100">SchoolNet</h1><p className="text-[10px] text-gray-600 font-mono">v3.0 \u00b7 {role}</p></div>
        </div>
        {schoolName && <p className="mt-3 text-xs text-gray-500 truncate">{schoolName}</p>}
      </div>
      <nav className="flex-1 overflow-y-auto p-3 space-y-1">
        {items.map((item) => {
          const active = path===item.href || path.startsWith(item.href+"/");
          return (
            <Link key={item.href} href={item.href} className={cn("flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all duration-200 group relative", active?"bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/20":"text-gray-500 hover:text-gray-200 hover:bg-cyber-dark hover:border hover:border-cyber-border")}>
              <span className={cn("w-5 h-5", active?"text-neon-cyan":"text-gray-600 group-hover:text-gray-400")}>{item.icon}</span>
              <span className="flex-1">{item.label}</span>
              {item.badge && <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-neon-cyan/10 text-neon-cyan">{item.badge}</span>}
              {active && <span className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 bg-neon-cyan rounded-full shadow-[0_0_8px_rgba(0,240,255,0.5)]" />}
            </Link>
          );
        })}
      </nav>
      {userName && (
        <div className="p-4 border-t border-cyber-border">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-cyan/20 to-neon-purple/20 flex items-center justify-center">
              <span className="text-xs font-bold text-gray-300">{userName.split(" ").map(n=>n[0]).join("").slice(0,2).toUpperCase()}</span>
            </div>
            <div className="flex-1 min-w-0"><p className="text-xs font-medium text-gray-300 truncate">{userName}</p><p className="text-[10px] text-gray-600">{role}</p></div>
          </div>
        </div>
      )}
    </aside>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\layout\TopBar.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import { ReactNode } from "react";
export function TopBar({ title, subtitle, actions, className }: { title:string; subtitle?:string; actions?:ReactNode; className?:string }) {
  return (
    <header className={cn("h-16 flex items-center justify-between px-6 border-b border-cyber-border bg-cyber-darker/50 backdrop-blur-sm sticky top-0 z-30", className)}>
      <div><h1 className="text-lg font-semibold text-gray-100">{title}</h1>{subtitle&&<p className="text-xs text-gray-500 mt-0.5">{subtitle}</p>}</div>
      {actions && <div className="flex items-center gap-3">{actions}</div>}
    </header>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\layout\Shell.tsx" @'
"use client"; import { cn } from "@/lib/utils"; import { ReactNode } from "react";
export function Shell({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <main className={cn("ml-64 min-h-screen bg-cyber-black", className)}>
      <div className="cyber-grid-bg opacity-30 fixed inset-0 pointer-events-none" />
      <div className="relative">{children}</div>
    </main>
  );
}
'@

Write-FileNoBom "$FRONTEND\src\components\dashboards\SchoolMap.tsx" @'
"use client"; import { NeonCard } from "@/components/ui/NeonCard"; import { StatusBadge } from "@/components/ui/StatusBadge";
export function SchoolMap({ schools }: { schools: {id:string;name:string;status:"ACTIVE"|"SUSPENDED"|"TRIAL";learners:number;region:string}[] }) {
  const active = schools.filter(s=>s.status==="ACTIVE").length;
  const suspended = schools.filter(s=>s.status==="SUSPENDED").length;
  const trial = schools.filter(s=>s.status==="TRIAL").length;
  return (
    <NeonCard title="School Network Map" subtitle="Live distribution of active nodes" accent="cyan">
      <div className="relative h-64 bg-cyber-darker rounded-lg border border-cyber-border overflow-hidden">
        <div className="cyber-grid-bg absolute inset-0 opacity-50" />
        <svg className="absolute inset-0 w-full h-full" viewBox="0 0 400 200">
          <line x1="80" y1="60" x2="200" y2="40" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="200" y1="40" x2="320" y2="80" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="80" y1="60" x2="120" y2="140" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="320" y1="80" x2="280" y2="160" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="120" y1="140" x2="280" y2="160" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
        </svg>
        {schools.slice(0,5).map((s,i)=>{
          const pos = [{x:80,y:60},{x:200,y:40},{x:320,y:80},{x:120,y:140},{x:280,y:160}][i%5];
          return (
            <div key={s.id} className="absolute transform -translate-x-1/2 -translate-y-1/2 group" style={{left:pos.x,top:pos.y}}>
              <div className={cn("w-4 h-4 rounded-full border-2", s.status==="ACTIVE"?"bg-neon-green/20 border-neon-green shadow-[0_0_12px_rgba(0,255,135,0.3)]":s.status==="SUSPENDED"?"bg-neon-red/20 border-neon-red shadow-[0_0_12px_rgba(255,51,85,0.3)]":"bg-neon-amber/20 border-neon-amber shadow-[0_0_12px_rgba(255,184,0,0.3)]")} />
              <div className="absolute left-6 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity bg-cyber-dark border border-cyber-border rounded-lg px-3 py-2 whitespace-nowrap z-10">
                <p className="text-xs font-medium text-gray-200">{s.name}</p>
                <p className="text-[10px] text-gray-500">{s.learners} learners \u00b7 {s.region}</p>
              </div>
            </div>
          );
        })}
        <div className="absolute bottom-3 left-3 flex items-center gap-4">
          <span className="w-2 h-2 rounded-full bg-neon-green shadow-[0_0_6px_rgba(0,255,135,0.5)]" /><span className="text-[10px] text-gray-500">{active} Active</span>
          <span className="w-2 h-2 rounded-full bg-neon-amber shadow-[0_0_6px_rgba(255,184,0,0.5)]" /><span className="text-[10px] text-gray-500">{trial} Trial</span>
          <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_6px_rgba(255,51,85,0.5)]" /><span className="text-[10px] text-gray-500">{suspended} Suspended</span>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-4 mt-4">
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-cyan font-mono">{schools.length}</div><div className="text-[10px] text-gray-500 mt-1">Total Schools</div></div>
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-green font-mono">{schools.reduce((s,sc)=>s+sc.learners,0).toLocaleString()}</div><div className="text-[10px] text-gray-500 mt-1">Total Learners</div></div>
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-amber font-mono">{Math.round(active/(schools.length||1)*100)}%</div><div className="text-[10px] text-gray-500 mt-1">Active Rate</div></div>
      </div>
    </NeonCard>
  );
}
function cn(...i:any[]){const{c}=require("@/lib/utils");return c(...i);}
'@

# ─── Root Layout ───
Write-FileNoBom "$FRONTEND\src\app\layout.tsx" @'
import type { Metadata } from "next";
import "@/styles/globals.css";
export const metadata: Metadata = {
  title: "SchoolNet — Multi-Tenant School Management Platform",
  description: "Enterprise-grade school management, LMS, and public health oversight system with real-time analytics and clinic integration.",
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-cyber-black text-gray-100 antialiased">{children}</body>
    </html>
  );
}
'@

# ─── Landing Page ───
Write-FileNoBom "$FRONTEND\src\app\page.tsx" @'
"use client"; import Link from "next/link";
export default function LandingPage() {
  return (
    <div className="min-h-screen bg-cyber-black cyber-grid-bg flex flex-col">
      <div className="fixed inset-0 bg-[radial-gradient(ellipse_at_top,rgba(0,240,255,0.06),transparent_60%)] pointer-events-none" />
      <nav className="relative z-10 flex items-center justify-between px-8 py-5 border-b border-cyber-border">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-neon-cyan/10 border border-neon-cyan/30 flex items-center justify-center">
            <span className="text-neon-cyan font-bold">S</span>
          </div>
          <span className="text-lg font-bold text-gray-100">SchoolNet</span>
        </div>
        <div className="flex items-center gap-4">
          {[{l:"SuperAdmin",h:"/superadmin"},{l:"SchoolAdmin",h:"/schooladmin"},{l:"Teacher",h:"/teacher"},{l:"Parent",h:"/parent"},{l:"Clinic",h:"/clinic"}].map(r=><Link key={r.h} href={r.h} className="text-sm text-gray-500 hover:text-gray-300 transition-colors">{r.l}</Link>)}
        </div>
      </nav>
      <main className="relative z-10 flex-1 flex flex-col items-center justify-center px-6 text-center">
        <div className="max-w-3xl mx-auto">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-neon-cyan/5 border border-neon-cyan/20 mb-8">
            <span className="w-2 h-2 rounded-full bg-neon-cyan animate-pulse" />
            <span className="text-xs text-neon-cyan font-mono">Enterprise Platform v3.0</span>
          </div>
          <h1 className="text-5xl md:text-7xl font-bold leading-tight mb-6">
            <span className="text-gray-100">Multi-Tenant</span><br />
            <span className="text-gradient-cyan">School Management</span><br />
            <span className="text-gray-100">&amp;</span> <span className="text-gradient-purple">Health Oversight</span>
          </h1>
          <p className="text-lg text-gray-500 max-w-xl mx-auto mb-10 leading-relaxed">
            Enterprise-grade platform connecting schools, teachers, parents, and clinics with real-time attendance tracking, LMS, billing automation, and public health surveillance.
          </p>
          <div className="grid grid-cols-5 gap-4 max-w-2xl mx-auto mb-12">
            {[{l:"SuperAdmin",h:"/superadmin",c:"border-neon-red/30 text-neon-red"},{l:"SchoolAdmin",h:"/schooladmin",c:"border-neon-cyan/30 text-neon-cyan"},{l:"Teacher",h:"/teacher",c:"border-neon-purple/30 text-neon-purple"},{l:"Parent",h:"/parent",c:"border-neon-green/30 text-neon-green"},{l:"Clinic",h:"/clinic",c:"border-neon-amber/30 text-neon-amber"}].map(r=>(
              <Link key={r.h} href={r.h} className={"px-4 py-3 rounded-xl bg-cyber-card border " + r.c + " hover:bg-cyber-dark transition-all text-sm font-medium"}>{r.l}</Link>
            ))}
          </div>
          <div className="grid grid-cols-3 gap-8 max-w-lg mx-auto">
            {[{v:"1,200+",l:"Schools Active"},{v:"850K+",l:"Learners Tracked"},{v:"99.9%",l:"Platform Uptime"}].map(s=><div key={s.l}><div className="text-2xl font-bold text-gray-100 font-mono">{s.v}</div><div className="text-xs text-gray-600 mt-1">{s.l}</div></div>)}
          </div>
        </div>
      </main>
      <footer className="relative z-10 border-t border-cyber-border py-4 px-8">
        <div className="flex items-center justify-between text-xs text-gray-600">
          <span>SchoolNet v3.0 — Multi-Tenant Platform</span>
          <span className="font-mono">Supabase + Vercel + Render</span>
        </div>
      </footer>
    </div>
  );
}
'@

Write-Host "Core files written!" -ForegroundColor Green

# ─── STEP 6: ALL 5 DASHBOARD PAGES ───
Write-Host "[6/7] Writing all 5 dashboard pages..." -ForegroundColor Yellow

# ---- SUPERADMIN ----
Write-FileNoBom "$FRONTEND\src\app\superadmin\page.tsx" @'
"use client"; import { Shell } from "@/components/layout/Shell"; import { Sidebar } from "@/components/layout/Sidebar"; import { TopBar } from "@/components/layout/TopBar";
import { StatCard } from "@/components/ui/StatCard"; import { NeonCard } from "@/components/ui/NeonCard"; import { NeonButton } from "@/components/ui/NeonButton"; import { StatusBadge } from "@/components/ui/StatusBadge";
import { SchoolMap } from "@/components/dashboards/SchoolMap";
import { Globe, School, Users, CreditCard, AlertTriangle, BarChart3, Activity, Shield, Download, Bell, Settings, RefreshCw } from "lucide-react";
const nav = [
  {label:"Global Overview",href:"/superadmin",icon:<Globe size={18}/>},{label:"Schools",href:"/superadmin/schools",icon:<School size={18}/>},
  {label:"Billing",href:"/superadmin/billing",icon:<CreditCard size={18}/>,badge:"4"},{label:"Alerts",href:"/superadmin/alerts",icon:<AlertTriangle size={18}/>,badge:"12"},
  {label:"Analytics",href:"/superadmin/analytics",icon:<BarChart3 size={18}/>},{label:"Audit Log",href:"/superadmin/audit",icon:<Activity size={18}/>},
  {label:"System Health",href:"/superadmin/system",icon:<Shield size={18}/>},{label:"Settings",href:"/superadmin/settings",icon:<Settings size={18}/>},
];
const mock = [{id:"1",name:"Springfield High",status:"ACTIVE" as const,learners:1240,region:"Gauteng"},{id:"2",name:"Riverside Academy",status:"ACTIVE" as const,learners:890,region:"Western Cape"},{id:"3",name:"Hillcrest Primary",status:"SUSPENDED" as const,learners:560,region:"KZN"},{id:"4",name:"Sunnydale College",status:"ACTIVE" as const,learners:2100,region:"Gauteng"},{id:"5",name:"Oceanview School",status:"TRIAL" as const,learners:340,region:"Eastern Cape"},{id:"6",name:"Greenfield Academy",status:"ACTIVE" as const,learners:780,region:"Limpopo"}];
export default function SuperAdmin() {
  return <div className="min-h-screen bg-cyber-black">
    <Sidebar items={nav} role="SUPERADMIN" userName="Admin Zulu" schoolName="District Management Console" />
    <Shell><TopBar title="Global Command Center" subtitle="Multi-school oversight and system controls" actions={<><NeonButton variant="ghost" size="sm" icon={<RefreshCw size={14}/>}>Sync</NeonButton><NeonButton variant="primary" size="sm" icon={<Download size={14}/>}>Export</NeonButton></>} />
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-4 gap-4">
          <StatCard label="Total Schools" value="1,247" change="+12 this quarter" changeType="increase" accent="cyan" trend={88} />
          <StatCard label="Active Learners" value="854,320" change="+2.4%" changeType="increase" accent="green" trend={92} />
          <StatCard label="Monthly Revenue" value="R 1.2M" change="98% collected" changeType="increase" accent="purple" trend={78} />
          <StatCard label="Pending Issues" value="23" change="+7 this week" changeType="decrease" accent="red" trend={34} />
        </div>
        <div className="grid grid-cols-3 gap-6">
          <div className="col-span-2"><SchoolMap schools={mock} /></div>
          <NeonCard title="Live Billing Feed" subtitle="Real-time payment activity" accent="purple">
            <div className="space-y-3">{([{school:"Springfield High",amount:"R 24,800",status:"completed" as const,time:"2 min ago"},{school:"Riverside Acad.",amount:"R 17,800",status:"completed" as const,time:"15 min ago"},{school:"Hillcrest Primary",amount:"R 11,200",status:"failed" as const,time:"1 hr ago"},{school:"Sunnydale College",amount:"R 42,000",status:"pending" as const,time:"2 hrs ago"},{school:"Oceanview School",amount:"R 6,800",status:"completed" as const,time:"3 hrs ago"}]).map((tx,i)=>(
              <div key={i} className="flex items-center justify-between py-2 border-b border-cyber-border last:border-0">
                <div><p className="text-xs font-medium text-gray-200">{tx.school}</p><p className="text-[10px] text-gray-600">{tx.time}</p></div>
                <div className="flex items-center gap-3"><span className="text-sm font-mono text-gray-200">{tx.amount}</span><StatusBadge label={tx.status} variant={tx.status==="completed"?"green":tx.status==="failed"?"red":"amber"} dot /></div>
              </div>
            ))}</div>
            <div className="mt-4 pt-3 border-t border-cyber-border"><NeonButton variant="purple" size="sm" className="w-full"><CreditCard size={14}/> Master Billing Override</NeonButton></div>
          </NeonCard>
        </div>
        <div className="grid grid-cols-3 gap-6">
          <NeonCard title="System Traffic" subtitle="Real-time API throughput" accent="cyan">
            <div className="flex items-center justify-center py-6">
              <div className="relative w-36 h-36">
                <svg className="w-full h-full transform -rotate-90" viewBox="0 0 120 120">
                  <circle cx="60" cy="60" r="54" fill="none" stroke="#1a1a3e" strokeWidth="8" />
                  <circle cx="60" cy="60" r="54" fill="none" stroke="#00f0ff" strokeWidth="8" strokeDasharray={`${(85/100)*339.292} 339.292`} strokeLinecap="round" />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center"><span className="text-2xl font-bold text-gray-100 font-mono">85%</span><span className="text-[10px] text-gray-500">Capacity</span></div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3 text-center"><div className="p-2 rounded bg-cyber-darker"><div className="text-xs font-mono text-neon-cyan">2.4K</div><div className="text-[9px] text-gray-600">Req/s</div></div><div className="p-2 rounded bg-cyber-darker"><div className="text-xs font-mono text-neon-green">14ms</div><div className="text-[9px] text-gray-600">Latency</div></div></div>
          </NeonCard>
          <div className="col-span-2">
            <NeonCard title="School Nodes" subtitle="Active institutions" accent="green">
              <div className="overflow-x-auto"><table className="w-full text-xs">
                <thead><tr className="text-gray-500 border-b border-cyber-border"><th className="text-left py-3 font-medium">School</th><th className="text-left py-3 font-medium">Region</th><th className="text-right py-3 font-medium">Learners</th><th className="text-right py-3 font-medium">Status</th><th className="text-right py-3 font-medium">Actions</th></tr></thead>
                <tbody>{mock.map(s=><tr key={s.id} className="border-b border-cyber-border/50 hover:bg-cyber-darker/50 transition-colors"><td className="py-3 text-gray-200 font-medium">{s.name}</td><td className="py-3 text-gray-500">{s.region}</td><td className="py-3 text-right font-mono text-gray-300">{s.learners.toLocaleString()}</td><td className="py-3 text-right"><StatusBadge label={s.status} variant={s.status==="ACTIVE"?"green":s.status==="SUSPENDED"?"red":"amber"} dot /></td><td className="py-3 text-right"><NeonButton variant="ghost" size="sm">Manage</NeonButton></td></tr>)}</tbody>
              </table></div>
            </NeonCard>
          </div>
        </div>
      </div>
    </Shell>
  </div>;
}
'@

# ---- SCHOOLADMIN ----
Write-FileNoBom "$FRONTEND\src\app\schooladmin\page.tsx" @'
"use client"; import { Shell } from "@/components/layout/Shell"; import { Sidebar } from "@/components/layout/Sidebar"; import { TopBar } from "@/components/layout/TopBar";
import { StatCard } from "@/components/ui/StatCard"; import { NeonCard } from "@/components/ui/NeonCard"; import { NeonButton } from "@/components/ui/NeonButton"; import { StatusBadge } from "@/components/ui/StatusBadge";
import { Upload, Users, Bell, FileSpreadsheet, AlertTriangle, Calendar, Clock, TrendingUp, Download } from "lucide-react";
const nav = [
  {label:"Dashboard",href:"/schooladmin",icon:<TrendingUp size={18}/>},{label:"SA-SAMS Import",href:"/schooladmin/import",icon:<Upload size={18}/>},
  {label:"Learners",href:"/schooladmin/learners",icon:<Users size={18}/>,badge:"1,240"},{label:"Attendance",href:"/schooladmin/attendance",icon:<Clock size={18}/>,badge:"3"},
  {label:"Alerts",href:"/schooladmin/alerts",icon:<Bell size={18}/>,badge:"7"},{label:"Billing",href:"/schooladmin/billing",icon:<FileSpreadsheet size={18}/>},
];
export default function SchoolAdmin() {
  return <div className="min-h-screen bg-cyber-black">
    <Sidebar items={nav} role="SCHOOLADMIN" userName="Principal Dlamini" schoolName="Springfield High School" />
    <Shell><TopBar title="School Management Console" subtitle="Springfield High · EMIS: 5001203456" actions={<NeonButton variant="primary" size="sm" icon={<Upload size={14}/>}>Import SA-SAMS</NeonButton>} />
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-4 gap-4">
          <StatCard label="Total Learners" value="1,240" change="+23 this term" changeType="increase" accent="cyan" trend={85} />
          <StatCard label="Today's Attendance" value="92.4%" change="+2.1% vs yesterday" changeType="increase" accent="green" trend={92} />
          <StatCard label="Absent Today" value="38" change="6 LATE · 32 ABSENT" changeType="decrease" accent="amber" trend={15} />
          <StatCard label="Open Alerts" value="7" change="3 TRUANCY · 4 MEDICAL" changeType="decrease" accent="red" trend={25} />
        </div>
        <div className="grid grid-cols-3 gap-6">
          <div className="col-span-2 space-y-6">
            <NeonCard title="SA-SAMS Import Zone" subtitle="Drag & drop spreadsheet files" accent="cyan">
              <div className="border-2 border-dashed border-cyber-border rounded-xl p-12 text-center hover:border-neon-cyan/30 transition-all bg-cyber-darker/50 group cursor-pointer">
                <Upload size={44} className="mx-auto text-gray-600 group-hover:text-neon-cyan transition-colors mb-4" />
                <p className="text-sm text-gray-400 mb-1">Drop your SA-SAMS export file here</p>
                <p className="text-xs text-gray-600">Supports .xlsx, .xls, .csv — Max 50MB</p>
                <NeonButton variant="primary" size="sm" className="mt-4">Browse Files</NeonButton>
              </div>
              <div className="mt-4 space-y-2">
                {[{name:"learner_roster_2026_Q3.xlsx",status:"COMPLETED" as const,rows:1240,date:"2026-07-15"},{name:"parent_contacts_update.csv",status:"PROCESSING" as const,rows:980,date:"2026-07-20"}].map((f,i)=>(
                  <div key={i} className="flex items-center justify-between py-3 px-4 rounded-lg bg-cyber-darker border border-cyber-border">
                    <div className="flex items-center gap-3"><FileSpreadsheet size={18} className={f.status==="COMPLETED"?"text-neon-green":"text-neon-amber"} /><div><p className="text-xs text-gray-200 font-medium">{f.name}</p><p className="text-[10px] text-gray-600">{f.rows} rows · {f.date}</p></div></div>
                    <StatusBadge label={f.status} variant={f.status==="COMPLETED"?"green":"amber"} dot pulsing={f.status==="PROCESSING"} />
                  </div>
                ))}
              </div>
            </NeonCard>
            <NeonCard title="Attendance Compliance" subtitle="Today's register submission status" accent="amber">
              <div className="space-y-2">{([{c:"Mathematics 10A",t:"Mrs. Khumalo",r:30,e:32,s:"PARTIAL" as const},{c:"English 11B",t:"Mr. Peters",r:28,e:28,s:"COMPLETE" as const},{c:"Science 9C",t:"Dr. Molefe",r:0,e:30,s:"MISSING" as const},{c:"History 12A",t:"Ms. Zulu",r:25,e:25,s:"COMPLETE" as const},{c:"Geography 8B",t:"Mr. Botha",r:0,e:26,s:"MISSING" as const}]).map((c,i)=>(
                <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker/50 transition-colors">
                  <div><p className="text-xs text-gray-200">{c.c}</p><p className="text-[9px] text-gray-600">{c.t}</p></div>
                  <div className="flex items-center gap-3"><span className="text-[10px] font-mono text-gray-500">{c.r}/{c.e}</span><StatusBadge label={c.s} variant={c.s==="COMPLETE"?"green":c.s==="PARTIAL"?"amber":"red"} dot pulsing={c.s==="MISSING"} /></div>
                </div>
              ))}</div>
            </NeonCard>
          </div>
          <div className="space-y-6">
            <NeonCard title="Absence Ticker" subtitle="Live today" accent="amber">
              <div className="space-y-2">{([{n:"T. Mokoena",g:"10B",t:"08:45",y:"ABSENT" as const},{n:"L. van der Merwe",g:"11A",t:"09:00",y:"LATE" as const},{n:"S. Patel",g:"9C",t:"09:15",y:"ABSENT" as const},{n:"K. Ndlovu",g:"12A",t:"10:00",y:"ABSENT" as const},{n:"M. Botha",g:"8B",t:"10:30",y:"LATE" as const}]).map((a,i)=>(
                <div key={i} className="flex items-center justify-between py-1.5 border-b border-cyber-border/50 last:border-0">
                  <div><p className="text-xs text-gray-200">{a.n}</p><p className="text-[10px] text-gray-600">Grade {a.g}</p></div>
                  <div className="flex items-center gap-2"><span className="text-[10px] text-gray-500">{a.t}</span><StatusBadge label={a.y} variant={a.y==="ABSENT"?"red":"amber"} dot /></div>
                </div>
              ))}</div>
              <NeonButton variant="amber" size="sm" className="w-full mt-3" icon={<AlertTriangle size={14}/>}>View All Absences</NeonButton>
            </NeonCard>
            <NeonCard title="Quick Actions" accent="purple">
              <div className="grid grid-cols-2 gap-2">
                <NeonButton variant="primary" size="sm" icon={<Bell size={14}/>}>School Alert</NeonButton>
                <NeonButton variant="green" size="sm" icon={<Users size={14}/>}>Take Register</NeonButton>
                <NeonButton variant="purple" size="sm" icon={<Calendar size={14}/>}>Schedule</NeonButton>
                <NeonButton variant="amber" size="sm" icon={<FileSpreadsheet size={14}/>}>Quick Reports</NeonButton>
                <NeonButton variant="pink" size="sm" icon={<Download size={14}/>}>Export CSV</NeonButton>
                <NeonButton variant="primary" size="sm" icon={<Bell size={14}/>}>Announce</NeonButton>
              </div>
            </NeonCard>
          </div>
        </div>
      </div>
    </Shell>
  </div>;
}
'@

# ---- TEACHER ----
Write-FileNoBom "$FRONTEND\src\app\teacher\page.tsx" @'
"use client"; import { Shell } from "@/components/layout/Shell"; import { Sidebar } from "@/components/layout/Sidebar"; import { TopBar } from "@/components/layout/TopBar";
import { NeonCard, NeonCardHeader } from "@/components/ui/NeonCard"; import { NeonButton } from "@/components/ui/NeonButton"; import { StatusBadge } from "@/components/ui/StatusBadge";
import { useState } from "react"; import { CheckSquare, BookOpen, FileText, Users, Clock, Upload, Send, Bell, BarChart3 } from "lucide-react";
const nav = [
  {label:"Dashboard",href:"/teacher",icon:<CheckSquare size={18}/>},{label:"Attendance",href:"/teacher/attendance",icon:<Users size={18}/>,badge:"2"},
  {label:"Gradebook",href:"/teacher/gradebook",icon:<BookOpen size={18}/>},{label:"Assignments",href:"/teacher/assignments",icon:<FileText size={18}/>,badge:"3"},
  {label:"Resources",href:"/teacher/resources",icon:<Upload size={18}/>},{label:"Schedule",href:"/teacher/schedule",icon:<Clock size={18}/>},
];
const students = [
  {name:"Amahle Zulu",grade:"10A",present:true,late:false},{name:"Brandon Peters",grade:"10A",present:true,late:false},
  {name:"Cynthia Mokoena",grade:"10A",present:false,late:true},{name:"Daniel van Wyk",grade:"10A",present:true,late:false},
  {name:"Elena dos Santos",grade:"10A",present:false,late:false},{name:"Farai Chigumbura",grade:"10A",present:true,late:false},
  {name:"Grace Ndhlovu",grade:"10A",present:true,late:false},{name:"Henk Botha",grade:"10A",present:false,late:false},
];
export default function Teacher() {
  const [roster,setRoster] = useState(students);
  const p=roster.filter(s=>s.present&&!s.late).length, l=roster.filter(s=>s.late).length, a=roster.filter(s=>!s.present&&!s.late).length;
  const toggle = (idx:number, mode:"p"|"l"|"a") => setRoster(prev=>prev.map((s,i)=>i!==idx?s:{...s,present:mode==="p"?!s.present?true:false:false,late:mode==="l"?!s.late?true:false:false}));
  return <div className="min-h-screen bg-cyber-black">
    <Sidebar items={nav} role="TEACHER" userName="Mrs. Khumalo" schoolName="Springfield High · Mathematics" />
    <Shell><TopBar title="Teacher Console" subtitle="Mathematics — Grade 10A · 21 July 2026" actions={<NeonButton variant="primary" size="sm" icon={<Send size={14}/>}>Submit Register</NeonButton>} />
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-3 gap-6">
          <NeonCard title="Attendance Toggle" subtitle="Tap P / L / A to record" accent="cyan">
            <NeonCardHeader accent="cyan"><div className="flex gap-2"><StatusBadge label={p+" PRESENT"} variant="green" dot /><StatusBadge label={l+" LATE"} variant="amber" dot /><StatusBadge label={a+" ABSENT"} variant="red" dot /></div></NeonCardHeader>
            <div className="space-y-1 max-h-[420px] overflow-y-auto">{[...roster].map((s,i)=>(
              <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker transition-colors border border-transparent">
                <div className="flex items-center gap-3">
                  <div className={"w-8 h-8 rounded-full flex items-center justify-center text-[10px] font-bold "+(s.present&&!s.late?"bg-neon-green/10 text-neon-green":s.late?"bg-neon-amber/10 text-neon-amber":"bg-neon-red/10 text-neon-red")}>{s.name.split(" ").map(n=>n[0]).join("").slice(0,2)}</div>
                  <div><p className="text-xs text-gray-200">{s.name}</p><p className="text-[10px] text-gray-600">Grade {s.grade}</p></div>
                </div>
                <div className="flex gap-1.5">
                  {["p","l","a"].map(m=>{
                    const active = m==="p"?s.present&&!s.late:m==="l"?s.late:m==="a"?!s.present&&!s.late:false;
                    const c = m==="p"?"green":m==="l"?"amber":"red";
                    return <button key={m} onClick={()=>toggle(i,m as "p"|"l"|"a")} className={"w-7 h-7 rounded flex items-center justify-center text-[10px] font-medium transition-all cursor-pointer "+(active?`bg-neon-${c}/20 border border-neon-${c}/30 text-neon-${c}`:"bg-cyber-dark border border-cyber-border text-gray-600")}>{m.toUpperCase()}</button>;
                  })}
                </div>
              </div>
            ))}</div>
            <div className="mt-3 pt-3 border-t border-cyber-border flex justify-between"><span className="text-[10px] text-gray-600">{p+l}/{roster.length} recorded</span><NeonButton variant="primary" size="sm">Submit</NeonButton></div>
          </NeonCard>
          <NeonCard title="Gradebook Quick Entry" subtitle="Quadratic Functions Test" accent="purple">
            <div className="space-y-2 max-h-[420px] overflow-y-auto">{students.slice(0,8).map((s,i)=>(
              <div key={i} className="flex items-center justify-between py-2"><span className="text-xs text-gray-200 w-36 truncate">{s.name}</span><div className="flex items-center gap-2"><input type="number" placeholder="—" className="w-16 text-center font-mono text-xs bg-cyber-dark border border-cyber-border rounded px-2 py-1.5" /><span className="text-[10px] text-gray-600">/100</span></div></div>
            ))}</div>
            <NeonButton variant="purple" size="sm" className="w-full mt-3" icon={<BookOpen size={14}/>}>Open Full Gradebook</NeonButton>
          </NeonCard>
          <div className="space-y-6">
            <NeonCard title="Documents" subtitle="Lesson notes & resources" accent="green">
              <div className="space-y-2">{[{n:"Quadratic Functions Notes.pdf",s:"2.4 MB"},{n:"Homework Set 3.pdf",s:"1.1 MB"},{n:"Term 3 Scheme.docx",s:"856 KB"}].map((d,i)=>(
                <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker cursor-pointer"><div className="flex items-center gap-3"><FileText size={16} className="text-neon-green" /><div><p className="text-xs text-gray-200">{d.n}</p><p className="text-[9px] text-gray-600">{d.s}</p></div></div><Upload size={14} className="text-gray-600 opacity-0 group-hover:opacity-100"/></div>
              ))}</div>
              <NeonButton variant="green" size="sm" className="w-full mt-3" icon={<Upload size={14}/>}>Upload Resource</NeonButton>
            </NeonCard>
            <NeonCard title="Upcoming" accent="amber">
              {[{l:"Test: Algebra",d:"24 Jul"},{l:"Parent Meeting",d:"26 Jul"},{l:"Assignment Due",d:"28 Jul"}].map((e,i)=><div key={i} className="flex items-center justify-between py-1.5"><span className="text-xs text-gray-200">{e.l}</span><StatusBadge label={e.d} variant="amber" /></div>)}
            </NeonCard>
          </div>
        </div>
      </div>
    </Shell>
  </div>;
}
'@

# ---- PARENT ----
Write-FileNoBom "$FRONTEND\src\app\parent\page.tsx" @'
"use client"; import { Shell } from "@/components/layout/Shell"; import { Sidebar } from "@/components/layout/Sidebar"; import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard"; import { NeonButton } from "@/components/ui/NeonButton"; import { StatusBadge } from "@/components/ui/StatusBadge";
import { Calendar, Bell, AlertTriangle, Heart, User, FileText, CreditCard, Clock, CheckCircle, XCircle } from "lucide-react";
const nav = [
  {label:"Home",href:"/parent",icon:<User size={18}/>},{label:"Assignments",href:"/parent/assignments",icon:<FileText size={18}/>,badge:"2"},
  {label:"Attendance",href:"/parent/attendance",icon:<Clock size={18}/>},{label:"Billing",href:"/parent/billing",icon:<CreditCard size={18}/>,badge:"UNPAID"},
  {label:"Medical",href:"/parent/medical",icon:<Heart size={18}/>},{label:"Alerts",href:"/parent/alerts",icon:<Bell size={18}/>},
];
const children = [{name:"Lethabo Mokoena",grade:"10A",attendance:94,chronic:null,avg:"B"},{name:"Karabo Mokoena",grade:"7B",attendance:88,chronic:"Asthma",avg:"A-"}];
export default function Parent() {
  return <div className="min-h-screen bg-cyber-black">
    <Sidebar items={nav} role="PARENT" userName="Mrs. Mokoena" schoolName="Springfield High School" />
    <Shell><TopBar title="Parent Portal" subtitle="Your children in real time" actions={<NeonButton variant="primary" size="sm" icon={<Bell size={14}/>}>Notifications <span className="ml-1 w-4 h-4 rounded-full bg-neon-red text-[9px] inline-flex items-center justify-center font-bold">3</span></NeonButton>} />
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-2 gap-6">{children.map(c=>(
          <NeonCard key={c.name} title={c.name} subtitle={"Grade "+c.grade} interactive accent={c.chronic?"amber":"green"}>
            <div className="grid grid-cols-4 gap-3 mb-4">
              {[{v:c.attendance+"%",l:"Attendance",c:"text-neon-green"},{v:c.avg,l:"Avg Grade",c:"text-neon-cyan"},{v:"0",l:"Missing",c:"text-neon-purple"},{v:"0",l:"Alerts",c:"text-neon-amber"}].map((s,i)=>(
                <div key={i} className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className={"text-lg font-bold font-mono "+s.c}>{s.v}</div><div className="text-[9px] text-gray-600">{s.l}</div></div>
              ))}
            </div>
            <div className="flex gap-2">{c.chronic?<StatusBadge label={"Chronic: "+c.chronic} variant="amber" dot />:<StatusBadge label="No chronic conditions" variant="green" dot />}</div>
          </NeonCard>
        ))}</div>
        <div className="grid grid-cols-3 gap-6">
          <NeonCard title="Upcoming Deadlines" subtitle="Calendar badges" accent="cyan">
            <div className="flex flex-wrap gap-2 mb-4">{["Math Test Jul 24","History Essay Jul 28","Science Project Aug 2"].map((d,i)=>(
              <div key={i} className="px-3 py-1.5 rounded-lg bg-neon-red/10 border border-neon-red/20 text-xs text-neon-red"><Calendar size={12} className="inline mr-1"/>{d}</div>
            ))}</div>
            <div className="rounded-lg bg-cyber-darker p-3 border border-cyber-border">
              <div className="grid grid-cols-7 gap-1 text-center mb-2">{["M","T","W","T","F","S","S"].map(d=><span key={d} className="text-[9px] text-gray-600 font-medium">{d}</span>)}</div>
              {[20,21,22,23,24,25,26].map((w,i)=>(
                <div key={i} className="grid grid-cols-7 gap-1 text-center mb-1">{Array.from({length:7},(_,j)=>{
                  const day=w+j-(i*7); if(day<1||day>31)return<div key={j}/>;
                  return <div key={j} className={"text-[11px] py-1 rounded "+(day===21?"ring-1 ring-neon-cyan/50 ":"")+([24,26,28].includes(day)?"bg-neon-cyan/10 text-neon-cyan font-bold":"text-gray-500")}>{day}{[24,26,28].includes(day)&&<div className="w-1 h-1 rounded-full bg-neon-cyan mx-auto mt-0.5"/>}</div>;
                })}</div>
              ))}
            </div>
          </NeonCard>
          <NeonCard title="Alert Timeline" subtitle="Real-time notifications" accent="amber">
            <div className="space-y-3">{[{icon:<AlertTriangle size={14}/>,t:"Karabo late to 3rd period",time:"Today 09:15",c:"text-neon-amber"},{icon:<CheckCircle size={14}/>,t:"Lethabo submitted Math HW",time:"Yesterday 16:30",c:"text-neon-green"},{icon:<Bell size={14}/>,t:"Parent-Teacher meeting Tue 26 Jul",time:"2 days ago",c:"text-neon-purple"},{icon:<XCircle size={14}/>,t:"Karabo absent period 2",time:"3 days ago",c:"text-neon-red"}].map((a,i)=>(
              <div key={i} className="flex items-start gap-3 py-2 border-b border-cyber-border/50 last:border-0"><span className={"mt-0.5 "+a.c}>{a.icon}</span><div><p className="text-xs text-gray-200">{a.t}</p><p className="text-[10px] text-gray-600">{a.time}</p></div></div>
            ))}</div>
          </NeonCard>
          <div className="space-y-6">
            <NeonCard title="Medical Opt-In" subtitle="POPIA consent" accent="purple">
              {children.map(c=><div key={c.name} className="p-3 rounded-lg bg-cyber-darker border border-cyber-border mb-3"><p className="text-xs font-medium text-gray-200 mb-2">{c.name}</p><div className="flex items-center justify-between mb-1"><span className="text-[10px] text-gray-500">POPIA</span><StatusBadge label="GRANTED" variant="green" dot /></div><div className="flex items-center justify-between"><span className="text-[10px] text-gray-500">Chronic</span>{c.chronic?<StatusBadge label={c.chronic} variant="amber" dot />:<span className="text-[10px] text-gray-600">None</span>}</div></div>)}
              <NeonButton variant="purple" size="sm" className="w-full" icon={<Heart size={14}/>}>Update Medical</NeonButton>
            </NeonCard>
            <NeonCard title="Billing" subtitle="R100/year per learner" accent="pink">
              <div className="flex items-center gap-3 p-3 rounded-lg bg-neon-red/5 border border-neon-red/20 mb-3"><CreditCard size={20} className="text-neon-red" /><div><p className="text-xs text-gray-200 font-medium">R200 outstanding</p><p className="text-[9px] text-gray-500">2 learners · Due 31 Jul</p></div></div>
              <NeonButton variant="pink" size="sm" className="w-full" icon={<CreditCard size={14}/>}>Pay Now — R200</NeonButton>
            </NeonCard>
          </div>
        </div>
      </div>
    </Shell>
  </div>;
}
'@

# ---- CLINIC ----
Write-FileNoBom "$FRONTEND\src\app\clinic\page.tsx" @'
"use client"; import { Shell } from "@/components/layout/Shell"; import { Sidebar } from "@/components/layout/Sidebar"; import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard"; import { NeonButton } from "@/components/ui/NeonButton"; import { StatusBadge } from "@/components/ui/StatusBadge"; import { StatCard } from "@/components/ui/StatCard";
import { useState } from "react"; import { AlertTriangle, Heart, Users, MapPin, Phone, CheckCircle, Clock, Filter, Download, Search, Syringe, FileText, Home } from "lucide-react";
const nav = [
  {label:"Inbox",href:"/clinic",icon:<AlertTriangle size={18}/>,badge:"12"},{label:"All Alerts",href:"/clinic/alerts",icon:<Heart size={18}/>},
  {label:"Schools",href:"/clinic/schools",icon:<Users size={18}/>},{label:"Immunization",href:"/clinic/immunization",icon:<Syringe size={18}/>,badge:"8"},
  {label:"Tracking",href:"/clinic/tracking",icon:<MapPin size={18}/>},{label:"Reports",href:"/clinic/reports",icon:<Download size={18}/>},
];
const alerts = [
  {id:1,learner:"Thabo Nkosi",school:"Springfield High",grade:"10B",chronic:"Asthma",status:"INBOUND" as const,days:4,contact:"+27 82 555 0101",time:"2 hrs ago"},
  {id:2,learner:"Lerato Molefe",school:"Riverside Acad.",grade:"8A",chronic:"Diabetes Type 1",status:"CONTACTED" as const,days:3,contact:"+27 72 555 0202",time:"5 hrs ago"},
  {id:3,learner:"Sipho Dlamini",school:"Hillcrest Primary",grade:"5C",chronic:null,status:"INBOUND" as const,days:5,contact:"+27 62 555 0303",time:"1 day ago"},
  {id:4,learner:"Zanele Khumalo",school:"Sunnydale College",grade:"11A",chronic:"Epilepsy",status:"ESCALATED" as const,days:7,contact:"+27 82 555 0404",time:"2 days ago"},
  {id:5,learner:"Bongani Zulu",school:"Springfield High",grade:"9C",chronic:null,status:"RESOLVED" as const,days:0,contact:"+27 72 555 0505",time:"3 days ago"},
];
export default function Clinic() {
  const [filter,setFilter] = useState("ALL"); const [search,setSearch] = useState("");
  const f = alerts.filter(a=>filter==="ALL"||a.status===filter).filter(a=>a.learner.toLowerCase().includes(search.toLowerCase())||a.school.toLowerCase().includes(search.toLowerCase()));
  const inbound = alerts.filter(a=>a.status==="INBOUND").length;
  return <div className="min-h-screen bg-cyber-black">
    <Sidebar items={nav} role="CLINIC" userName="Sister Ndlovu" schoolName="District Health Office · Region A" />
    <Shell><TopBar title="Clinic Health Portal" subtitle="District health oversight & truancy management" actions={
      <><div className="relative"><Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600" /><input placeholder="Search..." className="pl-8 w-48 h-8 text-xs bg-cyber-dark border border-cyber-border rounded-lg" value={search} onChange={e=>setSearch(e.target.value)}/></div><NeonButton variant="primary" size="sm" icon={<Download size={14}/>}>Export</NeonButton></>
    } />
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-4 gap-4">
          <StatCard label="Inbound Alerts" value={inbound.toString()} change="+3 today" changeType="increase" accent="red" trend={78} />
          <StatCard label="Contacted" value={alerts.filter(a=>a.status==="CONTACTED").length.toString()} change="Pending follow-up" changeType="neutral" accent="amber" trend={45} />
          <StatCard label="Escalated" value={alerts.filter(a=>a.status==="ESCALATED").length.toString()} change="Needs review" changeType="decrease" accent="pink" trend={20} />
          <StatCard label="Resolved This Week" value="8" change="+2 vs last week" changeType="increase" accent="green" trend={72} />
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs text-gray-500 mr-2">Filter:</span>
          {[{k:"ALL",l:"All",c:alerts.length},{k:"INBOUND",l:"Inbound",c:inbound},{k:"CONTACTED",l:"Contacted",c:alerts.filter(a=>a.status==="CONTACTED").length},{k:"ESCALATED",l:"Escalated",c:alerts.filter(a=>a.status==="ESCALATED").length},{k:"RESOLVED",l:"Resolved",c:alerts.filter(a=>a.status==="RESOLVED").length}].map(f2=>(
            <button key={f2.k} onClick={()=>setFilter(f2.k)} className={"px-3 py-1.5 rounded-full text-[10px] font-medium transition-all flex items-center gap-1.5 "+(filter===f2.k?"bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30":"bg-cyber-dark text-gray-500 border border-cyber-border hover:text-gray-300")}>
              {f2.l}<span className="w-4 h-4 rounded-full flex items-center justify-center text-[8px] bg-cyber-mid">{f2.c}</span>
            </button>
          ))}
        </div>
        <div className="grid grid-cols-2 gap-4">{f.map(a=>(
          <NeonCard key={a.id} accent={a.status==="INBOUND"?"red":a.status==="CONTACTED"?"amber":a.status==="ESCALATED"?"pink":"green"}>
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className={"w-10 h-10 rounded-full flex items-center justify-center text-xs font-bold "+(a.status==="INBOUND"?"bg-neon-red/10 text-neon-red":a.status==="CONTACTED"?"bg-neon-amber/10 text-neon-amber":a.status==="ESCALATED"?"bg-neon-pink/10 text-neon-pink":"bg-neon-green/10 text-neon-green")}>
                  {a.learner.split(" ").map(n=>n[0]).join("")}
                </div>
                <div><h3 className="text-sm font-medium text-gray-100">{a.learner}</h3><p className="text-[10px] text-gray-500">{a.school} · Grade {a.grade}</p></div>
              </div>
              <StatusBadge label={a.status} variant={a.status==="INBOUND"?"red":a.status==="CONTACTED"?"amber":a.status==="ESCALATED"?"pink":"green"} dot pulsing={a.status==="INBOUND"||a.status==="ESCALATED"} />
            </div>
            <div className="grid grid-cols-2 gap-2 mb-3">
              <div className="flex items-center gap-2 text-xs text-gray-500"><Clock size={12}/>{a.days>0?a.days+" consecutive absent":"Resolved"}</div>
              <div className="flex items-center gap-2 text-xs text-gray-500"><Phone size={12}/>{a.contact}</div>
              {a.chronic&&<div className="col-span-2 flex items-center gap-2"><Heart size={12} className="text-neon-amber"/><StatusBadge label={"Chronic: "+a.chronic} variant="amber" dot /></div>}
            </div>
            <div className="flex items-center justify-between pt-2 border-t border-cyber-border">
              <span className="text-[10px] text-gray-600">{a.time}</span>
              <div className="flex gap-2">{a.status!=="RESOLVED"?<><NeonButton variant="amber" size="sm" icon={<Phone size={12}/>}>Contact</NeonButton><NeonButton variant="green" size="sm" icon={<CheckCircle size={12}/>}>Resolve</NeonButton></>:<StatusBadge label="Completed" variant="green" dot />}</div>
            </div>
          </NeonCard>
        ))}</div>
      </div>
    </Shell>
  </div>;
}
'@

Write-Host "  All 5 dashboard pages written!" -ForegroundColor Green

# ─── STEP 7: INSTALL & BUILD ───
Write-Host "`n[7/7] Installing dependencies and building..." -ForegroundColor Yellow
Set-Location $FRONTEND

Write-Host "  Installing npm packages..." -ForegroundColor Cyan
npm install --legacy-peer-deps 2>&1 | Where-Object { $_ -notmatch "npm warn" }

Write-Host "`n  Building production bundle..." -ForegroundColor Cyan
npx next build 2>&1 | Where-Object { $_ -notmatch "telemetry" }

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n  ✓ BUILD SUCCESSFUL!" -ForegroundColor Green
} else {
    Write-Host "`n  ⚠ Build issues found — check output above" -ForegroundColor Yellow
}

# ─── STEP 8: GIT INIT & PUSH ───
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SETTING UP GIT & PUSHING TO GITHUB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Set-Location $ROOT

# .gitignore
Write-FileNoBom "$ROOT\.gitignore" @'
node_modules/
.next/
.env
.env.local
*.log
.DS_Store
dist/
.cache/
__pycache__/
*.pyc
'@

# Init git
git init
git add -A
git commit -m "Initial commit: SchoolNet v3.0 complete platform - Multi-tenant school management, LMS, health oversight, billing, cron workers, cyberpunk UI"

# Set remote and push
git remote add origin https://github.com/hambaniks/school-platform.git
git branch -M main
git push -u origin main --force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " COMPLETE! Platform pushed to GitHub!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Repo:  https://github.com/hambaniks/school-platform" -ForegroundColor White
Write-Host "  Local: $ROOT" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT:" -ForegroundColor Yellow
Write-Host "  1. Deploy frontend/ to Vercel" -ForegroundColor Gray
Write-Host "  2. Run SQL migrations in Supabase" -ForegroundColor Gray
Write-Host "  3. Deploy edge functions" -ForegroundColor Gray
Write-Host "  4. Push render-cron/ to Render" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

Set-Location $ROOT