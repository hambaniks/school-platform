"use client";
import { Shell } from "@/components/layout/Shell";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { Calendar, Bell, AlertTriangle, Heart, User, FileText, CreditCard, Clock, CheckCircle, XCircle } from "lucide-react";

const nav = [
  { label: "Home", href: "/parent", icon: <User size={18} /> },
  { label: "Assignments", href: "/parent/assignments", icon: <FileText size={18} />, badge: "2" },
  { label: "Attendance", href: "/parent/attendance", icon: <Clock size={18} /> },
  { label: "Billing", href: "/parent/billing", icon: <CreditCard size={18} />, badge: "UNPAID" },
  { label: "Medical", href: "/parent/medical", icon: <Heart size={18} /> },
  { label: "Alerts", href: "/parent/alerts", icon: <Bell size={18} /> },
];

const children = [
  { name: "Lethabo Mokoena", grade: "10A", attendance: 94, chronic: null, avg: "B" },
  { name: "Karabo Mokoena", grade: "7B", attendance: 88, chronic: "Asthma", avg: "A-" },
];

export default function Parent() {
  return (
    <div className="min-h-screen bg-cyber-black">
      <Sidebar items={nav} role="PARENT" userName="Mrs. Mokoena" schoolName="Springfield High School" />
      <Shell>
        <TopBar title="Parent Portal" subtitle="Your children in real time" actions={
          <NeonButton variant="primary" size="sm" icon={<Bell size={14} />}>Notifications <span className="ml-1 w-4 h-4 rounded-full bg-neon-red text-[9px] inline-flex items-center justify-center font-bold">3</span></NeonButton>
        } />
        <div className="p-6 space-y-6 animate-fade-in">
          <div className="grid grid-cols-2 gap-6">
            {children.map(c => (
              <NeonCard key={c.name} title={c.name} subtitle={"Grade " + c.grade} interactive accent={c.chronic ? "amber" : "green"}>
                <div className="grid grid-cols-4 gap-3 mb-4">
                  {[{ v: c.attendance + "%", l: "Attendance", c: "text-neon-green" }, { v: c.avg, l: "Avg Grade", c: "text-neon-cyan" }, { v: "0", l: "Missing", c: "text-neon-purple" }, { v: "0", l: "Alerts", c: "text-neon-amber" }].map((s, i) => (
                    <div key={i} className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border">
                      <div className={"text-lg font-bold font-mono " + s.c}>{s.v}</div>
                      <div className="text-[9px] text-gray-600">{s.l}</div>
                    </div>
                  ))}
                </div>
                <div className="flex gap-2">
                  {c.chronic ? <StatusBadge label={"Chronic: " + c.chronic} variant="amber" dot /> : <StatusBadge label="No chronic conditions" variant="green" dot />}
                </div>
              </NeonCard>
            ))}
          </div>

          <div className="grid grid-cols-3 gap-6">
            <NeonCard title="Upcoming Deadlines" subtitle="Calendar badges" accent="cyan">
              <div className="flex flex-wrap gap-2 mb-4">
                {["Math Test Jul 24", "History Essay Jul 28", "Science Project Aug 2"].map((d, i) => (
                  <div key={i} className="px-3 py-1.5 rounded-lg bg-neon-red/10 border border-neon-red/20 text-xs text-neon-red">
                    <Calendar size={12} className="inline mr-1" />{d}
                  </div>
                ))}
              </div>
              <div className="rounded-lg bg-cyber-darker p-3 border border-cyber-border">
                <div className="grid grid-cols-7 gap-1 text-center mb-2">
                  {["M", "T", "W", "T", "F", "S", "S"].map(d => <span key={d} className="text-[9px] text-gray-600 font-medium">{d}</span>)}
                </div>
                {[20, 21, 22, 23, 24, 25, 26].map((w, i) => (
                  <div key={i} className="grid grid-cols-7 gap-1 text-center mb-1">
                    {Array.from({ length: 7 }, (_, j) => {
                      const day = w + j - (i * 7);
                      if (day < 1 || day > 31) return <div key={j} />;
                      return (
                        <div key={j} className={"text-[11px] py-1 rounded " + (day === 21 ? "ring-1 ring-neon-cyan/50 " : "") + ([24, 26, 28].includes(day) ? "bg-neon-cyan/10 text-neon-cyan font-bold" : "text-gray-500")}>
                          {day}{[24, 26, 28].includes(day) && <div className="w-1 h-1 rounded-full bg-neon-cyan mx-auto mt-0.5" />}
                        </div>
                      );
                    })}
                  </div>
                ))}
              </div>
            </NeonCard>

            <NeonCard title="Alert Timeline" subtitle="Real-time notifications" accent="amber">
              <div className="space-y-3">
                {[
                  { icon: <AlertTriangle size={14} />, t: "Karabo late to 3rd period", time: "Today 09:15", c: "text-neon-amber" },
                  { icon: <CheckCircle size={14} />, t: "Lethabo submitted Math HW", time: "Yesterday 16:30", c: "text-neon-green" },
                  { icon: <Bell size={14} />, t: "Parent-Teacher meeting Tue 26 Jul", time: "2 days ago", c: "text-neon-purple" },
                  { icon: <XCircle size={14} />, t: "Karabo absent period 2", time: "3 days ago", c: "text-neon-red" },
                ].map((a, i) => (
                  <div key={i} className="flex items-start gap-3 py-2 border-b border-cyber-border/50 last:border-0">
                    <span className={"mt-0.5 " + a.c}>{a.icon}</span>
                    <div><p className="text-xs text-gray-200">{a.t}</p><p className="text-[10px] text-gray-600">{a.time}</p></div>
                  </div>
                ))}
              </div>
            </NeonCard>

            <div className="space-y-6">
              <NeonCard title="Medical Opt-In" subtitle="POPIA consent" accent="purple">
                {children.map(c => (
                  <div key={c.name} className="p-3 rounded-lg bg-cyber-darker border border-cyber-border mb-3">
                    <p className="text-xs font-medium text-gray-200 mb-2">{c.name}</p>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-[10px] text-gray-500">POPIA</span>
                      <StatusBadge label="GRANTED" variant="green" dot />
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] text-gray-500">Chronic</span>
                      {c.chronic ? <StatusBadge label={c.chronic} variant="amber" dot /> : <span className="text-[10px] text-gray-600">None</span>}
                    </div>
                  </div>
                ))}
                <NeonButton variant="purple" size="sm" className="w-full" icon={<Heart size={14} />}>Update Medical</NeonButton>
              </NeonCard>
              <NeonCard title="Billing" subtitle="R100/year per learner" accent="pink">
                <div className="flex items-center gap-3 p-3 rounded-lg bg-neon-red/5 border border-neon-red/20 mb-3">
                  <CreditCard size={20} className="text-neon-red" />
                  <div><p className="text-xs text-gray-200 font-medium">R200 outstanding</p><p className="text-[9px] text-gray-500">2 learners · Due 31 Jul</p></div>
                </div>
                <NeonButton variant="pink" size="sm" className="w-full" icon={<CreditCard size={14} />}>Pay Now — R200</NeonButton>
              </NeonCard>
            </div>
          </div>
        </div>
      </Shell>
    </div>
  );
}