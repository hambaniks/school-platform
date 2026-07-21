"use client";
import { Shell } from "@/components/layout/Shell";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { NeonCard } from "@/components/ui/NeonCard";
import { NeonButton } from "@/components/ui/NeonButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { StatCard } from "@/components/ui/StatCard";
import { useState } from "react";
import { Upload, Users, Bell, CreditCard, Clock, AlertTriangle, CheckCircle, Download, RefreshCw, Search, UserPlus, FileText, Activity } from "lucide-react";

const nav = [
  { label: "Dashboard", href: "/schooladmin", icon: <Activity size={18} /> },
  { label: "Learners", href: "/schooladmin/learners", icon: <Users size={18} />, badge: "1,240" },
  { label: "Attendance", href: "/schooladmin/attendance", icon: <Clock size={18} /> },
  { label: "Alerts", href: "/schooladmin/alerts", icon: <Bell size={18} />, badge: "8" },
  { label: "Billing", href: "/schooladmin/billing", icon: <CreditCard size={18} />, badge: "OVERDUE" },
  { label: "SA-SAMS", href: "/schooladmin/sa-sams", icon: <Upload size={18} /> },
];

export default function SchoolAdmin() {
  const [uploadStatus, setUploadStatus] = useState<string | null>(null);
  const handleUpload = () => {
    setUploadStatus("uploading");
    setTimeout(() => setUploadStatus("success"), 2000);
  };

  return (
    <div className="min-h-screen bg-cyber-black">
      <Sidebar items={nav} role="SCHOOLADMIN" userName="Mr. Williams" schoolName="Springfield High School" />
      <Shell>
        <TopBar title="School Administration" subtitle="Springfield High · 1,240 learners · Grade 8–12" actions={
          <><NeonButton variant="primary" size="sm" icon={<RefreshCw size={14} />}>Sync Now</NeonButton><NeonButton variant="secondary" size="sm" icon={<Download size={14} />}>Export</NeonButton></>
        } />
        <div className="p-6 space-y-6 animate-fade-in">
          <div className="grid grid-cols-4 gap-4">
            <StatCard label="Total Learners" value="1,240" change="+28 this term" changeType="increase" accent="cyan" trend={78} />
            <StatCard label="Today Attendance" value="94.2%" change="1,167 present" changeType="increase" accent="green" trend={94} />
            <StatCard label="Active Alerts" value="8" change="3 critical" changeType="increase" accent="red" trend={60} />
            <StatCard label="Billing Rate" value="87%" change="R24,800 collected" changeType="neutral" accent="amber" trend={87} />
          </div>

          <div className="grid grid-cols-3 gap-6">
            <NeonCard title="SA-SAMS Ingestion" subtitle="Import learner data (non-overwrite)" accent="blue">
              <div className="p-4 rounded-lg bg-cyber-darker border border-cyber-border border-dashed text-center mb-4">
                <Upload size={24} className="mx-auto text-gray-600 mb-2" />
                <p className="text-xs text-gray-500 mb-1">Drag & drop CSV/XML</p>
                <p className="text-[10px] text-gray-700">SA-SAMS export format</p>
              </div>
              <NeonButton variant="primary" size="sm" icon={<Upload size={14} />} className="w-full" onClick={handleUpload}>
                {uploadStatus === "uploading" ? "Uploading..." : uploadStatus === "success" ? "Uploaded ✓" : "Upload SA-SAMS File"}
              </NeonButton>
              {uploadStatus === "success" && <p className="text-[10px] text-neon-green mt-2 text-center">28 new learners imported, 0 duplicates skipped</p>}
            </NeonCard>

            <NeonCard title="Attendance Ticker" subtitle="Today · 14:00 cutoff enforced" accent="green">
              <div className="space-y-3">
                {[{ grade: "10A", present: "92%", late: "5%", absent: "3%", flag: false },
                  { grade: "10B", present: "88%", late: "7%", absent: "5%", flag: true },
                  { grade: "11A", present: "95%", late: "3%", absent: "2%", flag: false },
                  { grade: "12A", present: "78%", late: "10%", absent: "12%", flag: true }].map((g, i) => (
                  <div key={i} className="flex items-center justify-between py-1.5 border-b border-cyber-border/30 last:border-0">
                    <span className="text-xs text-gray-400 w-10">Gr {g.grade}</span>
                    <div className="flex gap-3 text-[10px]">
                      <span className="text-neon-green">{g.present}</span>
                      <span className="text-neon-amber">{g.late}</span>
                      <span className="text-neon-red">{g.absent}</span>
                    </div>
                    {g.flag && <StatusBadge label="FLAGGED" variant="red" dot size="sm" />}
                  </div>
                ))}
              </div>
              <NeonButton variant="green" size="sm" className="w-full mt-3" icon={<CheckCircle size={14} />}>Mark All Present</NeonButton>
            </NeonCard>

            <div className="space-y-6">
              <NeonCard title="Pending Alerts" subtitle="Requires attention" accent="red">
                {[{ n: "Thabo Nkosi", g: "10B", d: 4, s: "medium" }, { n: "Zanele Khumalo", g: "11A", d: 7, s: "critical" }, { n: "Bongani Zulu", g: "9C", d: 3, s: "medium" }].map((a, i) => (
                  <div key={i} className="flex items-center justify-between py-2"><span className="text-xs text-gray-200">{a.n} (Gr {a.g})</span><div className="flex items-center gap-2"><StatusBadge label={a.d + "d"} variant={a.s === "critical" ? "red" : "amber"} /><StatusBadge label={a.s} variant={a.s === "critical" ? "red" : "amber"} dot /></div></div>
                ))}
                <NeonButton variant="red" size="sm" className="w-full mt-3">View All Alerts</NeonButton>
              </NeonCard>
              <NeonCard title="Quick Links" accent="purple">
                <div className="grid grid-cols-2 gap-2">
                  {[["Add Learner", "+"], ["Billing Console", "$"], ["Class Roster", "@"], ["Reports", "#"]].map((q, i) => (
                    <button key={i} className="flex items-center gap-2 text-[10px] px-3 py-2 rounded-lg bg-cyber-dark border border-cyber-border text-gray-400 hover:text-neon-cyan transition-all cursor-pointer">
                      <span className="text-neon-cyan">{q[1]}</span>{q[0]}
                    </button>
                  ))}
                </div>
              </NeonCard>
            </div>
          </div>
        </div>
      </Shell>
    </div>
  );
}