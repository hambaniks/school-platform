// Billing Convert — Multi-currency conversion using fixed rates
import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";

const EXCHANGE_RATES: Record<string, number> = {
  ZAR: 1, USD: 18.5, EUR: 20.1, GBP: 23.4, BWP: 1.37, NAD: 1.0, SZL: 1.0, LSL: 1.0, MZN: 0.29, ZMW: 0.72, MWK: 0.011
};

serve(async (req) => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { invoice_id, target_currency = "ZAR" } = await req.json().catch(() => ({}));

  let query = supabase.from("billing").select("*");
  if (invoice_id) query = query.eq("id", invoice_id);
  const { data: invoices, error } = await query;
  if (error) return new Response(JSON.stringify({ error }), { status: 500 });

  const results = [];
  for (const inv of invoices || []) {
    const sourceRate = EXCHANGE_RATES[inv.currency] || 1;
    const targetRate = EXCHANGE_RATES[target_currency] || 1;
    const convertedAmount = Number(inv.amount) * (targetRate / sourceRate);
    
    if (inv.currency !== target_currency) {
      await supabase.from("billing").update({
        amount: Math.round(convertedAmount * 100) / 100,
        currency: target_currency
      }).eq("id", inv.id);
    }
    results.push({ id: inv.id, original: Number(inv.amount), converted: Math.round(convertedAmount * 100) / 100, from: inv.currency, to: target_currency, rate: Math.round((targetRate / sourceRate) * 10000) / 10000 });
  }

  return new Response(JSON.stringify({ converted: results.length, results }), { headers: { "Content-Type": "application/json" } });
});
