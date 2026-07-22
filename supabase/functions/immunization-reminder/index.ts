// Immunization Reminder — Check upcoming due dates and create alerts
import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";

serve(async (req) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  
  const { data: upcoming, error } = await supabase
    .from("immunization")
    .select("id, learner_id, vaccine_name, dose_number, next_due_date, learners!inner(school_id, full_name, parent_id, profiles!inner(full_name, phone, email))")
    .lte("next_due_date", new Date(Date.now() + 14 * 86400000).toISOString().split("T")[0])
    .gte("next_due_date", new Date().toISOString().split("T")[0])
    .is("notes", null);

  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  if (!upcoming || upcoming.length === 0) return new Response(JSON.stringify({ reminders: 0 }));

  const reminders = [];
  for (const record of upcoming) {
    reminders.push({
      learner_id: record.learner_id,
      vaccine_name: record.vaccine_name,
      dose_number: record.dose_number,
      due_date: record.next_due_date,
      parent_contact: (record as any).learners?.profiles?.phone || "N/A",
      parent_email: (record as any).learners?.profiles?.email || "N/A"
    });
    
    await supabase.from("immunization").update({
      notes: `Reminder sent: due ${record.next_due_date}`
    }).eq("id", record.id);
  }

  return new Response(JSON.stringify({ reminders: reminders.length, data: reminders }), {
    headers: { "Content-Type": "application/json" }
  });
});
