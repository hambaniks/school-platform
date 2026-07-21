"use client"; import { NeonCard } from "@/components/ui/NeonCard"; import { StatusBadge } from "@/components/ui/StatusBadge";
export function SchoolMap({ schools }: { schools: {id:string;name:string;status:"ACTIVE"|"SUSPENDED"|"TRIAL";learners:number;region:string}[] }) {
  const active = schools.filter(s=>s.status==="ACTIVE").length;
  const suspended = schools.filter(s=>s.status==="SUSPENDED").length;
  const trial = schools.filter(s=>s.status==="TRIAL").length;
  return (
    <NeonCard title="School Network Map" subtitle="Live distribution of active nodes" accent="cyan">
      <div className="relative h-64 bg-cyber-darker rounded-lg border border-cyber-border overflow-hidden">
        <div className="cyber-grid-bg absolute inset-0 opacity-50" />
        <svg className="absolute inset-0 w-full h-full" viewBox="0 0 400 200">
          <line x1="80" y1="60" x2="200" y2="40" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="200" y1="40" x2="320" y2="80" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="80" y1="60" x2="120" y2="140" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="320" y1="80" x2="280" y2="160" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
          <line x1="120" y1="140" x2="280" y2="160" stroke="rgba(0,240,255,0.08)" strokeWidth="1" />
        </svg>
        {schools.slice(0,5).map((s,i)=>{
          const pos = [{x:80,y:60},{x:200,y:40},{x:320,y:80},{x:120,y:140},{x:280,y:160}][i%5];
          return (
            <div key={s.id} className="absolute transform -translate-x-1/2 -translate-y-1/2 group" style={{left:pos.x,top:pos.y}}>
              <div className={cn("w-4 h-4 rounded-full border-2", s.status==="ACTIVE"?"bg-neon-green/20 border-neon-green shadow-[0_0_12px_rgba(0,255,135,0.3)]":s.status==="SUSPENDED"?"bg-neon-red/20 border-neon-red shadow-[0_0_12px_rgba(255,51,85,0.3)]":"bg-neon-amber/20 border-neon-amber shadow-[0_0_12px_rgba(255,184,0,0.3)]")} />
              <div className="absolute left-6 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity bg-cyber-dark border border-cyber-border rounded-lg px-3 py-2 whitespace-nowrap z-10">
                <p className="text-xs font-medium text-gray-200">{s.name}</p>
                <p className="text-[10px] text-gray-500">{s.learners} learners \u00b7 {s.region}</p>
              </div>
            </div>
          );
        })}
        <div className="absolute bottom-3 left-3 flex items-center gap-4">
          <span className="w-2 h-2 rounded-full bg-neon-green shadow-[0_0_6px_rgba(0,255,135,0.5)]" /><span className="text-[10px] text-gray-500">{active} Active</span>
          <span className="w-2 h-2 rounded-full bg-neon-amber shadow-[0_0_6px_rgba(255,184,0,0.5)]" /><span className="text-[10px] text-gray-500">{trial} Trial</span>
          <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_6px_rgba(255,51,85,0.5)]" /><span className="text-[10px] text-gray-500">{suspended} Suspended</span>
        </div>
      </div>
      <div className="grid grid-cols-3 gap-4 mt-4">
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-cyan font-mono">{schools.length}</div><div className="text-[10px] text-gray-500 mt-1">Total Schools</div></div>
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-green font-mono">{schools.reduce((s,sc)=>s+sc.learners,0).toLocaleString()}</div><div className="text-[10px] text-gray-500 mt-1">Total Learners</div></div>
        <div className="text-center p-3 rounded-lg bg-cyber-darker border border-cyber-border"><div className="text-lg font-bold text-neon-amber font-mono">{Math.round(active/(schools.length||1)*100)}%</div><div className="text-[10px] text-gray-500 mt-1">Active Rate</div></div>
      </div>
    </NeonCard>
  );
}
function cn(...i:any[]){const{c}=require("@/lib/utils");return c(...i);}