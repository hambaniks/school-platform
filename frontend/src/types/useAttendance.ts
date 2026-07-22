"use client";
import { useState, useCallback, useEffect, useRef } from "react";
import type { AttendanceRecord, AttendanceStats, Learner } from "@/types";

export function useAttendance(options?: { autoFetch?: boolean }) {
  const [records, setRecords] = useState<AttendanceRecord[]>([]);
  const [learners, setLearners] = useState<Learner[]>([]);
  const [stats, setStats] = useState<AttendanceStats>({ present: 0, absent: 0, late: 0, excused: 0, total: 0, percentage: 0 });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const fetchAttendance = useCallback(async (filters?: { date?: string; grade?: string; status?: string; learnerId?: string }) => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (filters?.date) params.set("date", filters.date);
      if (filters?.grade) params.set("grade", filters.grade);
      if (filters?.status) params.set("status", filters.status);
      if (filters?.learnerId) params.set("learnerId", filters.learnerId);

      const res = await fetch(`/api/attendance?${params.toString()}`);
      if (!res.ok) throw new Error(`API error: ${res.status}`);
      const data = await res.json();
      if (mountedRef.current) {
        setRecords(data.records || []);
        setLearners(data.learners || []);
        setStats(data.stats || { present: 0, absent: 0, late: 0, excused: 0, total: 0, percentage: 0 });
      }
    } catch (err: any) {
      if (mountedRef.current) setError(err.message || "Failed to fetch attendance");
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  const markAttendance = useCallback(async (entries: { learner_id: string; date: string; status: string; method?: string }[]) => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/attendance", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ entries }),
      });
      if (!res.ok) throw new Error(`API error: ${res.status}`);
      const data = await res.json();
      if (mountedRef.current) {
        if (data.records) setRecords(data.records);
        if (data.stats) setStats(data.stats);
      }
      return data;
    } catch (err: any) {
      if (mountedRef.current) setError(err.message || "Failed to mark attendance");
      return null;
    } finally {
      if (mountedRef.current) setLoading(false);
    }
  }, []);

  const updateAttendance = useCallback(async (id: string, status: string) => {
    try {
      const res = await fetch("/api/attendance", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, status }),
      });
      if (!res.ok) throw new Error(`API error: ${res.status}`);
      const data = await res.json();
      if (mountedRef.current && data.record) {
        setRecords((prev) => prev.map((r) => (r.id === id ? data.record : r)));
        if (data.stats) setStats(data.stats);
      }
      return data;
    } catch (err: any) {
      if (mountedRef.current) setError(err.message || "Failed to update attendance");
      return null;
    }
  }, []);

  useEffect(() => {
    return () => { mountedRef.current = false; };
  }, []);

  useEffect(() => {
    if (options?.autoFetch !== false) fetchAttendance();
  }, [fetchAttendance, options?.autoFetch]);

  return { records, learners, stats, loading, error, fetchAttendance, markAttendance, updateAttendance };
}