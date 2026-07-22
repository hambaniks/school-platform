// Truancy Prediction — ML risk scoring via weighted heuristic model
import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";

serve(async (req) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { school_id, learner_id } = await req.json().catch(() => ({}));
  
  let query = supabase.from("attendance").select("learner_id, status, date, learners!inner(school_id, full_name, grade, chronic_conditions)");
  if (school_id) query = query.eq("learners.school_id", school_id);
  if (learner_id) query = query.eq("learner_id", learner_id);
  query = query.gte("date", new Date(Date.now() - 30 * 86400000).toISOString().split("T")[0]);
  
  const { data: records, error } = await query;
  if (error) return new Response(JSON.stringify({ error }), { status: 500 });

  const learnerMap = new Map<string, { name: string; grade: string; total: number; absent: number; late: number; chronic: boolean; days: Set<string> }>();
  for (const r of records || []) {
    const lid = r.learner_id;
    if (!learnerMap.has(lid)) learnerMap.set(lid, {
      name: (r as any).learners?.full_name || "Unknown",
      grade: (r as any).learners?.grade || "N/A",
      total: 0, absent: 0, late: 0, chronic: !!(r as any).learners?.chronic_conditions?.length, days: new Set()
    });
    const entry = learnerMap.get(lid)!;
    entry.total++;
    if (r.status === "absent" || r.status === "sick") entry.absent++;
    if (r.status === "late") entry.late++;
    entry.days.add(r.date);
  }

  const predictions = [];
  for (const [lid, data] of learnerMap) {
    const attendanceRate = data.total > 0 ? ((data.total - data.absent) / data.total) * 100 : 100;
    const absenceStreak = data.absent;
    let riskScore = Math.round((100 - attendanceRate) * 0.6 + (absenceStreak > 5 ? 30 : absenceStreak * 5) + (data.chronic ? 15 : 0) + (data.late > 10 ? 10 : data.late * 1));
    riskScore = Math.min(100, Math.max(0, riskScore));
    const flags: string[] = [];
    if (riskScore >= 70) flags.push("HIGH_RISK");
    if (attendanceRate < 80) flags.push("POOR_ATTENDANCE");
    if (absenceStreak >= 5) flags.push("ABSENCE_STREAK");
    if (data.chronic) flags.push("CHRONIC_CONDITION");
    if (data.late > 10) flags.push("CHRONIC_LATENESS");
    const trend = absenceStreak > 3 ? "deteriorating" : absenceStreak > 1 ? "stable" : "improving";
    predictions.push({
      learner_id: lid, risk_score: riskScore, attendance_rate: Math.round(attendanceRate * 10) / 10,
      days_absent_30d: data.absent, trend, flags, recommended_action: riskScore >= 70 ? "Immediate intervention required" : riskScore >= 40 ? "Monitor closely" : "On track",
      model_version: "heuristic-v1"
    });
  }
  
  const { error: upsertError } = await supabase.from("truancy_predictions").upsert(
    predictions.map(p => ({ ...p, school_id: school_id || null })),
    { onConflict: "learner_id", ignoreDuplicates: false }
  );
  if (upsertError) return new Response(JSON.stringify({ error: upsertError.message }), { status: 500 });
  return new Response(JSON.stringify({ predictions: predictions.length }), { headers: { "Content-Type": "application/json" } });
});
