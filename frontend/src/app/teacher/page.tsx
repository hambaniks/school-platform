"use client";
import { Shell } from "@/components/layout/Shell";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { useState } from "react";
import { ClipboardCheck, Users, BookOpen, FileText, Upload, Clock, CheckCircle, XCircle, AlertTriangle } from "lucide-react";

const nav = [
  { label: "Dashboard", href: "/teacher", icon: <ClipboardCheck size={18} /> },
  { label: "Classes", href: "/teacher/classes", icon: <Users size={18} />, badge: "4" },
  { label: "Gradebook", href: "/teacher/gradebook", icon: <BookOpen size={18} /> },
  { label: "Documents", href: "/teacher/documents", icon: <FileText size={18} />, badge: "3" },
  { label: "Timetable", href: "/teacher/timetable", icon: <Clock size={18} /> },
];

const roster = [
  { name: "Lethabo Mokoena", grade: "10A", present: true, late: false },
  { name: "Thabo Nkosi", grade: "10B", present: false, late: false },
  { name: "Karabo Molefe", grade: "10A", present: true, late: true },
  { name: "Zanele Khumalo", grade: "11A", present: true, late: false },
  { name: "Sipho Dlamini", grade: "10A", present: false, late: false },
  { name: "Bongani Zulu", grade: "10A", present: true, late: false },
  { name: "Lerato Molefe", grade: "10A", present: true, late: false },
  { name: "Nomsa Ngwenya", grade: "10B", present: true, late: true },
];

const students = [
  { name: "Lethabo Mokoena", present: true, late: false },
  { name: "Thabo Nkosi", present: false, late: false },
  { name: "Karabo Molefe", present: true, late: true },
  { name: "Sipho Dlamini", present: false, late: false },
  { name: "Bongani Zulu", present: true, late: false },
  { name: "Lerato Molefe", present: true, late: false },
];

export default function Teacher() {
  const [rosterState, setRoster] = useState(roster);
  const toggle = (idx: number, mode: "p" | "l" | "a") => {
    setRoster(rosterState.map((s, i) => i === idx ? {
      ...s,
      present: mode === "p" ? true : mode === "l" ? true : false,
      late: mode === "l" ? true : false
    } : s));
  };

  const p = rosterState.filter(s => s.present && !s.late).length;
  const l = rosterState.filter(s => s.late).length;
  const a = rosterState.filter(s => !s.present && !s.late).length;

  return (
    <div className="min-h-screen bg-cyber-black">
      <Sidebar items={nav} role="TEACHER" userName="Ms. Dlamini" schoolName="Springfield High School" />
      <Shell>
        <TopBar title="Teacher Command Center" subtitle="Mathematics · Grade 10A–11A · 4 classes" actions={
          <NeonButton variant="primary" size="sm" icon={<Upload size={14} />}>Submit Attendance</NeonButton>
        } />
        <div className="p-6 animate-fade-in">
          <div className="grid grid-cols-3 gap-6">
            <NeonCard title="Attendance Toggle" subtitle="Period 1 · Mathematics 10A" accent="green">
              <NeonCard title="" className="mb-4">
                <div className="flex gap-4 text-xs"><StatusBadge label={p + " PRESENT"} variant="green" dot /><StatusBadge label={l + " LATE"} variant="amber" dot /><StatusBadge label={a + " ABSENT"} variant="red" dot /></div>
              </NeonCard>
              <div className="space-y-1 max-h-[420px] overflow-y-auto">
                {rosterState.map((s, i) => (
                  <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker transition-colors border border-transparent">
                    <div className="flex items-center gap-3">
                      <div className={"w-8 h-8 rounded-full flex items-center justify-center text-[10px] font-bold " + (s.present && !s.late ? "bg-neon-green/10 text-neon-green" : s.late ? "bg-neon-amber/10 text-neon-amber" : "bg-neon-red/10 text-neon-red")}>
                        {s.name.split(" ").map(n => n[0]).join("").slice(0, 2)}
                      </div>
                      <div><p className="text-xs text-gray-200">{s.name}</p><p className="text-[10px] text-gray-600">Grade {s.grade}</p></div>
                    </div>
                    <div className="flex gap-1.5">
                      {["p", "l", "a"].map(m => {
                        const active = m === "p" ? s.present && !s.late : m === "l" ? s.late : m === "a" ? !s.present && !s.late : false;
                        const c = m === "p" ? "green" : m === "l" ? "amber" : "red";
                        return (
                          <button key={m} onClick={() => toggle(i, m as "p" | "l" | "a")}
                            className={"w-7 h-7 rounded flex items-center justify-center text-[10px] font-medium transition-all cursor-pointer " + (active ? `bg-neon-${c}/20 border border-neon-${c}/30 text-neon-${c}` : "bg-cyber-dark border border-cyber-border text-gray-600")}>
                            {m.toUpperCase()}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-3 pt-3 border-t border-cyber-border flex justify-between">
                <span className="text-[10px] text-gray-600">{p + l}/{roster.length} recorded</span>
                <NeonButton variant="primary" size="sm">Submit</NeonButton>
              </div>
            </NeonCard>

            <NeonCard title="Gradebook Quick Entry" subtitle="Quadratic Functions Test" accent="purple">
              <div className="space-y-2 max-h-[420px] overflow-y-auto">
                {students.slice(0, 8).map((s, i) => (
                  <div key={i} className="flex items-center justify-between py-2">
                    <span className="text-xs text-gray-200 w-36 truncate">{s.name}</span>
                    <div className="flex items-center gap-2">
                      <input type="number" placeholder="—" className="w-16 text-center font-mono text-xs bg-cyber-dark border border-cyber-border rounded px-2 py-1.5" />
                      <span className="text-[10px] text-gray-600">/100</span>
                    </div>
                  </div>
                ))}
              </div>
              <NeonButton variant="purple" size="sm" className="w-full mt-3" icon={<BookOpen size={14} />}>Open Full Gradebook</NeonButton>
            </NeonCard>

            <div className="space-y-6">
              <NeonCard title="Documents" subtitle="Lesson notes & resources" accent="green">
                <div className="space-y-2">
                  {[{ n: "Quadratic Functions Notes.pdf", s: "2.4 MB" }, { n: "Homework Set 3.pdf", s: "1.1 MB" }, { n: "Term 3 Scheme.docx", s: "856 KB" }].map((d, i) => (
                    <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker cursor-pointer">
                      <div className="flex items-center gap-3"><FileText size={16} className="text-neon-green" /><div><p className="text-xs text-gray-200">{d.n}</p><p className="text-[9px] text-gray-600">{d.s}</p></div></div>
                    </div>
                  ))}
                </div>
                <NeonButton variant="green" size="sm" className="w-full mt-3" icon={<Upload size={14} />}>Upload Resource</NeonButton>
              </NeonCard>
              <NeonCard title="Upcoming" accent="amber">
                {[{ l: "Test: Algebra", d: "24 Jul" }, { l: "Parent Meeting", d: "26 Jul" }, { l: "Assignment Due", d: "28 Jul" }].map((e, i) => (
                  <div key={i} className="flex items-center justify-between py-1.5"><span className="text-xs text-gray-200">{e.l}</span><StatusBadge label={e.d} variant="amber" /></div>
                ))}
              </NeonCard>
            </div>
          </div>
        </div>
      </Shell>
    </div>
  );
}