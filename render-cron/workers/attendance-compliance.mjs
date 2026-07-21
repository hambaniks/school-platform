import { createClient } from "@supabase/supabase-js";
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function run() {
  console.log("[Attendance Compliance] Checking attendance records...");
  const now = new Date();
  const today = now.toISOString().split("T")[0];

  const { data: learners } = await supabase.from("learners").select("id, school_id").eq("is_active", true);
  if (!learners?.length) { console.log("No active learners."); return; }

  const { data: existing } = await supabase.from("attendance").select("learner_id").eq("date", today).eq("period", 1);
  const recorded = new Set(existing?.map(r => r.learner_id) || []);
  const missing = learners.filter(l => !recorded.has(l.id));

  if (!missing.length) { console.log("All attendance recorded."); return; }

  // Ensure compliance_flags table exists or use an existing mechanism
  console.log(`Flagging ${missing.length} learners with missing attendance`);
  // In production, insert into a compliance_flags table or send alerts
}

run().catch(console.error);