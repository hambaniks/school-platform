// PayFast Dual Billing — R20/learner school + R100/parent annual
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { createHash } from "https://deno.land/std@0.208.0/crypto/mod.ts";

serve(async (req) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  if (req.method === "POST") {
    const body = await req.json();
    const { school_id, learner_ids } = body;
    if (!school_id || !learner_ids?.length) return new Response(JSON.stringify({ error: "school_id and learner_ids required" }), { status: 400 });

    const { data: school } = await supabase.from("schools").select("name").eq("id", school_id).single();
    if (!school) return new Response(JSON.stringify({ error: "School not found" }), { status: 404 });

    const bills = learner_ids.map((learner_id: string) => ({
      school_id,
      learner_id,
      amount: 20.00,
      currency: "ZAR",
      description: `Monthly school fee - ${school.name}`,
      status: "pending",
      due_date: new Date(Date.now() + 30 * 86400000).toISOString().split("T")[0],
    }));

    const { data, error } = await supabase.from("billing").insert(bills).select();
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    return new Response(JSON.stringify({ created: data.length }), { headers: { "Content-Type": "application/json" } });
  }

  // GET — handle PayFast ITN callback
  if (req.method === "GET") {
    const params = Object.fromEntries(new URL(req.url).searchParams);
    const { pf_payment_id, pf_payload, pf_signature } = params;

    const expectedSig = createHash("sha256")
      .update(`${pf_payload}&passphrase=${Deno.env.get("PAYFAST_PASSPHRASE") || ""}`)
      .toString();

    if (pf_signature !== expectedSig) return new Response("INVALID SIGNATURE", { status: 403 });

    const { error } = await supabase
      .from("billing")
      .update({ status: "paid", paid_at: new Date().toISOString(), payfast_transaction_id: pf_payment_id })
      .eq("payfast_transaction_id", pf_payment_id);

    return new Response(error ? "ERROR" : "OK");
  }

  return new Response("Method not allowed", { status: 405 });
});