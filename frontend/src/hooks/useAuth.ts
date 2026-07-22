"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import { createBrowserClient } from "@supabase/ssr";
import type { User } from "@supabase/supabase-js";

interface Profile {
  id: string;
  full_name?: string;
  role?: string;
  school_id?: string;
  avatar_url?: string;
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const supabaseRef = useRef(createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  ));

  const refreshProfile = useCallback(async (userId: string) => {
    const { data, error } = await supabaseRef.current
      .from("profiles")
      .select("*")
      .eq("id", userId)
      .single();
    if (!error && data) setProfile(data);
  }, []);

  useEffect(() => {
    const sb = supabaseRef.current;

    sb.auth.getUser().then(({ data: { user: u } }) => {
      setUser(u ?? null);
      if (u) refreshProfile(u.id);
      setLoading(false);
    });

    const { data: listener } = sb.auth.onAuthStateChange((_event, session) => {
      const u = session?.user ?? null;
      setUser(u);
      if (u) refreshProfile(u.id);
      else setProfile(null);
    });

    return () => listener?.subscription.unsubscribe();
  }, [refreshProfile]);

  const signOut = useCallback(async () => {
    await supabaseRef.current.auth.signOut();
    setUser(null);
    setProfile(null);
  }, []);

  return { user, profile, loading, signOut, refreshProfile };
}