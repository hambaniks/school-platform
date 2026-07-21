// Monthly Health PDF — anonymized summary sent to health desk
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async () => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const healthEmail = Deno.env.get("HEALTH_DEPT_EMAIL") || "health-regional@education.gov.za";

  // Aggregate alerts by school (anonymized)
  const { data: alerts } = await supabase
    .from("clinical_alerts")
    .select("school_id, severity, status, chronic_flag, created_at")
    .gte("created_at", new Date(Date.now() - 30 * 86400000).toISOString());

  if (!alerts || alerts.length === 0) return new Response(JSON.stringify({ message: "No alerts this month" }));

  const summary = alerts.reduce((acc: any, a: any) => {
    const key = a.school_id;
    if (!acc[key]) acc[key] = { school_id: key, total: 0, chronic: 0, critical: 0, resolved: 0 };
    acc[key].total++;
    if (a.chronic_flag) acc[key].chronic++;
    if (a.severity === "critical") acc[key].critical++;
    if (a.status === "resolved") acc[key].resolved++;
    return acc;
  }, {});

  const anonymizedReport = Object.values(summary);

  const pdfContent = JSON.stringify({
    generated_at: new Date().toISOString(),
    period: "monthly",
    total_alerts: alerts.length,
    schools: anonymizedReport,
    email_recipient: healthEmail,
  });

  // Upload report to storage
  const fileName = `health-report-${new Date().toISOString().split("T")[0]}.json`;
  const { error } = await supabase.storage
    .from("official-reports")
    .upload(`${fileName}`, pdfContent, { contentType: "application/json", upsert: true });

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  return new Response(JSON.stringify({ report: fileName, schools: anonymizedReport }), {
    headers: { "Content-Type": "application/json" },
  });
});