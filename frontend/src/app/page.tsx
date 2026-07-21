"use client";
import Link from "next/link";
import { Shield, ChevronRight, Activity, Bell, CreditCard, Brain, Syringe, Map, Fingerprint, PenTool, Calendar, Heart, Truck, BarChart3, Award } from "lucide-react";

const features = [
  { icon: <Shield size={20}/>, title: "Multi-Tenant Security", desc: "Supabase RLS isolates every school's data" },
  { icon: <Bell size={20}/>, title: "Truancy Watchdog", desc: "3-day ABSENT triggers clinical alert" },
  { icon: <CreditCard size={20}/>, title: "PayFast Billing", desc: "R20/learner + R100/parent dual billing" },
  { icon: <Brain size={20}/>, title: "Predictive Truancy AI", desc: "ML-scan flags patterns before they escalate" },
  { icon: <Syringe size={20}/>, title: "Immunization Tracker", desc: "Vaccine schedule & compliance monitoring" },
  { icon: <Map size={20}/>, title: "Real-Time Heat Maps", desc: "Geo-spatial attendance & alert density" },
  { icon: <Fingerprint size={20}/>, title: "Biometric SSO", desc: "FIDO2 WebAuthn zero-trust auth" },
  { icon: <PenTool size={20}/>, title: "Interactive Whiteboard", desc: "Real-time collaborative canvas" },
  { icon: <Calendar size={20}/>, title: "Smart Calendar Sync", desc: "iCal/Google Calendar exam sync" },
  { icon: <Heart size={20}/>, title: "Clinic Case Mgmt", desc: "Chronic tracking & escalation workflows" },
  { icon: <Truck size={20}/>, title: "Bus Tracker", desc: "GPS bus route & geofence alerts" },
  { icon: <BarChart3 size={20}/>, title: "Power BI Export", desc: "One-click analytics export" },
  { icon: <Award size={20}/>, title: "Achievement Badges", desc: "Gamified learner milestone rewards" },
  { icon: <Activity size={20}/>, title: "POPIA Audit Trail", desc: "Full immutable audit log" },
];

export default function Home() {
  return (
    <div className="min-h-screen bg-cyber-black flex flex-col items-center justify-center p-8">
      <div className="max-w-4xl mx-auto text-center">
        <div className="inline-flex items-center gap-3 px-4 py-2 rounded-full bg-neon-cyan/5 border border-neon-cyan/20 mb-8">
          <Shield size={14} className="text-neon-cyan" />
          <span className="text-[11px] text-neon-cyan font-medium">SCHOOLNET v3.0</span>
        </div>
        <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-4">
          <span className="text-gray-100">School Health &</span>
          <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-neon-cyan via-neon-blue to-neon-purple">LMS Platform</span>
        </h1>
        <p className="text-gray-500 text-sm max-w-xl mx-auto mb-8">
          Multi-tenant school management with real-time truancy detection, health oversight,
          automated billing, and a neon-cyberpunk command center.
        </p>
        <div className="flex items-center justify-center gap-4 mb-16">
          <Link href="/superadmin" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-neon-cyan/10 text-neon-cyan border border-neon-cyan/30 text-xs font-medium hover:bg-neon-cyan/20 transition-all">
            SuperAdmin <ChevronRight size={14} />
          </Link>
          <Link href="/schooladmin" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-neon-blue/10 text-neon-blue border border-neon-blue/30 text-xs font-medium hover:bg-neon-blue/20 transition-all">
            SchoolAdmin <ChevronRight size={14} />
          </Link>
          <Link href="/teacher" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-neon-green/10 text-neon-green border border-neon-green/30 text-xs font-medium hover:bg-neon-green/20 transition-all">
            Teacher <ChevronRight size={14} />
          </Link>
          <Link href="/parent" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-neon-amber/10 text-neon-amber border border-neon-amber/30 text-xs font-medium hover:bg-neon-amber/20 transition-all">
            Parent <ChevronRight size={14} />
          </Link>
          <Link href="/clinic" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-neon-pink/10 text-neon-pink border border-neon-pink/30 text-xs font-medium hover:bg-neon-pink/20 transition-all">
            Clinic <ChevronRight size={14} />
          </Link>
        </div>

        <h2 className="text-sm font-medium text-gray-400 mb-6 uppercase tracking-widest">Full Platform Capabilities</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {features.map((f, i) => (
            <div key={i} className="flex items-start gap-3 p-3 rounded-lg bg-cyber-card border border-cyber-border">
              <span className="text-neon-cyan mt-0.5">{f.icon}</span>
              <div className="text-left">
                <p className="text-xs font-medium text-gray-200">{f.title}</p>
                <p className="text-[10px] text-gray-600">{f.desc}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 p-4 rounded-lg bg-cyber-darker border border-cyber-border">
          <p className="text-[10px] text-gray-600">
            Stack: Supabase (PostgreSQL + RLS) · Vercel (Next.js 14) · Render (Cron Workers) · Hybrid iOS/Android · SA-SAMS Ingestion
          </p>
        </div>
      </div>
    </div>
  );
}