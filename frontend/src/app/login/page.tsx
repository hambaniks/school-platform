"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";
import { Shield, Eye, EyeOff, Loader2, ChevronRight } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error: authErr } = await supabase.auth.signInWithPassword({ email, password });
    if (authErr) { setError(authErr.message); setLoading(false); return; }

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("Login failed"); setLoading(false); return; }

    const { data: profile } = await supabase
      .from("profiles").select("role").eq("id", user.id).single();

    setLoading(false);
    const role = (profile?.role as string) || "teacher";
    const redirectMap: Record<string, string> = {
      superadmin: "/superadmin", schooladmin: "/schooladmin",
      teacher: "/teacher", parent: "/parent", clinic: "/clinic",
    };
    router.push(redirectMap[role] || "/teacher");
  };

  return (
    <div className="min-h-screen bg-cyber-black flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-3 px-4 py-2 rounded-full bg-neon-cyan/5 border border-neon-cyan/20 mb-4">
            <Shield size={14} className="text-neon-cyan" />
            <span className="text-[11px] text-neon-cyan font-medium">SCHOOLNET v3.0</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-100">Sign in to your account</h1>
          <p className="text-gray-500 text-sm mt-1">Multi-tenant school management platform</p>
        </div>

        <form onSubmit={handleLogin} className="bg-cyber-card border border-cyber-border rounded-xl p-6 space-y-4">
          {error && (
            <div className="p-3 rounded-lg bg-neon-red/10 border border-neon-red/30 text-neon-red text-xs">{error}</div>
          )}

          <div>
            <label className="block text-xs font-medium text-gray-400 mb-1.5">Email</label>
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
              placeholder="you@school.edu.za" required
              className="w-full px-3 py-2.5 rounded-lg bg-cyber-dark border border-cyber-border text-gray-100 text-sm placeholder-gray-600 focus:outline-none focus:border-neon-cyan/50 focus:ring-1 focus:ring-neon-cyan/20 transition-all" />
          </div>

          <div>
            <label className="block text-xs font-medium text-gray-400 mb-1.5">Password</label>
            <div className="relative">
              <input type={showPw ? "text" : "password"} value={password} onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••" required
                className="w-full px-3 py-2.5 pr-10 rounded-lg bg-cyber-dark border border-cyber-border text-gray-100 text-sm placeholder-gray-600 focus:outline-none focus:border-neon-cyan/50 focus:ring-1 focus:ring-neon-cyan/20 transition-all" />
              <button type="button" onClick={() => setShowPw(!showPw)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300">
                {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <button type="submit" disabled={loading}
            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30 text-sm font-medium hover:bg-neon-cyan/20 transition-all disabled:opacity-50">
            {loading ? <Loader2 size={16} className="animate-spin" /> : <Shield size={16} />}
            {loading ? "Signing in..." : "Sign in"}
            {!loading && <ChevronRight size={16} />}
          </button>

          <p className="text-[10px] text-gray-600 text-center">Secured with Supabase Auth · POPIA Compliant</p>
        </form>
      </div>
    </div>
  );
}
