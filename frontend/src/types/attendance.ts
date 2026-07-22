export type AttendanceStatus = "present" | "absent" | "late" | "excused";

export interface AttendanceRecord {
  id: string;
  learner_id: string;
  learner_name?: string;
  grade?: string;
  subject?: string;
  date: string;
  status: AttendanceStatus;
  method?: "roll-call" | "qr" | "biometric";
  marked_by?: string;
  created_at: string;
  updated_at: string;
}

export interface AttendanceStats {
  present: number;
  absent: number;
  late: number;
  excused: number;
  total: number;
  percentage: number;
}

export interface Learner {
  id: string;
  name: string;
  grade: string;
  status: AttendanceStatus;
}

export interface AttendanceDay {
  date: number;
  present: number;
  absent: number;
  late: number;
  total: number;
}