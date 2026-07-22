import { createClient } from "@supabase/supabase-js";
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const THRESHOLD = 3;

async function run() {
  console.log("[Truancy Watchdog] Starting scan...");
  const { data: truants, error } = await supabase.rpc("find_truants", { threshold_days: THRESHOLD });
  if (error) { console.error("RPC error:", error); return; }
  if (!truants?.length) { console.log("No truants found."); return; }
  const alerts = truants.map(t => ({
    learner_id: t.learner_id, school_id: t.school_id, consecutive_absences: t.absent_days,
    severity: t.absent_days >= 7 ? "critical" : t.absent_days >= 5 ? "high" : "medium",
    status: "inbound", chronic_flag: t.has_chronic || false,
  }));
  const { data, error: insertError } = await supabase.from("clinical_alerts").insert(alerts).select();
  if (insertError) { console.error("Insert error:", insertError); return; }
  console.log(`Created ${data.length} truancy alerts`);
}
run().catch(console.error);
