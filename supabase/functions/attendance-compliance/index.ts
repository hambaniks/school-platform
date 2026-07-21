// Attendance Compliance Lock — 14:00 cutoff enforcement
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async () => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const now = new Date();
  const cutoffHour = parseInt(Deno.env.get("ATTENDANCE_CUTOFF_HOUR") || "14");

  if (now.getHours() < cutoffHour) {
    return new Response(JSON.stringify({ message: "Before cutoff, no action needed" }));
  }

  const today = now.toISOString().split("T")[0];
  const { data: learners, error } = await supabase
    .from("learners")
    .select("id, school_id, full_name")
    .eq("is_active", true);

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });

  // Get existing attendance for today per learner+period 1
  const { data: existing } = await supabase
    .from("attendance")
    .select("learner_id")
    .eq("date", today)
    .eq("period", 1);

  const recorded = new Set(existing?.map((r: any) => r.learner_id) || []);
  const missing = learners.filter((l: any) => !recorded.has(l.id));

  if (missing.length === 0) return new Response(JSON.stringify({ flagged: 0 }));

  // Create compliance flags
  const { data: flagData, error: flagError } = await supabase.from("compliance_flags").insert(
    missing.map((l: any) => ({
      learner_id: l.id,
      school_id: l.school_id,
      date: today,
      reason: "Attendance not recorded by cutoff",
      status: "pending",
    }))
  );

  if (flagError) return new Response(JSON.stringify({ error: flagError.message }), { status: 500 });
  return new Response(JSON.stringify({ flagged: missing.length, message: "Compliance flags created" }));
});