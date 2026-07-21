'use client';

import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import {
  LoadingSpinner,
  ErrorState,
  EmptyState,
} from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface Submission {
  id: string;
  studentName: string;
  subject: string;
  assignmentTitle: string;
  submittedAt: string;
  status: 'pending' | 'processing' | 'completed' | 'manual_review';
  score: number | null;
  maxScore: number;
  confidence: number | null;
  rubricScore: { category: string; earned: number; max: number }[];
  feedback: string;
}

interface Metrics {
  totalSubmissions: number;
  autoGraded: number;
  pendingReview: number;
  avgScore: number;
  avgConfidence: number;
  throughput24h: number;
}

const METRICS: Metrics = {
  totalSubmissions: 847,
  autoGraded: 721,
  pendingReview: 126,
  avgScore: 71.4,
  avgConfidence: 94.2,
  throughput24h: 189,
};

const SUBMISSIONS: Submission[] = [
  {
    id: 'GRD-001',
    studentName: 'Lindiwe Nkosi',
    subject: 'Mathematics',
    assignmentTitle: 'Algebra Quiz Term 2',
    submittedAt: '2026-07-21T08:30:00Z',
    status: 'completed',
    score: 34,
    maxScore: 50,
    confidence: 96,
    rubricScore: [
      { category: 'Correctness', earned: 18, max: 25 },
      { category: 'Method', earned: 10, max: 15 },
      { category: 'Presentation', earned: 6, max: 10 },
    ],
    feedback: 'Well structured. Review quadratic formula steps 4-7.',
  },
  {
    id: 'GRD-002',
    studentName: 'Thato Molefe',
    subject: 'English',
    assignmentTitle: 'Essay: SA Identity',
    submittedAt: '2026-07-21T09:15:00Z',
    status: 'completed',
    score: 42,
    maxScore: 50,
    confidence: 91,
    rubricScore: [
      { category: 'Content', earned: 22, max: 25 },
      { category: 'Grammar', earned: 12, max: 15 },
      { category: 'Structure', earned: 8, max: 10 },
    ],
    feedback: 'Excellent argument. Minor grammar on page 2.',
  },
  {
    id: 'GRD-003',
    studentName: 'Zanele Khumalo',
    subject: 'Physical Science',
    assignmentTitle: 'Lab Report: Chemical Reactions',
    submittedAt: '2026-07-21T10:00:00Z',
    status: 'processing',
    score: null,
    maxScore: 60,
    confidence: null,
    rubricScore: [],
    feedback: 'Processing &mdash; ~2 min remaining',
  },
  {
    id: 'GRD-004',
    studentName: 'Sipho Dlamini',
    subject: 'History',
    assignmentTitle: 'Apartheid Timeline',
    submittedAt: '2026-07-20T14:45:00Z',
    status: 'manual_review',
    score: null,
    maxScore: 40,
    confidence: 67,
    rubricScore: [],
    feedback: 'Handwriting confidence < 70% &mdash; manual review needed',
  },
  {
    id: 'GRD-005',
    studentName: 'Amara Okafor',
    subject: 'Mathematics',
    assignmentTitle: 'Geometry Proofs',
    submittedAt: '2026-07-20T11:20:00Z',
    status: 'completed',
    score: 56,
    maxScore: 60,
    confidence: 98,
    rubricScore: [
      { category: 'Correctness', earned: 30, max: 30 },
      { category: 'Method', earned: 15, max: 15 },
      { category: 'Presentation', earned: 11, max: 15 },
    ],
    feedback: 'Perfect proofs. Improve diagram labels.',
  },
  {
    id: 'GRD-006',
    studentName: 'Bongani Zuma',
    subject: 'Geography',
    assignmentTitle: 'Climate Graphs',
    submittedAt: '2026-07-19T16:30:00Z',
    status: 'pending',
    score: null,
    maxScore: 30,
    confidence: null,
    rubricScore: [],
    feedback: 'In queue &mdash; ~15 min wait',
  },
];

const STATUS_STYLE: Record<string, string> = {
  pending: 'bg-gray-100 text-gray-600',
  processing: 'bg-blue-100 text-blue-600',
  completed: 'bg-green-100 text-green-600',
  manual_review: 'bg-yellow-100 text-yellow-600',
};

const STATUS_LABEL: Record<string, string> = {
  pending: 'Pending',
  processing: 'Processing...',
  completed: 'Graded \u2713',
  manual_review: 'Manual Review',
};

export default function AutoGradingPage() {
  const [metrics, setMetrics] = useState<Metrics | null>(null);
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | Submission['status']>('all');

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError(null);
    const [m, r] = await Promise.all([
      mockApi<Metrics>(METRICS, 600),
      mockApi<Submission[]>(SUBMISSIONS, 900),
    ]);
    if (m.error || r.error) {
      setError(m.error || r.error || 'Failed to load');
    } else {
      setMetrics(m.data);
      setSubmissions(r.data || []);
    }
    setLoading(false);
  }

  const filtered =
    filter === 'all'
      ? submissions
      : submissions.filter((s) => s.status === filter);

  if (loading) return <LoadingSpinner size="lg" />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          AI Auto-Grading Engine
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Computer vision + NLP scoring of handwritten submissions
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <StatCard
          title="Total"
          value={metrics?.totalSubmissions ?? 0}
          color="blue"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          }
        />
        <StatCard
          title="Auto-Graded"
          value={metrics?.autoGraded ?? 0}
          color="green"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{ direction: 'up', label: (metrics?.throughput24h ?? 0) + ' graded today' }}
        />
        <StatCard
          title="Pending Review"
          value={metrics?.pendingReview ?? 0}
          color="orange"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
        <StatCard
          title="Avg Score"
          value={(metrics?.avgScore ?? 0) + '%'}
          color="purple"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
          }
        />
        <StatCard
          title="AI Confidence"
          value={(metrics?.avgConfidence ?? 0) + '%'}
          color="teal"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          }
          subtitle="Threshold: >85% auto-grade"
        />
      </div>

      <div className="flex items-center gap-3">
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as typeof filter)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="all">All</option>
          <option value="pending">Pending</option>
          <option value="processing">Processing</option>
          <option value="completed">Completed</option>
          <option value="manual_review">Manual Review</option>
        </select>
        <span className="text-xs text-gray-400">{filtered.length} submissions</span>
      </div>

      {filtered.length === 0 ? (
        <EmptyState title="No submissions match" />
      ) : (
        <div className="space-y-3">
          {filtered.map((s) => (
            <div
              key={s.id}
              className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <h3 className="font-semibold text-gray-900">
                      {s.assignmentTitle}
                    </h3>
                    <span
                      className={
                        'rounded-full px-2.5 py-0.5 text-xs font-medium ' +
                        STATUS_STYLE[s.status]
                      }
                    >
                      {STATUS_LABEL[s.status]}
                    </span>
                  </div>
                  <p className="mt-1 text-sm text-gray-500">
                    {s.studentName} &middot; {s.subject} &middot;{' '}
                    {new Date(s.submittedAt).toLocaleString('en-ZA', {
                      timeZone: 'Africa/Johannesburg',
                    })}
                  </p>
                </div>
                {s.score !== null && (
                  <div className="text-right">
                    <p className="text-2xl font-bold text-gray-900">
                      {s.score}/{s.maxScore}
                    </p>
                    <p className="text-xs text-gray-400">
                      ({Math.round((s.score / s.maxScore) * 100)}%)
                    </p>
                  </div>
                )}
              </div>

              {s.rubricScore.length > 0 && (
                <div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3">
                  {s.rubricScore.map((r, i) => (
                    <div key={i} className="rounded bg-gray-50 p-2 text-xs">
                      <span className="text-gray-500">{r.category}</span>
                      <div className="mt-1 flex items-center gap-2">
                        <div className="h-1.5 flex-1 rounded-full bg-gray-200">
                          <div
                            className="h-1.5 rounded-full bg-blue-500"
                            style={{
                              width: (r.earned / r.max) * 100 + '%',
                            }}
                          />
                        </div>
                        <span className="font-medium text-gray-700">
                          {r.earned}/{r.max}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {s.confidence !== null && s.status === 'completed' && (
                <div className="mt-2 flex items-center gap-2 text-xs">
                  <span className="text-gray-400">AI Confidence:</span>
                  <span
                    className={
                      'font-medium ' +
                      (s.confidence >= 90
                        ? 'text-green-600'
                        : s.confidence >= 80
                        ? 'text-yellow-600'
                        : 'text-red-600')
                    }
                  >
                    {s.confidence}%
                  </span>
                </div>
              )}

              <div className="mt-2 rounded bg-blue-50 p-2 text-xs text-blue-700">
                {s.feedback}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
