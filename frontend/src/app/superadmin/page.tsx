"use client";
import { Shell } from "@/components/layout/Shell";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { StatCard } from "@/components/ui/StatCard";
import { useState } from "react";
import {
  Shield, Settings, Globe, Users, School, CreditCard, Bell,
  Activity, Download, Filter, Search, AlertTriangle, CheckCircle,
  Clock, DollarSign, BarChart3, Map, RefreshCw
} from "lucide-react";

const nav = [
  { label: "Dashboard", href: "/superadmin", icon: <Activity size={18} /> },
  { label: "Schools", href: "/superadmin/schools", icon: <School size={18} />, badge: "14" },
  { label: "Users", href: "/superadmin/users", icon: <Users size={18} /> },
  { label: "Billing", href: "/superadmin/billing", icon: <CreditCard size={18} />, badge: "OVERDUE" },
  { label: "Alerts", href: "/superadmin/alerts", icon: <Bell size={18} />, badge: "23" },
  { label: "Settings", href: "/superadmin/settings", icon: <Settings size={18} /> },
];

const schools = [
  { name: "Springfield High", code: "SPR001", learners: 1240, region: "Region A", alerts: 8, billing: "98%" },
  { name: "Riverside Academy", code: "RIV002", learners: 980, region: "Region B", alerts: 3, billing: "87%" },
  { name: "Hillcrest Primary", code: "HIL003", learners: 650, region: "Region A", alerts: 12, billing: "92%" },
  { name: "Sunnydale College", code: "SUN004", learners: 1500, region: "Region C", alerts: 5, billing: "95%" },
  { name: "Oceanview High", code: "OCE005", learners: 820, region: "Region B", alerts: 2, billing: "100%" },
  { name: "Green Valley", code: "GRE006", learners: 430, region: "Region A", alerts: 7, billing: "79%" },
];

const recentAlerts = [
  { id: 1, school: "Hillcrest Primary", learner: "Sipho Dlamini", days: 5, severity: "high", time: "2 hrs ago" },
  { id: 2, school: "Springfield High", learner: "Thabo Nkosi", days: 4, severity: "medium", time: "5 hrs ago" },
  { id: 3, school: "Green Valley", learner: "Zanele Khumalo", days: 7, severity: "critical", time: "1 day ago" },
  { id: 4, school: "Riverside Academy", learner: "Lerato Molefe", days: 3, severity: "medium", time: "2 days ago" },
];

export default function SuperAdmin() {
  const [search, setSearch] = useState("");
  const [selectedRegion, setSelectedRegion] = useState("ALL");
  const filtered = schools.filter(s => s.name.toLowerCase().includes(search.toLowerCase()) && (selectedRegion === "ALL" || s.region === selectedRegion));
  const totalLearners = schools.reduce((a, s) => a + s.learners, 0);

  return (
    <div className="min-h-screen bg-cyber-black">
      <Sidebar items={nav} role="SUPERADMIN" userName="System Admin" schoolName="Global Oversight" />
      <Shell>
        <TopBar
          title="SuperAdmin Command Center"
          subtitle="Multi-tenant oversight · 14 schools · 5,620 learners"
          showSearch
          actions={
            <><NeonButton variant="primary" size="sm" icon={<RefreshCw size={14} />}>Sync All</NeonButton><NeonButton variant="secondary" size="sm" icon={<Download size={14} />}>Export</NeonButton></>
          }
        />
        <div className="p-6 space-y-6 animate-fade-in">
          {/* Stats */}
          <div className="grid grid-cols-5 gap-4">
            <StatCard label="Total Schools" value="14" change="2 pending audit" changeType="neutral" accent="cyan" trend={85} />
            <StatCard label="Total Learners" value={totalLearners.toLocaleString()} change="+124 this month" changeType="increase" accent="blue" trend={72} />
            <StatCard label="Active Alerts" value="23" change="+5 vs last week" changeType="increase" accent="red" trend={68} />
            <StatCard label="Billing Rate" value="91.6%" change="R42,800 collected" changeType="increase" accent="green" trend={92} />
            <StatCard label="Truancy Rate" value="3.2%" change="-0.8% improvement" changeType="decrease" accent="amber" trend={32} />
          </div>

          {/* Map placeholder */}
          <NeonCard title="Regional Heat Map" subtitle="Alert density by region" accent="cyan">
            <div className="h-48 rounded-lg bg-cyber-darker border border-cyber-border flex items-center justify-center">
              <div className="text-center">
                <Map size={32} className="mx-auto text-gray-600 mb-2" />
                <p className="text-xs text-gray-600">Real-time geo-spatial map</p>
                <p className="text-[10px] text-gray-700">Supersedes with Leaflet/Mapbox integration</p>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3 mt-4">
              <div className="text-center p-2 rounded-lg bg-cyber-darker"><div className="text-lg font-bold text-neon-red">8</div><div className="text-[9px] text-gray-600">Region A</div></div>
              <div className="text-center p-2 rounded-lg bg-cyber-darker"><div className="text-lg font-bold text-neon-amber">5</div><div className="text-[9px] text-gray-600">Region B</div></div>
              <div className="text-center p-2 rounded-lg bg-cyber-darker"><div className="text-lg font-bold text-neon-green">3</div><div className="text-[9px] text-gray-600">Region C</div></div>
            </div>
          </NeonCard>

          {/* Schools table */}
          <NeonCard title="School Directory" subtitle="All schools · billing & alert status" accent="blue">
            <div className="flex items-center gap-3 mb-4">
              <div className="relative flex-1">
                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600" />
                <input placeholder="Search schools..." className="pl-8 pr-4 h-8 text-xs bg-cyber-dark border border-cyber-border rounded-lg w-full" value={search} onChange={e => setSearch(e.target.value)} />
              </div>
              {["ALL", "Region A", "Region B", "Region C"].map(r => (
                <button key={r} onClick={() => setSelectedRegion(r)} className={"px-3 py-1.5 rounded-full text-[10px] " + (selectedRegion === r ? "bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30" : "bg-cyber-dark text-gray-500 border border-cyber-border")}>{r}</button>
              ))}
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead><tr className="text-gray-600 uppercase tracking-wider border-b border-cyber-border">
                  <th className="text-left py-3 px-2 font-medium">School</th>
                  <th className="text-left py-3 px-2 font-medium">Code</th>
                  <th className="text-center py-3 px-2 font-medium">Learners</th>
                  <th className="text-center py-3 px-2 font-medium">Region</th>
                  <th className="text-center py-3 px-2 font-medium">Alerts</th>
                  <th className="text-center py-3 px-2 font-medium">Billing</th>
                  <th className="text-right py-3 px-2 font-medium">Actions</th>
                </tr></thead>
                <tbody>{filtered.map((s, i) => (
                  <tr key={i} className="border-b border-cyber-border/50 hover:bg-cyber-darker/50 transition-colors">
                    <td className="py-3 px-2 font-medium text-gray-200">{s.name}</td>
                    <td className="py-3 px-2 text-gray-500 font-mono">{s.code}</td>
                    <td className="py-3 px-2 text-center font-mono">{s.learners}</td>
                    <td className="py-3 px-2 text-center"><span className="px-2 py-0.5 rounded text-[9px] bg-cyber-mid text-gray-500">{s.region}</span></td>
                    <td className="py-3 px-2 text-center"><StatusBadge label={s.alerts + " active"} variant={s.alerts > 5 ? "red" : s.alerts > 2 ? "amber" : "green"} dot /></td>
                    <td className="py-3 px-2 text-center"><StatusBadge label={s.billing} variant={parseInt(s.billing) > 90 ? "green" : parseInt(s.billing) > 80 ? "amber" : "red"} /></td>
                    <td className="py-3 px-2 text-right"><NeonButton variant="primary" size="sm">Manage</NeonButton></td>
                  </tr>
                ))}</tbody>
              </table>
            </div>
          </NeonCard>

          {/* Recent alerts + quick actions */}
          <div className="grid grid-cols-2 gap-6">
            <NeonCard title="Recent Truancy Alerts" subtitle="Last 24 hours" accent="red">
              <div className="space-y-2">{recentAlerts.map((a, i) => (
                <div key={i} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-cyber-darker transition-colors">
                  <div><p className="text-xs text-gray-200">{a.learner}</p><p className="text-[10px] text-gray-600">{a.school}</p></div>
                  <div className="flex items-center gap-2"><StatusBadge label={a.days + " days"} variant={a.severity === "critical" ? "red" : "amber"} /><span className="text-[10px] text-gray-600">{a.time}</span></div>
                </div>
              ))}</div>
              <NeonButton variant="red" size="sm" className="w-full mt-3" icon={<AlertTriangle size={12} />}>View All Alerts</NeonButton>
            </NeonCard>
            <div className="space-y-6">
              <NeonCard title="Platform Health" subtitle="System status" accent="green">
                <div className="space-y-2">{[{ l: "Supabase", v: "Operational" }, { l: "Edge Functions", v: "5/5 Active" }, { l: "Cron Workers", v: "3/3 Synced" }, { l: "PayFast API", v: "Connected" }, { l: "OneSignal", v: "Push Ready" }].map((s, i) => (
                  <div key={i} className="flex items-center justify-between py-1.5"><span className="text-xs text-gray-400">{s.l}</span><StatusBadge label={s.v} variant="green" dot /></div>
                ))}</div>
              </NeonCard>
              <NeonCard title="Quick Actions" accent="purple">
                <div className="grid grid-cols-2 gap-2">{["Force Sync SA-SAMS", "Generate Monthly PDF", "Clear Alert Queue", "Run Billing Cycle"].map((a, i) => (
                  <button key={i} className="text-[10px] px-3 py-2 rounded-lg bg-cyber-dark border border-cyber-border text-gray-400 hover:text-neon-cyan hover:border-neon-cyan/30 transition-all cursor-pointer">{a}</button>
                ))}</div>
              </NeonCard>
            </div>
          </div>
        </div>
      </Shell>
    </div>
  );
}