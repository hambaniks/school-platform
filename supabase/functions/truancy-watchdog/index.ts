// Truancy Watchdog — runs nightly via Supabase cron or Render
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
const THRESHOLD = 3;

serve(async () => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: truants } = await supabase.rpc("find_truants", { threshold_days: THRESHOLD });
  if (!truants || truants.length === 0) return new Response(JSON.stringify({ alerts_created: 0 }));

  const alerts = truants.map((t: any) => ({
    learner_id: t.learner_id,
    school_id: t.school_id,
    consecutive_absences: t.absent_days,
    severity: t.absent_days >= 7 ? "critical" : t.absent_days >= 5 ? "high" : "medium",
    status: "inbound",
    chronic_flag: t.has_chronic || false,
  }));

  const { data, error } = await supabase.from("clinical_alerts").insert(alerts).select();
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  return new Response(JSON.stringify({ alerts_created: data.length }), { headers: { "Content-Type": "application/json" } });
});