// SA-SAMS CSV/XML Parser — non-overwrite ingestion
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { parse } from "https://deno.land/std@0.208.0/csv/parse.ts";

serve(async (req) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const form = await req.formData();
  const file = form.get("file") as File;
  const schoolId = form.get("school_id") as string;
  if (!file || !schoolId) return new Response(JSON.stringify({ error: "file and school_id required" }), { status: 400 });

  const text = await file.text();
  const rows = parse(text, { skipFirstRow: true, columns: ["id_number","full_name","grade","class_name","date_of_birth"] });

  const { data: existing } = await supabase.from("learners").select("id_number").eq("school_id", schoolId);
  const existingSet = new Set(existing?.map((l: any) => l.id_number) || []);

  const newLearners = rows.filter((r: any) => !existingSet.has(r.id_number));
  if (newLearners.length === 0) return new Response(JSON.stringify({ inserted: 0, skipped: rows.length }));

  const { data, error } = await supabase.from("learners").insert(
    newLearners.map((r: any) => ({ ...r, school_id: schoolId, date_of_birth: r.date_of_birth || null }))
  );
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  return new Response(JSON.stringify({ inserted: newLearners.length, skipped: rows.length - newLearners.length }), {
    headers: { "Content-Type": "application/json" },
  });
});