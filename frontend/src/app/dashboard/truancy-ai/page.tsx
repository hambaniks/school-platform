'use client';

import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import {
  LoadingSpinner,
  ErrorState,
  EmptyState,
} from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface AtRiskStudent {
  id: string;
  name: string;
  grade: string;
  class: string;
  riskScore: number;
  attendanceRate: number;
  daysAbsent: number;
  trend: 'rising' | 'stable' | 'declining';
  flags: string[];
  recommendedAction: string;
}

interface Summary {
  critical: number;
  high: number;
  moderate: number;
  low: number;
  totalFlagged: number;
  avgRiskScore: number;
}

const SUMMARY: Summary = {
  critical: 12,
  high: 28,
  moderate: 45,
  low: 63,
  totalFlagged: 148,
  avgRiskScore: 62,
};

const STUDENTS: AtRiskStudent[] = [
  {
    id: 'S001',
    name: 'Lindiwe Nkosi',
    grade: '10',
    class: '10A',
    riskScore: 94,
    attendanceRate: 38,
    daysAbsent: 23,
    trend: 'rising',
    flags: ['Chronic absenteeism', 'Failing math', 'No parent contact'],
    recommendedAction: 'Immediate home visit + counselor referral',
  },
  {
    id: 'S002',
    name: 'Thato Molefe',
    grade: '9',
    class: '9B',
    riskScore: 87,
    attendanceRate: 45,
    daysAbsent: 19,
    trend: 'rising',
    flags: ['Frequent late arrivals', 'Disengaged in class'],
    recommendedAction: 'Parent-teacher conference this week',
  },
  {
    id: 'S003',
    name: 'Zanele Khumalo',
    grade: '11',
    class: '11C',
    riskScore: 78,
    attendanceRate: 52,
    daysAbsent: 15,
    trend: 'stable',
    flags: ['Illness pattern (Mon/Fri)', 'Drop in grades'],
    recommendedAction: 'School nurse assessment + academic support',
  },
  {
    id: 'S004',
    name: 'Sipho Dlamini',
    grade: '8',
    class: '8A',
    riskScore: 72,
    attendanceRate: 58,
    daysAbsent: 12,
    trend: 'declining',
    flags: ['Recent change in behavior'],
    recommendedAction: 'Mentor assignment + weekly check-ins',
  },
  {
    id: 'S005',
    name: 'Amara Okafor',
    grade: '12',
    class: '12B',
    riskScore: 65,
    attendanceRate: 61,
    daysAbsent: 10,
    trend: 'stable',
    flags: ['Peer influence concerns'],
    recommendedAction: 'Group counseling session',
  },
  {
    id: 'S006',
    name: 'Bongani Zuma',
    grade: '10',
    class: '10B',
    riskScore: 81,
    attendanceRate: 48,
    daysAbsent: 17,
    trend: 'rising',
    flags: ['Sibling also flagged', 'Economic hardship'],
    recommendedAction: 'Social worker referral + fee waiver assessment',
  },
];

function riskColor(score: number): string {
  if (score >= 85) return 'text-red-600 bg-red-50 border-red-200';
  if (score >= 70) return 'text-orange-600 bg-orange-50 border-orange-200';
  if (score >= 55) return 'text-yellow-600 bg-yellow-50 border-yellow-200';
  return 'text-green-600 bg-green-50 border-green-200';
}

const TREND_MAP: Record<string, string> = {
  rising: '\u2191 Critical',
  stable: '\u2192 Watching',
  declining: '\u2193 Improving',
};

export default function TruancyAIPage() {
  const [summary, setSummary] = useState<Summary | null>(null);
  const [students, setStudents] = useState<AtRiskStudent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [riskFilter, setRiskFilter] = useState<
    'all' | 'critical' | 'high' | 'moderate'
  >('all');

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError(null);
    const [s, r] = await Promise.all([
      mockApi<Summary>(SUMMARY, 800),
      mockApi<AtRiskStudent[]>(STUDENTS, 1000),
    ]);
    if (s.error || r.error) {
      setError(s.error || r.error || 'Failed to load data');
    } else {
      setSummary(s.data);
      setStudents(r.data || []);
    }
    setLoading(false);
  }

  const filtered = students.filter((s) => {
    const matchSearch =
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.id.toLowerCase().includes(search.toLowerCase()) ||
      s.class.toLowerCase().includes(search.toLowerCase());
    if (!matchSearch) return false;
    if (riskFilter === 'critical') return s.riskScore >= 85;
    if (riskFilter === 'high') return s.riskScore >= 70 && s.riskScore < 85;
    if (riskFilter === 'moderate') return s.riskScore >= 55 && s.riskScore < 70;
    return true;
  });

  if (loading) return <LoadingSpinner size="lg" />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Predictive Truancy AI
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          ML-powered early warning &mdash; flags at-risk students 2 weeks
          before chronic absence triggers
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Critical Risk"
          value={summary?.critical ?? 0}
          color="red"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01" />
            </svg>
          }
          trend={{ direction: 'up', label: 'Immediate action needed' }}
        />
        <StatCard
          title="High Risk"
          value={summary?.high ?? 0}
          color="orange"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01" />
            </svg>
          }
          trend={{ direction: 'up', label: 'Intervention this week' }}
        />
        <StatCard
          title="Moderate Risk"
          value={summary?.moderate ?? 0}
          color="yellow"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{ direction: 'up', label: 'Monitoring recommended' }}
        />
        <StatCard
          title="Avg Risk Score"
          value={(summary?.avgRiskScore ?? 0) + '%'}
          color="blue"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          }
          subtitle="Across all flagged students"
        />
      </div>

      <div className="flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Search name, ID, or class..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none w-72"
        />
        <select
          value={riskFilter}
          onChange={(e) => setRiskFilter(e.target.value as typeof riskFilter)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="all">All Risk Levels</option>
          <option value="critical">Critical (85+)</option>
          <option value="high">High (70-84)</option>
          <option value="moderate">Moderate (55-69)</option>
        </select>
        <span className="text-xs text-gray-400">{filtered.length} students</span>
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          title="No students match your filters"
          description="Try adjusting the search or filter criteria"
        />
      ) : (
        <div className="overflow-x-auto rounded-lg border border-gray-200">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Student</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Class</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Risk</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Attendance</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Absent</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Trend</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Flags</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.map((s) => (
                <tr key={s.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900">
                    {s.name}
                    <br />
                    <span className="text-xs text-gray-400">{s.id}</span>
                  </td>
                  <td className="px-4 py-3">
                    {s.grade} &bull; {s.class}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span
                      className={
                        'inline-block rounded-full border px-2.5 py-0.5 text-xs font-bold ' +
                        riskColor(s.riskScore)
                      }
                    >
                      {s.riskScore}%
                    </span>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <div className="flex items-center justify-center gap-2">
                      <div className="h-2 w-12 rounded-full bg-gray-200">
                        <div
                          className={
                            'h-2 rounded-full ' +
                            (s.attendanceRate < 50
                              ? 'bg-red-500'
                              : s.attendanceRate < 65
                              ? 'bg-yellow-500'
                              : 'bg-green-500')
                          }
                          style={{ width: s.attendanceRate + '%' }}
                        />
                      </div>
                      <span className="text-xs text-gray-500">{s.attendanceRate}%</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-center text-gray-700">{s.daysAbsent}</td>
                  <td
                    className={
                      'px-4 py-3 text-center text-xs font-medium ' +
                      (s.trend === 'rising'
                        ? 'text-red-600'
                        : s.trend === 'stable'
                        ? 'text-yellow-600'
                        : 'text-green-600')
                    }
                  >
                    {TREND_MAP[s.trend]}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1">
                      {s.flags.map((f, i) => (
                        <span
                          key={i}
                          className="rounded bg-gray-100 px-2 py-0.5 text-xs text-gray-600"
                        >
                          {f}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-600 italic">
                    {s.recommendedAction}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm">
        <h3 className="font-semibold text-blue-800">
          ML Model: Ensemble Gradient Boosted Trees + LSTM
        </h3>
        <ul className="mt-2 list-inside list-disc space-y-1 text-blue-700">
          <li>
            <strong>Features:</strong> Daily attendance, lateness, grades,
            discipline records, sibling truancy, socioeconomic indicators
          </li>
          <li>
            <strong>Prediction window:</strong> 10&ndash;14 days before
            chronic absence trigger (&ge;15 days)
          </li>
          <li>
            <strong>Accuracy:</strong> 89.3% precision, 92.1% recall
            &mdash; retrained daily at 02:00
          </li>
        </ul>
      </div>
    </div>
  );
}
