"use client";
import { useState, useCallback, useRef, useEffect } from "react";

interface TruancyPrediction {
  id: string;
  learner_name: string;
  grade: string;
  risk_score: number;
  risk_level: "low" | "medium" | "high";
  absences: number;
  trend: "increasing" | "stable" | "decreasing";
  factors: string[];
  last_attendance: string;
}

export function useTruancy() {
  const [predictions, setPredictions] = useState<TruancyPrediction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const fetchPredictions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/attendance?status=absent&limit=20");
      if (!res.ok) throw new Error(`API error: ${res.status}`);

      // Build mock predictions from absence data
      const data = await res.json();
      const names = ["Thabo Mokoena", "Lerato Dlamini", "Sipho Nkosi", "Zanele Khumalo", "Kagiso Molefe", "Busisiwe Zulu"];
      const demoPredictions: TruancyPrediction[] = names.map((name, i) => ({
        id: `pred-${i + 1}`,
        learner_name: name,
        grade: ["10A", "11B", "9C", "12A", "8B", "10C"][i],
        risk_score: Math.round((Math.random() * 40 + 30) * 10) / 10,
        risk_level: (i < 2 ? "high" : i < 4 ? "medium" : "low") as "low" | "medium" | "high",
        absences: Math.floor(Math.random() * 12 + 1),
        trend: (["increasing", "stable", "decreasing"] as const)[i % 3],
        factors: ["Late arrivals ×4", "No guardian contact", "Declining grades"].slice(0, Math.floor(Math.random() * 3) + 1),
        last_attendance: ["absent", "absent", "present", "late", "absent", "present"][i],
      }));
      if (mountedRef.current) setPredictions(demoPredictions);
    } catch (err: any) {
      if (mountedRef.current) setError(err.message || "Failed to fetch predictions");
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    return () => { mountedRef.current = false; };
  }, []);

  return { predictions, loading, error, fetchPredictions };
}