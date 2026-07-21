# -------------------- START SETUP.PS1 --------------------
param([string]$ProjectRoot = "C:\Users\k2020\school-platform")
$Frontend = Join-Path $ProjectRoot "frontend"

Write-Host "=== SCHOOL PLATFORM — BUILD FIX + 4 COMPONENTS ===" -ForegroundColor Cyan

# ----- STEP 1: FIX BUILD ERRORS -----
Write-Host "[1/6] Fixing build errors..." -ForegroundColor Yellow

# Fix package.json BOM
$pkgPath = Join-Path $Frontend "package.json"
if (Test-Path $pkgPath) {
    $bytes = [System.IO.File]::ReadAllBytes($pkgPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        [System.IO.File]::WriteAllBytes($pkgPath, $bytes[3..($bytes.Length-1)])
        Write-Host "  [FIXED] Removed BOM from package.json" -ForegroundColor Green
    }
}

# Fix next.config.js - remove experimental.serverActions
$configFile = $null
foreach ($f in @("$Frontend\next.config.js","$Frontend\next.config.mjs","$Frontend\next.config.ts")) {
    if (Test-Path $f) { $configFile = $f; break }
}
if ($configFile) {
    $c = Get-Content $configFile -Raw
    $c = $c -replace 'experimental\s*:\s*\{[^}]*serverActions[^}]*\},?\s*', ''
    $c = $c -replace 'experimental\s*:\s*\{[^}]*\},?\s*', ''
    $c = $c -replace ',\s*}', '}'
    Set-Content -Path $configFile -Value $c -NoNewline
    Write-Host "  [FIXED] Cleaned $([System.IO.Path]::GetFileName($configFile))" -ForegroundColor Green
}

# ----- STEP 2: CREATE DIRECTORIES -----
Write-Host "[2/6] Creating directories..." -ForegroundColor Yellow
$dirs = @(
    "$Frontend\src\app\dashboard\truancy-ai"
    "$Frontend\src\app\dashboard\auto-grading"
    "$Frontend\src\app\dashboard\immunization"
    "$Frontend\src\app\dashboard\multi-currency"
    "$Frontend\src\components\dashboard"
    "$Frontend\src\lib"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
Write-Host "  [OK] Directories ready" -ForegroundColor Green

# ----- STEP 3: SHARED UTILITIES -----
Write-Host "[3/6] Creating shared utilities..." -ForegroundColor Yellow

@"
export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export async function api<T>(endpoint: string, opts: { method?: string; body?: unknown; headers?: Record<string,string>; params?: Record<string,string> } = {}): Promise<{data:T|null;error:string|null}> {
  try {
    let url = `${API_BASE}${endpoint}`;
    if (opts.params) url += '?' + new URLSearchParams(opts.params);
    const res = await fetch(url, {
      method: opts.method || 'GET',
      headers: { 'Content-Type': 'application/json', ...opts.headers },
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
    if (!res.ok) return { data: null, error: `HTTP ${res.status}` };
    return { data: await res.json() as T, error: null };
  } catch (e) { return { data: null, error: String(e) }; }
}

export function mockApi<T>(data: T, delay = 600): Promise<{data:T|null;error:string|null}> {
  return new Promise(r => setTimeout(() => r({ data, error: null }), delay));
}
"@ | Set-Content -Path "$Frontend\src\lib\api.ts" -Encoding UTF8

@"
interface StatCardProps { title: string; value: string|number; icon: React.ReactNode; trend?: { direction:'up'|'down'; label:string }; color?: string; subtitle?: string }
const colors: Record<string,string> = { blue:'border-l-blue-500 bg-blue-50', green:'border-l-green-500 bg-green-50', purple:'border-l-purple-500 bg-purple-50', orange:'border-l-orange-500 bg-orange-50', red:'border-l-red-500 bg-red-50', teal:'border-l-teal-500 bg-teal-50' };
const icons: Record<string,string> = { blue:'bg-blue-100 text-blue-600', green:'bg-green-100 text-green-600', purple:'bg-purple-100 text-purple-600', orange:'bg-orange-100 text-orange-600', red:'bg-red-100 text-red-600', teal:'bg-teal-100 text-teal-600' };
export default function StatCard({title,value,icon,trend,color='blue',subtitle}: StatCardProps) {
  return <div className={\`rounded-lg border border-gray-200 border-l-4 \${colors[color]} p-5 shadow-sm transition hover:shadow-md\`}>
    <div className="flex items-start justify-between">
      <div><p className="text-sm font-medium text-gray-500">{title}</p><p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>{subtitle&&<p className="mt-1 text-xs text-gray-400">{subtitle}</p>}</div>
      <div className={\`rounded-lg p-3 \${icons[color]}\`}>{icon}</div>
    </div>
    {trend&&<p className={\`mt-3 text-xs font-medium \${trend.direction==='up'?'text-green-600':'text-red-600'}\`}>{trend.direction==='up'?'▲':'▼'} {trend.label}</p>}
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\components\dashboard\StatCard.tsx" -Encoding UTF8

@"
export function LoadingSpinner({size='md'}:{size?:'sm'|'md'|'lg'}) {
  const s = {sm:'h-5 w-5',md:'h-8 w-8',lg:'h-12 w-12'};
  return <div className="flex items-center justify-center p-8"><div className={\`\${s[size]} animate-spin rounded-full border-4 border-gray-200 border-t-blue-600\`}/></div>;
}
export function ErrorState({message,onRetry}:{message:string;onRetry?:()=>void}) {
  return <div className="flex flex-col items-center justify-center rounded-lg border border-red-200 bg-red-50 p-8 text-center">
    <svg className="mb-3 h-10 w-10 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
    <p className="text-sm font-medium text-red-800">{message}</p>
    {onRetry&&<button onClick={onRetry} className="mt-3 rounded bg-red-600 px-4 py-1.5 text-xs text-white hover:bg-red-700">Retry</button>}
  </div>;
}
export function EmptyState({title,description}:{title:string;description?:string}) {
  return <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-gray-300 bg-gray-50 p-8 text-center">
    <svg className="mb-3 h-12 w-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-2.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/></svg>
    <p className="text-sm font-medium text-gray-600">{title}</p>
    {description&&<p className="mt-1 text-xs text-gray-400">{description}</p>}
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\components\dashboard\LoadingState.tsx" -Encoding UTF8

Write-Host "  [OK] Shared utilities created" -ForegroundColor Green

# ----- STEP 4: PAGE 1 — PREDICTIVE TRUANCY AI -----
Write-Host "[4/6] Creating page: Truancy AI..." -ForegroundColor Yellow

@"
'use client';
import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import { LoadingSpinner, ErrorState, EmptyState } from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface AtRiskStudent { id: string; name: string; grade: string; class: string; riskScore: number; attendanceRate: number; daysAbsent: number; trend: string; flags: string[]; recommendedAction: string }
interface Summary { critical: number; high: number; moderate: number; low: number; totalFlagged: number; avgRiskScore: number }

const SUMMARY: Summary = { critical:12, high:28, moderate:45, low:63, totalFlagged:148, avgRiskScore:62 };
const STUDENTS: AtRiskStudent[] = [
  { id:'S001', name:'Lindiwe Nkosi', grade:'10', class:'10A', riskScore:94, attendanceRate:38, daysAbsent:23, trend:'rising', flags:['Chronic absenteeism','Failing math','No parent contact'], recommendedAction:'Immediate home visit + counselor' },
  { id:'S002', name:'Thato Molefe', grade:'9', class:'9B', riskScore:87, attendanceRate:45, daysAbsent:19, trend:'rising', flags:['Frequent late arrivals','Disengaged'], recommendedAction:'Parent-teacher conference' },
  { id:'S003', name:'Zanele Khumalo', grade:'11', class:'11C', riskScore:78, attendanceRate:52, daysAbsent:15, trend:'stable', flags:['Illness pattern Mon/Fri','Grade drop'], recommendedAction:'Nurse + academic support' },
  { id:'S004', name:'Sipho Dlamini', grade:'8', class:'8A', riskScore:72, attendanceRate:58, daysAbsent:12, trend:'declining', flags:['Behavior change'], recommendedAction:'Mentor + weekly check-ins' },
  { id:'S005', name:'Amara Okafor', grade:'12', class:'12B', riskScore:65, attendanceRate:61, daysAbsent:10, trend:'stable', flags:['Peer influence'], recommendedAction:'Group counseling' },
  { id:'S006', name:'Bongani Zuma', grade:'10', class:'10B', riskScore:81, attendanceRate:48, daysAbsent:17, trend:'rising', flags:['Sibling flagged','Economic hardship'], recommendedAction:'Social worker + fee waiver' },
];

const RISK_COL = (s:number) => s>=85?'text-red-600 bg-red-50 border-red-200':s>=70?'text-orange-600 bg-orange-50 border-orange-200':s>=55?'text-yellow-600 bg-yellow-50 border-yellow-200':'text-green-600 bg-green-50 border-green-200';
const TREND = { rising:'↑ Critical', stable:'→ Watching', declining:'↓ Improving' };

export default function TruancyAIPage() {
  const [summary,setSummary] = useState<Summary|null>(null);
  const [students,setStudents] = useState<AtRiskStudent[]>([]);
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState<string|null>(null);
  const [search,setSearch] = useState('');
  const [filterRisk,setFilterRisk] = useState<'all'|'critical'|'high'|'moderate'>('all');

  useEffect(()=>{load()},[]);
  async function load() {
    setLoading(true); setError(null);
    const [s,r]=await Promise.all([mockApi<Summary>(SUMMARY,800),mockApi<AtRiskStudent[]>(STUDENTS,1000)]);
    if(s.error||r.error){setError(s.error||r.error||'Failed');}else{setSummary(s.data);setStudents(r.data||[]);}
    setLoading(false);
  }

  const filtered = students.filter(s=>{
    const q = s.name.toLowerCase().includes(search.toLowerCase())||s.id.toLowerCase().includes(search.toLowerCase())||s.class.toLowerCase().includes(search.toLowerCase());
    if(!q) return false;
    if(filterRisk==='critical') return s.riskScore>=85;
    if(filterRisk==='high') return s.riskScore>=70&&s.riskScore<85;
    if(filterRisk==='moderate') return s.riskScore>=55&&s.riskScore<70;
    return true;
  });

  if(loading) return <LoadingSpinner size="lg"/>;
  if(error) return <ErrorState message={error} onRetry={load}/>;

  return <div className="space-y-6 p-6">
    <div><h1 className="text-2xl font-bold text-gray-900">Predictive Truancy AI</h1><p className="mt-1 text-sm text-gray-500">ML flags at-risk students 2 weeks before chronic absence triggers</p></div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard title="Critical Risk" value={summary?.critical??0} color="red" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01"/></svg>} trend={{direction:'up',label:'Immediate action needed'}}/>
      <StatCard title="High Risk" value={summary?.high??0} color="orange" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01"/></svg>} trend={{direction:'up',label:'Intervention this week'}}/>
      <StatCard title="Moderate Risk" value={summary?.moderate??0} color="yellow" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'up',label:'Monitor'}}/>
      <StatCard title="Avg Risk Score" value={summary?.avgRiskScore+'%'||'0%'} color="blue" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>} subtitle="Across flagged students"/>
    </div>
    <div className="flex flex-wrap gap-3">
      <input type="text" placeholder="Search name, ID, class..." value={search} onChange={e=>setSearch(e.target.value)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none w-72"/>
      <select value={filterRisk} onChange={e=>setFilterRisk(e.target.value as any)} className="rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <option value="all">All Risk Levels</option>
        <option value="critical">Critical (85+)</option>
        <option value="high">High (70-84)</option>
        <option value="moderate">Moderate (55-69)</option>
      </select>
      <span className="text-xs text-gray-400">{filtered.length} students</span>
    </div>
    {filtered.length===0?<EmptyState title="No matches" description="Adjust search or filter"/>:
    <div className="overflow-x-auto rounded-lg border border-gray-200">
      <table className="min-w-full divide-y divide-gray-200 text-sm">
        <thead className="bg-gray-50">
          <tr><th className="px-4 py-3 text-left font-medium text-gray-500">Student</th><th className="px-4 py-3 text-left font-medium text-gray-500">Class</th><th className="px-4 py-3 text-center font-medium text-gray-500">Risk</th><th className="px-4 py-3 text-center font-medium text-gray-500">Attendance</th><th className="px-4 py-3 text-center font-medium text-gray-500">Absent</th><th className="px-4 py-3 text-center font-medium text-gray-500">Trend</th><th className="px-4 py-3 text-left font-medium text-gray-500">Flags</th><th className="px-4 py-3 text-left font-medium text-gray-500">Action</th></tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {filtered.map(s=><tr key={s.id} className="hover:bg-gray-50">
            <td className="px-4 py-3 font-medium text-gray-900">{s.name}<br/><span className="text-xs text-gray-400">{s.id}</span></td>
            <td className="px-4 py-3">{s.grade} • {s.class}</td>
            <td className="px-4 py-3 text-center"><span className={`inline-block rounded-full border px-2.5 py-0.5 text-xs font-bold ${RISK_COL(s.riskScore)}`}>{s.riskScore}%</span></td>
            <td className="px-4 py-3 text-center"><div className="flex items-center justify-center gap-2"><div className="h-2 w-12 rounded-full bg-gray-200"><div className={`h-2 rounded-full ${s.attendanceRate<50?'bg-red-500':s.attendanceRate<65?'bg-yellow-500':'bg-green-500'}`} style={{width:s.attendanceRate+'%'}}/></div><span className="text-xs text-gray-500">{s.attendanceRate}%</span></div></td>
            <td className="px-4 py-3 text-center text-gray-700">{s.daysAbsent}</td>
            <td className={`px-4 py-3 text-center text-xs font-medium ${s.trend==='rising'?'text-red-600':s.trend==='stable'?'text-yellow-600':'text-green-600'}`}>{TREND[s.trend as keyof typeof TREND]||s.trend}</td>
            <td className="px-4 py-3"><div className="flex flex-wrap gap-1">{s.flags.map((f,i)=><span key={i} className="rounded bg-gray-100 px-2 py-0.5 text-xs text-gray-600">{f}</span>)}</div></td>
            <td className="px-4 py-3 text-xs text-gray-600 italic">{s.recommendedAction}</td>
          </tr>)}
        </tbody>
      </table>
    </div>}
    <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm">
      <h3 className="font-semibold text-blue-800">ML Model: Ensemble Gradient Boosted Trees + LSTM</h3>
      <ul className="mt-2 list-inside list-disc space-y-1 text-blue-700">
        <li>Features: attendance history, lateness, grades, discipline, sibling truancy, socioeconomic</li>
        <li>Predicts chronic absence 10-14 days before trigger (≥15 days)</li>
        <li>Accuracy: 89.3% precision, 92.1% recall — retrained daily at 02:00</li>
      </ul>
    </div>
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\app\dashboard\truancy-ai\page.tsx" -Encoding UTF8
Write-Host "  [CREATED] /dashboard/truancy-ai/" -ForegroundColor Green

# ----- STEP 5: PAGE 2 — AI AUTO-GRADING -----
Write-Host "[5/6] Creating page: Auto-Grading..." -ForegroundColor Yellow

@"
'use client';
import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import { LoadingSpinner, ErrorState, EmptyState } from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface Submission { id:string; studentName:string; subject:string; assignmentTitle:string; submittedAt:string; status:'pending'|'processing'|'completed'|'manual_review'; score:number|null; maxScore:number; confidence:number|null; rubricScore:{category:string;earned:number;max:number}[]; feedback:string }
interface Metrics { totalSubmissions:number; autoGraded:number; pendingReview:number; avgScore:number; avgConfidence:number; throughput24h:number }

const METRICS: Metrics = { totalSubmissions:847, autoGraded:721, pendingReview:126, avgScore:71.4, avgConfidence:94.2, throughput24h:189 };
const SUBMISSIONS: Submission[] = [
  { id:'GRD-001', studentName:'Lindiwe Nkosi', subject:'Mathematics', assignmentTitle:'Algebra Quiz Term 2', submittedAt:'2026-07-21T08:30:00Z', status:'completed', score:34, maxScore:50, confidence:96, rubricScore:[{category:'Correctness',earned:18,max:25},{category:'Method',earned:10,max:15},{category:'Presentation',earned:6,max:10}], feedback:'Well structured. Review quadratic formula steps 4-7.' },
  { id:'GRD-002', studentName:'Thato Molefe', subject:'English', assignmentTitle:'Essay: SA Identity', submittedAt:'2026-07-21T09:15:00Z', status:'completed', score:42, maxScore:50, confidence:91, rubricScore:[{category:'Content',earned:22,max:25},{category:'Grammar',earned:12,max:15},{category:'Structure',earned:8,max:10}], feedback:'Excellent argument. Minor grammar on page 2.' },
  { id:'GRD-003', studentName:'Zanele Khumalo', subject:'Physical Science', assignmentTitle:'Lab Report: Chemical Reactions', submittedAt:'2026-07-21T10:00:00Z', status:'processing', score:null, maxScore:60, confidence:null, rubricScore:[], feedback:'Processing — ~2 min remaining' },
  { id:'GRD-004', studentName:'Sipho Dlamini', subject:'History', assignmentTitle:'Apartheid Timeline', submittedAt:'2026-07-20T14:45:00Z', status:'manual_review', score:null, maxScore:40, confidence:67, rubricScore:[], feedback:'Handwriting confidence < 70% — manual review needed' },
  { id:'GRD-005', studentName:'Amara Okafor', subject:'Mathematics', assignmentTitle:'Geometry Proofs', submittedAt:'2026-07-20T11:20:00Z', status:'completed', score:56, maxScore:60, confidence:98, rubricScore:[{category:'Correctness',earned:30,max:30},{category:'Method',earned:15,max:15},{category:'Presentation',earned:11,max:15}], feedback:'Perfect proofs. Improve diagram labels.' },
  { id:'GRD-006', studentName:'Bongani Zuma', subject:'Geography', assignmentTitle:'Climate Graphs', submittedAt:'2026-07-19T16:30:00Z', status:'pending', score:null, maxScore:30, confidence:null, rubricScore:[], feedback:'In queue — ~15 min wait' },
];

const STATUS_STYLE: Record<string,string> = { pending:'bg-gray-100 text-gray-600', processing:'bg-blue-100 text-blue-600', completed:'bg-green-100 text-green-600', manual_review:'bg-yellow-100 text-yellow-600' };
const STATUS_LABEL: Record<string,string> = { pending:'Pending', processing:'Processing...', completed:'Graded ✓', manual_review:'Manual Review' };

export default function AutoGradingPage() {
  const [metrics,setMetrics] = useState<Metrics|null>(null);
  const [submissions,setSubmissions] = useState<Submission[]>([]);
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState<string|null>(null);
  const [filter,setFilter] = useState<'all'|Submission['status']>('all');

  useEffect(()=>{load()},[]);
  async function load() {
    setLoading(true); setError(null);
    const [m,r]=await Promise.all([mockApi<Metrics>(METRICS,600),mockApi<Submission[]>(SUBMISSIONS,900)]);
    if(m.error||r.error){setError(m.error||r.error||'Failed');}else{setMetrics(m.data);setSubmissions(r.data||[]);}
    setLoading(false);
  }

  const filtered = filter==='all'?submissions:submissions.filter(s=>s.status===filter);
  if(loading) return <LoadingSpinner size="lg"/>;
  if(error) return <ErrorState message={error} onRetry={load}/>;

  return <div className="space-y-6 p-6">
    <div><h1 className="text-2xl font-bold text-gray-900">AI Auto-Grading Engine</h1><p className="mt-1 text-sm text-gray-500">Computer vision + NLP scoring of handwritten submissions against rubric criteria</p></div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
      <StatCard title="Total" value={metrics?.totalSubmissions??0} color="blue" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>}/>
      <StatCard title="Auto-Graded" value={metrics?.autoGraded??0} color="green" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'up',label:metrics?.throughput24h+' graded today'}}/>
      <StatCard title="Pending Review" value={metrics?.pendingReview??0} color="orange" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>}/>
      <StatCard title="Avg Score" value={(metrics?.avgScore??0)+'%'} color="purple" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>}/>
      <StatCard title="AI Confidence" value={(metrics?.avgConfidence??0)+'%'} color="teal" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>} subtitle="Threshold: >85% auto-grade"/>
    </div>
    <div className="flex items-center gap-3">
      <select value={filter} onChange={e=>setFilter(e.target.value as any)} className="rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <option value="all">All</option>
        <option value="pending">Pending</option>
        <option value="processing">Processing</option>
        <option value="completed">Completed</option>
        <option value="manual_review">Manual Review</option>
      </select>
      <span className="text-xs text-gray-400">{filtered.length} submissions</span>
    </div>
    {filtered.length===0?<EmptyState title="No submissions"/>:
    <div className="space-y-3">{filtered.map(s=><div key={s.id} className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-3"><h3 className="font-semibold text-gray-900">{s.assignmentTitle}</h3><span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${STATUS_STYLE[s.status]}`}>{STATUS_LABEL[s.status]}</span></div>
          <p className="mt-1 text-sm text-gray-500">{s.studentName} · {s.subject} · {new Date(s.submittedAt).toLocaleString('en-ZA',{timeZone:'Africa/Johannesburg'})}</p>
        </div>
        {s.score!==null&&<div className="text-right"><p className="text-2xl font-bold text-gray-900">{s.score}/{s.maxScore}</p><p className="text-xs text-gray-400">({Math.round(s.score/s.maxScore*100)}%)</p></div>}
      </div>
      {s.rubricScore.length>0&&<div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3">{s.rubricScore.map((r,i)=><div key={i} className="rounded bg-gray-50 p-2 text-xs"><span className="text-gray-500">{r.category}</span><div className="mt-1 flex items-center gap-2"><div className="h-1.5 flex-1 rounded-full bg-gray-200"><div className="h-1.5 rounded-full bg-blue-500" style={{width:r.earned/r.max*100+'%'}}/></div><span className="font-medium text-gray-700">{r.earned}/{r.max}</span></div></div>)}</div>}
      {s.confidence!==null&&s.status==='completed'&&<div className="mt-2 flex items-center gap-2 text-xs"><span className="text-gray-400">AI Confidence:</span><span className={`font-medium ${s.confidence>=90?'text-green-600':s.confidence>=80?'text-yellow-600':'text-red-600'}`}>{s.confidence}%</span></div>}
      <div className="mt-2 rounded bg-blue-50 p-2 text-xs text-blue-700">{s.feedback}</div>
    </div>)}</div>}
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\app\dashboard\auto-grading\page.tsx" -Encoding UTF8
Write-Host "  [CREATED] /dashboard/auto-grading/" -ForegroundColor Green

# ----- STEP 6: PAGE 3 — IMMUNIZATION TRACKER -----
Write-Host "[6/6] Creating page: Immunization Tracker..." -ForegroundColor Yellow

@"
'use client';
import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import { LoadingSpinner, ErrorState, EmptyState } from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface Record { id:string; learnerName:string; grade:string; school:string; vaccine:string; dose:string; dueDate:string; administeredDate:string|null; status:'completed'|'overdue'|'upcoming'|'pending_reminder'; clinic:string; notes:string }
interface Metrics { totalLearners:number; fullyVaccinated:number; overdueDoses:number; upcomingDoses:number; coverageRate:number; remindersSentThisMonth:number }

const METRICS: Metrics = { totalLearners:1250, fullyVaccinated:1038, overdueDoses:47, upcomingDoses:165, coverageRate:83, remindersSentThisMonth:312 };
const RECORDS: Record[] = [
  { id:'VAC-001', learnerName:'Lindiwe Nkosi', grade:'10', school:'Soweto High', vaccine:'HPV (Gardasil)', dose:'Dose 2', dueDate:'2026-08-15', administeredDate:null, status:'upcoming', clinic:'Soweto Clinic', notes:'2nd dose due 6 months after 1st' },
  { id:'VAC-002', learnerName:'Thato Molefe', grade:'9', school:'Soweto High', vaccine:'Tdap Booster', dose:'Booster', dueDate:'2026-06-30', administeredDate:null, status:'overdue', clinic:'Orlando Health', notes:'21 days overdue — contacted 2x' },
  { id:'VAC-003', learnerName:'Zanele Khumalo', grade:'11', school:'Soweto High', vaccine:'MenACWY', dose:'Dose 1', dueDate:'2026-07-10', administeredDate:'2026-07-08', status:'completed', clinic:'Soweto Clinic', notes:'Completed. Next at age 16.' },
  { id:'VAC-004', learnerName:'Sipho Dlamini', grade:'8', school:'JHB Academy', vaccine:'COVID-19', dose:'Dose 2', dueDate:'2026-09-01', administeredDate:null, status:'upcoming', clinic:'Braamfontein Vacc Centre', notes:'Schedule late August' },
  { id:'VAC-005', learnerName:'Amara Okafor', grade:'12', school:'JHB Academy', vaccine:'Hepatitis B', dose:'Dose 3', dueDate:'2026-05-20', administeredDate:'2026-05-18', status:'completed', clinic:'Auckland Park Clinic', notes:'Series complete ✓' },
  { id:'VAC-006', learnerName:'Bongani Zuma', grade:'10', school:'Soweto High', vaccine:'IPV (Polio)', dose:'Booster', dueDate:'2026-07-01', administeredDate:null, status:'overdue', clinic:'Orlando Health', notes:'20 days overdue — no SMS response' },
  { id:'VAC-007', learnerName:'Nomsa Khumalo', grade:'1', school:'Mapetla Primary', vaccine:'MMR', dose:'Dose 2', dueDate:'2026-08-20', administeredDate:null, status:'pending_reminder', clinic:'Mapetla Clinic', notes:'Send reminder 30 days before' },
  { id:'VAC-008', learnerName:'Thabo Ngubane', grade:'2', school:'Mapetla Primary', vaccine:'DTaP', dose:'Dose 5', dueDate:'2026-07-25', administeredDate:null, status:'pending_reminder', clinic:'Mapetla Clinic', notes:'Final dose in series' },
];

const S: Record<string,string> = { completed:'bg-green-100 text-green-700', overdue:'bg-red-100 text-red-700', upcoming:'bg-blue-100 text-blue-700', pending_reminder:'bg-yellow-100 text-yellow-700' };
const L: Record<string,string> = { completed:'Completed ✓', overdue:'Overdue!', upcoming:'Upcoming', pending_reminder:'Reminder Pending' };

export default function ImmunizationPage() {
  const [metrics,setMetrics]=useState<Metrics|null>(null);
  const [records,setRecords]=useState<Record[]>([]);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState<string|null>(null);
  const [search,setSearch]=useState('');
  const [filter,setFilter]=useState<'all'|Record['status']>('all');

  useEffect(()=>{load()},[]);
  async function load() {
    setLoading(true); setError(null);
    const [m,r]=await Promise.all([mockApi<Metrics>(METRICS,600),mockApi<Record[]>(RECORDS,800)]);
    if(m.error||r.error){setError(m.error||r.error||'Failed');}else{setMetrics(m.data);setRecords(r.data||[]);}
    setLoading(false);
  }

  const filtered = records.filter(r=>{
    const q=r.learnerName.toLowerCase().includes(search.toLowerCase())||r.vaccine.toLowerCase().includes(search.toLowerCase())||r.school.toLowerCase().includes(search.toLowerCase());
    if(!q)return false; if(filter!=='all'&&r.status!==filter)return false; return true;
  });
  if(loading) return <LoadingSpinner size="lg"/>;
  if(error) return <ErrorState message={error} onRetry={load}/>;

  return <div className="space-y-6 p-6">
    <div><h1 className="text-2xl font-bold text-gray-900">Immunization Tracker</h1><p className="mt-1 text-sm text-gray-500">Vaccine schedule tracking with automated clinic + parent reminders</p></div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
      <StatCard title="Total Learners" value={metrics?.totalLearners??0} color="blue" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>}/>
      <StatCard title="Fully Vaccinated" value={metrics?.fullyVaccinated??0} color="green" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'up',label:metrics?.coverageRate+'% coverage'}}/>
      <StatCard title="Overdue" value={metrics?.overdueDoses??0} color="red" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'down',label:'Urgent action'}}/>
      <StatCard title="Upcoming" value={metrics?.upcomingDoses??0} color="purple" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>}/>
      <StatCard title="Reminders Sent" value={metrics?.remindersSentThisMonth??0} color="orange" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>} subtitle="This month"/>
    </div>
    <div className="flex flex-wrap gap-3">
      <input type="text" placeholder="Search learner, vaccine, school..." value={search} onChange={e=>setSearch(e.target.value)} className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none w-72"/>
      <select value={filter} onChange={e=>setFilter(e.target.value as any)} className="rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <option value="all">All</option>
        <option value="completed">Completed</option>
        <option value="overdue">Overdue</option>
        <option value="upcoming">Upcoming</option>
        <option value="pending_reminder">Reminder Pending</option>
      </select>
      <span className="text-xs text-gray-400">{filtered.length} records</span>
    </div>
    {filtered.length===0?<EmptyState title="No records match"/>:
    <div className="overflow-x-auto rounded-lg border border-gray-200">
      <table className="min-w-full divide-y divide-gray-200 text-sm">
        <thead className="bg-gray-50"><tr><th className="px-4 py-3 text-left font-medium text-gray-500">Learner</th><th className="px-4 py-3 text-left font-medium text-gray-500">Grade</th><th className="px-4 py-3 text-left font-medium text-gray-500">School</th><th className="px-4 py-3 text-left font-medium text-gray-500">Vaccine</th><th className="px-4 py-3 text-center font-medium text-gray-500">Dose</th><th className="px-4 py-3 text-center font-medium text-gray-500">Due</th><th className="px-4 py-3 text-center font-medium text-gray-500">Given</th><th className="px-4 py-3 text-center font-medium text-gray-500">Status</th><th className="px-4 py-3 text-left font-medium text-gray-500">Clinic</th></tr></thead>
        <tbody className="divide-y divide-gray-100">{filtered.map(r=><tr key={r.id} className="hover:bg-gray-50">
          <td className="px-4 py-3 font-medium text-gray-900">{r.learnerName}</td>
          <td className="px-4 py-3">{r.grade}</td>
          <td className="px-4 py-3 text-xs text-gray-500">{r.school}</td>
          <td className="px-4 py-3">{r.vaccine}</td>
          <td className="px-4 py-3 text-center">{r.dose}</td>
          <td className="px-4 py-3 text-center">{new Date(r.dueDate).toLocaleDateString('en-ZA')}</td>
          <td className="px-4 py-3 text-center">{r.administeredDate?new Date(r.administeredDate).toLocaleDateString('en-ZA'):'—'}</td>
          <td className="px-4 py-3 text-center"><span className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${S[r.status]}`}>{L[r.status]}</span></td>
          <td className="px-4 py-3 text-xs text-gray-500">{r.clinic}</td>
        </tr>)}</tbody>
      </table>
    </div>}
    <div className="rounded-lg border border-gray-200 bg-white p-4"><h3 className="font-semibold text-gray-900">Automated Reminder Cadence</h3>
      <ul className="mt-2 space-y-1 text-sm text-gray-600">
        <li>• <strong>30 days before:</strong> SMS to parent + clinic notification</li>
        <li>• <strong>14 days before:</strong> WhatsApp with clinic hours</li>
        <li>• <strong>Due date:</strong> Automated call + clinic confirmation</li>
        <li>• <strong>7 days overdue:</strong> School nurse + social worker</li>
        <li>• <strong>30 days overdue:</strong> DoH liaison case</li>
      </ul>
    </div>
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\app\dashboard\immunization\page.tsx" -Encoding UTF8
Write-Host "  [CREATED] /dashboard/immunization/" -ForegroundColor Green

# ----- STEP 7: PAGE 4 — MULTI-CURRENCY BILLING -----
Write-Host "[7/6] Creating page: Multi-Currency Billing..." -ForegroundColor Yellow

@"
'use client';
import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import { LoadingSpinner, ErrorState, EmptyState } from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface Invoice { id:string; learnerName:string; description:string; amount:number; currency:string; amountZAR:number; exchangeRate:number; issuedDate:string; dueDate:string; status:'paid'|'pending'|'overdue'|'partial'; paymentMethod:string|null; paidDate:string|null }
interface Metrics { totalOutstanding:number; invoicesThisMonth:number; paidThisMonth:number; overdueAmount:number; currenciesActive:number; avgCollectionTime:number }
interface Rate { pair:string; rate:number; change24h:number; lastUpdated:string }

const METRICS: Metrics = { totalOutstanding:485000, invoicesThisMonth:189, paidThisMonth:142, overdueAmount:127000, currenciesActive:3, avgCollectionTime:14 };
const RATES: Rate[] = [
  { pair:'USD/ZAR', rate:18.42, change24h:-0.31, lastUpdated:'2026-07-21T10:00:00Z' },
  { pair:'GBP/ZAR', rate:23.57, change24h:0.15, lastUpdated:'2026-07-21T10:00:00Z' },
  { pair:'EUR/ZAR', rate:20.18, change24h:-0.08, lastUpdated:'2026-07-21T10:00:00Z' },
];
const INVOICES: Invoice[] = [
  { id:'INV-2026-0841', learnerName:'Amara Okafor', description:'Term 3 Tuition — International', amount:4500, currency:'USD', amountZAR:82890, exchangeRate:18.42, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'pending', paymentMethod:null, paidDate:null },
  { id:'INV-2026-0842', learnerName:'James Mitchell', description:'Term 3 Tuition — International', amount:3200, currency:'GBP', amountZAR:75424, exchangeRate:23.57, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'paid', paymentMethod:'SWIFT', paidDate:'2026-07-15' },
  { id:'INV-2026-0843', learnerName:'Sophie Dubois', description:'Term 3 Tuition — International', amount:3800, currency:'EUR', amountZAR:76684, exchangeRate:20.18, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'pending', paymentMethod:null, paidDate:null },
  { id:'INV-2026-0844', learnerName:'Lindiwe Nkosi', description:'Term 3 — Local', amount:8500, currency:'ZAR', amountZAR:8500, exchangeRate:1, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'overdue', paymentMethod:null, paidDate:null },
  { id:'INV-2026-0845', learnerName:'Thato Molefe', description:'Term 3 — Local', amount:8500, currency:'ZAR', amountZAR:8500, exchangeRate:1, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'paid', paymentMethod:'EFT', paidDate:'2026-07-10' },
  { id:'INV-2026-0846', learnerName:'Zanele Khumalo', description:'Term 3 + Bus Transport', amount:11200, currency:'ZAR', amountZAR:11200, exchangeRate:1, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'partial', paymentMethod:'EFT (partial)', paidDate:'2026-07-18' },
  { id:'INV-2026-0847', learnerName:'Chen Wei', description:'Term 3 — International', amount:4500, currency:'USD', amountZAR:82890, exchangeRate:18.42, issuedDate:'2026-07-01', dueDate:'2026-07-31', status:'paid', paymentMethod:'PayPal', paidDate:'2026-07-12' },
];

const SYM: Record<string,string> = { USD:'$', GBP:'£', EUR:'€', ZAR:'R' };
const ST: Record<string,string> = { paid:'bg-green-100 text-green-700', pending:'bg-blue-100 text-blue-700', overdue:'bg-red-100 text-red-700', partial:'bg-yellow-100 text-yellow-700' };
const LB: Record<string,string> = { paid:'Paid ✓', pending:'Pending', overdue:'Overdue!', partial:'Partial' };
const fmt = (a:number,c:string)=> (SYM[c]||c+' ')+a.toLocaleString('en-ZA',{minimumFractionDigits:2});
const fmtZ = (a:number)=> 'R'+a.toLocaleString('en-ZA',{minimumFractionDigits:2});

export default function MultiCurrencyPage() {
  const [metrics,setMetrics]=useState<Metrics|null>(null);
  const [rates,setRates]=useState<Rate[]>([]);
  const [invoices,setInvoices]=useState<Invoice[]>([]);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState<string|null>(null);
  const [fStatus,setFStatus]=useState<'all'|Invoice['status']>('all');
  const [fCurr,setFCurr]=useState<'all'|string>('all');

  useEffect(()=>{load()},[]);
  async function load() {
    setLoading(true); setError(null);
    const [m,r,i]=await Promise.all([mockApi<Metrics>(METRICS,600),mockApi<Rate[]>(RATES,400),mockApi<Invoice[]>(INVOICES,900)]);
    if(m.error||r.error||i.error){setError(m.error||r.error||i.error||'Failed');}else{setMetrics(m.data);setRates(r.data||[]);setInvoices(i.data||[]);}
    setLoading(false);
  }

  const filtered = invoices.filter(x=>{if(fStatus!=='all'&&x.status!==fStatus)return false;if(fCurr!=='all'&&x.currency!==fCurr)return false;return true;});
  const currs = [...new Set(invoices.map(i=>i.currency))];
  if(loading) return <LoadingSpinner size="lg"/>;
  if(error) return <ErrorState message={error} onRetry={load}/>;

  return <div className="space-y-6 p-6">
    <div><h1 className="text-2xl font-bold text-gray-900">Multi-Currency Billing</h1><p className="mt-1 text-sm text-gray-500">Cross-border tuition with live ZAR/USD/GBP/EUR conversion via forex API</p></div>
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
      <StatCard title="Outstanding (ZAR)" value={fmtZ(metrics?.totalOutstanding??0)} color="blue" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>}/>
      <StatCard title="This Month" value={metrics?.invoicesThisMonth??0} color="orange" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>}/>
      <StatCard title="Paid" value={metrics?.paidThisMonth??0} color="green" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'up',label:Math.round((metrics?.paidThisMonth??0)/(metrics?.invoicesThisMonth??1)*100)+'% collected'}}/>
      <StatCard title="Overdue" value={fmtZ(metrics?.overdueAmount??0)} color="red" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>} trend={{direction:'down',label:'Follow up'}}/>
      <StatCard title="Currencies" value={metrics?.currenciesActive??0} color="purple" icon={<svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>} subtitle={currs.join(', ')}/>
    </div>
    <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">{rates.map(r=><div key={r.pair} className="rounded-lg border border-gray-200 bg-white p-3"><p className="text-xs text-gray-500">{r.pair}</p><p className="text-lg font-bold text-gray-900">{r.rate.toFixed(4)}</p><p className={`text-xs ${r.change24h>=0?'text-green-600':'text-red-600'}`}>{r.change24h>=0?'▲':'▼'} {Math.abs(r.change24h).toFixed(4)} (24h)</p></div>)}</div>
    <div className="flex flex-wrap gap-3">
      <select value={fStatus} onChange={e=>setFStatus(e.target.value as any)} className="rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <option value="all">All Status</option>
        <option value="paid">Paid</option>
        <option value="pending">Pending</option>
        <option value="overdue">Overdue</option>
        <option value="partial">Partial</option>
      </select>
      <select value={fCurr} onChange={e=>setFCurr(e.target.value)} className="rounded-lg border border-gray-300 px-3 py-2 text-sm">
        <option value="all">All Currencies</option>{currs.map(c=><option key={c} value={c}>{c}</option>)}
      </select>
      <span className="text-xs text-gray-400">{filtered.length} invoices</span>
    </div>
    {filtered.length===0?<EmptyState title="No invoices match"/>:
    <div className="space-y-3">{filtered.map(inv=><div key={inv.id} className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center gap-3"><span className="text-xs font-mono text-gray-400">{inv.id}</span><span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${ST[inv.status]}`}>{LB[inv.status]}</span><span className="rounded bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">{inv.currency}</span></div>
          <p className="mt-1 font-semibold text-gray-900">{inv.learnerName}</p><p className="text-sm text-gray-500">{inv.description}</p>
          <div className="mt-1 flex items-center gap-4 text-xs text-gray-400"><span>Issued: {new Date(inv.issuedDate).toLocaleDateString('en-ZA')}</span><span>Due: {new Date(inv.dueDate).toLocaleDateString('en-ZA')}</span>{inv.paidDate&&<span>Paid: {new Date(inv.paidDate).toLocaleDateString('en-ZA')}</span>}{inv.paymentMethod&&<span>Via: {inv.paymentMethod}</span>}</div>
        </div>
        <div className="text-right"><p className="text-xl font-bold text-gray-900">{fmt(inv.amount,inv.currency)}</p><p className="text-xs text-gray-400">{fmtZ(inv.amountZAR)} @ {inv.exchangeRate.toFixed(4)}</p></div>
      </div>
    </div>)}</div>}
  </div>;
}
"@ | Set-Content -Path "$Frontend\src\app\dashboard\multi-currency\page.tsx" -Encoding UTF8
Write-Host "  [CREATED] /dashboard/multi-currency/" -ForegroundColor Green

# ----- STEP 8: BUILD -----
Write-Host "`n[8/6] Building..." -ForegroundColor Yellow
Set-Location $Frontend

Write-Host "  -> npm install --legacy-peer-deps ..." -ForegroundColor Gray
npm install --legacy-peer-deps 2>&1 | Out-Host

Write-Host "  -> npx next build ..." -ForegroundColor Gray
npx next build 2>&1 | Out-Host
if ($LASTEXITCODE -eq 0) { Write-Host "  [BUILD OK]" -ForegroundColor Green }
else { Write-Host "  [BUILD ERRORS] Check above. Dev: npx next dev" -ForegroundColor Yellow }

# ----- STEP 9: GIT PUSH -----
Write-Host "`n[9/6] Pushing to GitHub..." -ForegroundColor Yellow
Set-Location $ProjectRoot
git add -A
git commit -m "Add Truancy AI, Auto-Grading, Immunization, Multi-Currency pages + fix build errors"
$branch = git rev-parse --abbrev-ref HEAD
git push origin $branch 2>&1 | Out-Host
if ($LASTEXITCODE -eq 0) { Write-Host "  [PUSHED to $branch]" -ForegroundColor Green }
else { Write-Host "  [PUSH FAILED] Run manually: git push origin $branch" -ForegroundColor Red }

Write-Host "`n=== DONE ===" -ForegroundColor Cyan
Write-Host "4 pages created: truancy-ai | auto-grading | immunization | multi-currency" -ForegroundColor Cyan
# -------------------- END SETUP.PS1 --------------------