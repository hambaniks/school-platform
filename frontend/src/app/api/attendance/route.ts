import { NextResponse } from "next/server";

// Supabase client (server-side)
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

function createClient() {
  const cookieStore = cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set() {},
        remove() {},
      },
    }
  );
}

// GET /api/attendance — query records with optional filters
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const date = searchParams.get("date");
    const grade = searchParams.get("grade");
    const status = searchParams.get("status");
    const learnerId = searchParams.get("learnerId");
    const limit = Math.min(parseInt(searchParams.get("limit") || "100"), 500);

    const sb = createClient();
    let query = sb.from("attendance_records").select("*, learners!inner(name, grade)");

    if (date) query = query.eq("date", date);
    if (grade) query = query.eq("learners.grade", grade);
    if (status) query = query.eq("status", status);
    if (learnerId) query = query.eq("learner_id", learnerId);

    query = query.order("created_at", { ascending: false }).limit(limit);

    const { data: records, error } = await query;
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    // Compute summary stats
    const total = records?.length || 0;
    const present = records?.filter((r: any) => r.status === "present").length || 0;
    const absent = records?.filter((r: any) => r.status === "absent").length || 0;
    const late = records?.filter((r: any) => r.status === "late").length || 0;
    const excused = records?.filter((r: any) => r.status === "excused").length || 0;
    const percentage = total > 0 ? Math.round(((present + late) / total) * 100) : 0;

    return NextResponse.json({
      records,
      stats: { present, absent, late, excused, total, percentage },
      learners: records?.map((r: any) => ({
        id: r.learner_id,
        name: r.learners?.name || "Unknown",
        grade: r.learners?.grade || "",
        status: r.status,
      })) || [],
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || "Internal server error" }, { status: 500 });
  }
}

// POST /api/attendance — bulk upsert attendance entries
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { entries } = body;

    if (!Array.isArray(entries) || entries.length === 0) {
      return NextResponse.json({ error: "entries array is required" }, { status: 400 });
    }

    const sb = createClient();
    const { data, error } = await sb
      .from("attendance_records")
      .upsert(
        entries.map((e: any) => ({
          learner_id: e.learner_id,
          date: e.date,
          status: e.status,
          method: e.method || "roll-call",
        })),
        { onConflict: "learner_id,date", ignoreDuplicates: false }
      )
      .select();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    return NextResponse.json({ records: data, message: `${entries.length} attendance records saved` });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || "Internal server error" }, { status: 500 });
  }
}

// PUT /api/attendance — update a single attendance record
export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { id, status } = body;

    if (!id || !status) {
      return NextResponse.json({ error: "id and status are required" }, { status: 400 });
    }

    const sb = createClient();
    const { data, error } = await sb
      .from("attendance_records")
      .update({ status, updated_at: new Date().toISOString() })
      .eq("id", id)
      .select()
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    return NextResponse.json({ record: data, message: "Attendance updated" });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || "Internal server error" }, { status: 500 });
  }
}