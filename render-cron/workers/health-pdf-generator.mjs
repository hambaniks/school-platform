import { createClient } from "@supabase/supabase-js";
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const healthEmail = process.env.HEALTH_DEPT_EMAIL || "health-regional@education.gov.za";

async function run() {
  console.log("[Health PDF Generator] Generating monthly report...");

  const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString();
  const { data: alerts } = await supabase
    .from("clinical_alerts")
    .select("school_id, severity, status, chronic_flag")
    .gte("created_at", thirtyDaysAgo);

  if (!alerts?.length) { console.log("No alerts this month."); return; }

  const summary = {};
  for (const a of alerts) {
    if (!summary[a.school_id]) summary[a.school_id] = { school_id: a.school_id, total: 0, chronic: 0, critical: 0, resolved: 0 };
    summary[a.school_id].total++;
    if (a.chronic_flag) summary[a.school_id].chronic++;
    if (a.severity === "critical") summary[a.school_id].critical++;
    if (a.status === "resolved") summary[a.school_id].resolved++;
  }

  const report = {
    generated_at: new Date().toISOString(),
    period: "monthly",
    total_alerts: alerts.length,
    schools: Object.values(summary),
    email_recipient: healthEmail,
  };

  const fileName = `health-report-${new Date().toISOString().split("T")[0]}.json`;
  const { error } = await supabase.storage
    .from("official-reports")
    .upload(fileName, JSON.stringify(report, null, 2), { contentType: "application/json", upsert: true });

  if (error) { console.error("Upload error:", error); return; }
  console.log(`Report uploaded: ${fileName}`);
}

run().catch(console.error);