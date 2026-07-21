"use client";
import { Shell } from "@/components/layout/Shell";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { StatCard } from "@/components/ui/StatCard";
import { useState } from "react";
import { AlertTriangle, Heart, Users, MapPin, Phone, CheckCircle, Clock, Filter, Download, Search, Syringe, FileText } from "lucide-react";

const nav = [
  { label: "Inbox", href: "/clinic", icon: <AlertTriangle size={18} />, badge: "12" },
  { label: "All Alerts", href: "/clinic/alerts", icon: <Heart size={18} /> },
  { label: "Schools", href: "/clinic/schools", icon: <Users size={18} /> },
  { label: "Immunization", href: "/clinic/immunization", icon: <Syringe size={18} />, badge: "8" },
  { label: "Tracking", href: "/clinic/tracking", icon: <MapPin size={18} /> },
  { label: "Reports", href: "/clinic/reports", icon: <Download size={18} /> },
];

const alerts = [
  { id: 1, learner: "Thabo Nkosi", school: "Springfield High", grade: "10B", chronic: "Asthma", status: "INBOUND" as const, days: 4, contact: "+27 82 555 0101", time: "2 hrs ago" },
  { id: 2, learner: "Lerato Molefe", school: "Riverside Acad.", grade: "8A", chronic: "Diabetes Type 1", status: "CONTACTED" as const, days: 3, contact: "+27 72 555 0202", time: "5 hrs ago" },
  { id: 3, learner: "Sipho Dlamini", school: "Hillcrest Primary", grade: "5C", chronic: null, status: "INBOUND" as const, days: 5, contact: "+27 62 555 0303", time: "1 day ago" },
  { id: 4, learner: "Zanele Khumalo", school: "Sunnydale College", grade: "11A", chronic: "Epilepsy", status: "ESCALATED" as const, days: 7, contact: "+27 82 555 0404", time: "2 days ago" },
  { id: 5, learner: "Bongani Zulu", school: "Springfield High", grade: "9C", chronic: null, status: "RESOLVED" as const, days: 0, contact: "+27 72 555 0505", time: "3 days ago" },
];

export default function Clinic() {
  const [filter, setFilter] = useState("ALL");
  const [search, setSearch] = useState("");
  const f = alerts.filter(a => filter === "ALL" || a.status === filter).filter(a => a.learner.toLowerCase().includes(search.toLowerCase()) || a.school.toLowerCase().includes(search.toLowerCase()));
  const inbound = alerts.filter(a => a.status === "INBOUND").length;

  return (
    <div className="min-h-screen bg-cyber-black">
      <Sidebar items={nav} role="CLINIC" userName="Sister Ndlovu" schoolName="District Health Office · Region A" />
      <Shell>
        <TopBar title="Clinic Health Portal" subtitle="District health oversight & truancy management" actions={
          <><div className="relative"><Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600" /><input placeholder="Search..." className="pl-8 w-48 h-8 text-xs bg-cyber-dark border border-cyber-border rounded-lg" value={search} onChange={e => setSearch(e.target.value)} /></div><NeonButton variant="primary" size="sm" icon={<Download size={14} />}>Export</NeonButton></>
        } />
        <div className="p-6 space-y-6 animate-fade-in">
          <div className="grid grid-cols-4 gap-4">
            <StatCard label="Inbound Alerts" value={inbound.toString()} change="+3 today" changeType="increase" accent="red" trend={78} />
            <StatCard label="Contacted" value={alerts.filter(a => a.status === "CONTACTED").length.toString()} change="Pending follow-up" changeType="neutral" accent="amber" trend={45} />
            <StatCard label="Escalated" value={alerts.filter(a => a.status === "ESCALATED").length.toString()} change="Needs review" changeType="decrease" accent="pink" trend={20} />
            <StatCard label="Resolved This Week" value="8" change="+2 vs last week" changeType="increase" accent="green" trend={72} />
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs text-gray-500 mr-2">Filter:</span>
            {[{ k: "ALL", l: "All", c: alerts.length }, { k: "INBOUND", l: "Inbound", c: inbound }, { k: "CONTACTED", l: "Contacted", c: alerts.filter(a => a.status === "CONTACTED").length }, { k: "ESCALATED", l: "Escalated", c: alerts.filter(a => a.status === "ESCALATED").length }, { k: "RESOLVED", l: "Resolved", c: alerts.filter(a => a.status === "RESOLVED").length }].map(f2 => (
              <button key={f2.k} onClick={() => setFilter(f2.k)}
                className={"px-3 py-1.5 rounded-full text-[10px] font-medium transition-all flex items-center gap-1.5 " + (filter === f2.k ? "bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30" : "bg-cyber-dark text-gray-500 border border-cyber-border hover:text-gray-300")}>
                {f2.l}<span className="w-4 h-4 rounded-full flex items-center justify-center text-[8px] bg-cyber-mid">{f2.c}</span>
              </button>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-4">
            {f.map(a => (
              <NeonCard key={a.id} accent={a.status === "INBOUND" ? "red" : a.status === "CONTACTED" ? "amber" : a.status === "ESCALATED" ? "pink" : "green"}>
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className={"w-10 h-10 rounded-full flex items-center justify-center text-xs font-bold " + (a.status === "INBOUND" ? "bg-neon-red/10 text-neon-red" : a.status === "CONTACTED" ? "bg-neon-amber/10 text-neon-amber" : a.status === "ESCALATED" ? "bg-neon-pink/10 text-neon-pink" : "bg-neon-green/10 text-neon-green")}>
                      {a.learner.split(" ").map(n => n[0]).join("")}
                    </div>
                    <div><h3 className="text-sm font-medium text-gray-100">{a.learner}</h3><p className="text-[10px] text-gray-500">{a.school} · Grade {a.grade}</p></div>
                  </div>
                  <StatusBadge label={a.status} variant={a.status === "INBOUND" ? "red" : a.status === "CONTACTED" ? "amber" : a.status === "ESCALATED" ? "pink" : "green"} dot pulsing={a.status === "INBOUND" || a.status === "ESCALATED"} />
                </div>
                <div className="grid grid-cols-2 gap-2 mb-3">
                  <div className="flex items-center gap-2 text-xs text-gray-500"><Clock size={12} />{a.days > 0 ? a.days + " consecutive absent" : "Resolved"}</div>
                  <div className="flex items-center gap-2 text-xs text-gray-500"><Phone size={12} />{a.contact}</div>
                  {a.chronic && <div className="col-span-2 flex items-center gap-2"><Heart size={12} className="text-neon-amber" /><StatusBadge label={"Chronic: " + a.chronic} variant="amber" dot /></div>}
                </div>
                <div className="flex items-center justify-between pt-2 border-t border-cyber-border">
                  <span className="text-[10px] text-gray-600">{a.time}</span>
                  <div className="flex gap-2">
                    {a.status !== "RESOLVED" ? <><NeonButton variant="amber" size="sm" icon={<Phone size={12} />}>Contact</NeonButton><NeonButton variant="green" size="sm" icon={<CheckCircle size={12} />}>Resolve</NeonButton></> : <StatusBadge label="Completed" variant="green" dot />}
                  </div>
                </div>
              </NeonCard>
            ))}
          </div>
        </div>
      </Shell>
    </div>
  );
}