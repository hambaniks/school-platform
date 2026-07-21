'use client';

import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import {
  LoadingSpinner,
  ErrorState,
  EmptyState,
} from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface VaccinationRecord {
  id: string;
  learnerName: string;
  grade: string;
  school: string;
  vaccine: string;
  dose: string;
  dueDate: string;
  administeredDate: string | null;
  status: 'completed' | 'overdue' | 'upcoming' | 'pending_reminder';
  clinic: string;
  notes: string;
}

interface Metrics {
  totalLearners: number;
  fullyVaccinated: number;
  overdueDoses: number;
  upcomingDoses: number;
  coverageRate: number;
  remindersSentThisMonth: number;
}

const METRICS: Metrics = {
  totalLearners: 1250,
  fullyVaccinated: 1038,
  overdueDoses: 47,
  upcomingDoses: 165,
  coverageRate: 83,
  remindersSentThisMonth: 312,
};

const RECORDS: VaccinationRecord[] = [
  {
    id: 'VAC-001',
    learnerName: 'Lindiwe Nkosi',
    grade: '10',
    school: 'Soweto High',
    vaccine: 'HPV (Gardasil)',
    dose: 'Dose 2',
    dueDate: '2026-08-15',
    administeredDate: null,
    status: 'upcoming',
    clinic: 'Soweto Clinic',
    notes: '2nd dose due 6 months after 1st',
  },
  {
    id: 'VAC-002',
    learnerName: 'Thato Molefe',
    grade: '9',
    school: 'Soweto High',
    vaccine: 'Tdap Booster',
    dose: 'Booster',
    dueDate: '2026-06-30',
    administeredDate: null,
    status: 'overdue',
    clinic: 'Orlando Health',
    notes: '21 days overdue &mdash; contacted 2x',
  },
  {
    id: 'VAC-003',
    learnerName: 'Zanele Khumalo',
    grade: '11',
    school: 'Soweto High',
    vaccine: 'MenACWY',
    dose: 'Dose 1',
    dueDate: '2026-07-10',
    administeredDate: '2026-07-08',
    status: 'completed',
    clinic: 'Soweto Clinic',
    notes: 'Completed. Next at age 16.',
  },
  {
    id: 'VAC-004',
    learnerName: 'Sipho Dlamini',
    grade: '8',
    school: 'JHB Academy',
    vaccine: 'COVID-19',
    dose: 'Dose 2',
    dueDate: '2026-09-01',
    administeredDate: null,
    status: 'upcoming',
    clinic: 'Braamfontein Vacc Centre',
    notes: 'Schedule late August',
  },
  {
    id: 'VAC-005',
    learnerName: 'Amara Okafor',
    grade: '12',
    school: 'JHB Academy',
    vaccine: 'Hepatitis B',
    dose: 'Dose 3',
    dueDate: '2026-05-20',
    administeredDate: '2026-05-18',
    status: 'completed',
    clinic: 'Auckland Park Clinic',
    notes: 'Series complete \u2713',
  },
  {
    id: 'VAC-006',
    learnerName: 'Bongani Zuma',
    grade: '10',
    school: 'Soweto High',
    vaccine: 'IPV (Polio)',
    dose: 'Booster',
    dueDate: '2026-07-01',
    administeredDate: null,
    status: 'overdue',
    clinic: 'Orlando Health',
    notes: '20 days overdue &mdash; no SMS response',
  },
  {
    id: 'VAC-007',
    learnerName: 'Nomsa Khumalo',
    grade: '1',
    school: 'Mapetla Primary',
    vaccine: 'MMR',
    dose: 'Dose 2',
    dueDate: '2026-08-20',
    administeredDate: null,
    status: 'pending_reminder',
    clinic: 'Mapetla Clinic',
    notes: 'Send reminder 30 days before',
  },
  {
    id: 'VAC-008',
    learnerName: 'Thabo Ngubane',
    grade: '2',
    school: 'Mapetla Primary',
    vaccine: 'DTaP',
    dose: 'Dose 5',
    dueDate: '2026-07-25',
    administeredDate: null,
    status: 'pending_reminder',
    clinic: 'Mapetla Clinic',
    notes: 'Final dose in series',
  },
];

const STYLE: Record<string, string> = {
  completed: 'bg-green-100 text-green-700',
  overdue: 'bg-red-100 text-red-700',
  upcoming: 'bg-blue-100 text-blue-700',
  pending_reminder: 'bg-yellow-100 text-yellow-700',
};

const LABEL: Record<string, string> = {
  completed: 'Completed \u2713',
  overdue: 'Overdue!',
  upcoming: 'Upcoming',
  pending_reminder: 'Reminder Pending',
};

export default function ImmunizationPage() {
  const [metrics, setMetrics] = useState<Metrics | null>(null);
  const [records, setRecords] = useState<VaccinationRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | VaccinationRecord['status']>('all');

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError(null);
    const [m, r] = await Promise.all([
      mockApi<Metrics>(METRICS, 600),
      mockApi<VaccinationRecord[]>(RECORDS, 800),
    ]);
    if (m.error || r.error) {
      setError(m.error || r.error || 'Failed');
    } else {
      setMetrics(m.data);
      setRecords(r.data || []);
    }
    setLoading(false);
  }

  const filtered = records.filter((rec) => {
    const match =
      rec.learnerName.toLowerCase().includes(search.toLowerCase()) ||
      rec.vaccine.toLowerCase().includes(search.toLowerCase()) ||
      rec.school.toLowerCase().includes(search.toLowerCase());
    if (!match) return false;
    if (filter !== 'all' && rec.status !== filter) return false;
    return true;
  });

  if (loading) return <LoadingSpinner size="lg" />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Immunization Tracker
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Vaccine schedule tracking with automated clinic + parent reminders
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <StatCard
          title="Total Learners"
          value={metrics?.totalLearners ?? 0}
          color="blue"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          }
        />
        <StatCard
          title="Fully Vaccinated"
          value={metrics?.fullyVaccinated ?? 0}
          color="green"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{ direction: 'up', label: (metrics?.coverageRate ?? 0) + '% coverage' }}
        />
        <StatCard
          title="Overdue"
          value={metrics?.overdueDoses ?? 0}
          color="red"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{ direction: 'down', label: 'Urgent action' }}
        />
        <StatCard
          title="Upcoming"
          value={metrics?.upcomingDoses ?? 0}
          color="purple"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          }
        />
        <StatCard
          title="Reminders Sent"
          value={metrics?.remindersSentThisMonth ?? 0}
          color="orange"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
          }
          subtitle="This month"
        />
      </div>

      <div className="flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Search learner, vaccine, school..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-blue-500 focus:outline-none w-72"
        />
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as typeof filter)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="all">All</option>
          <option value="completed">Completed</option>
          <option value="overdue">Overdue</option>
          <option value="upcoming">Upcoming</option>
          <option value="pending_reminder">Reminder Pending</option>
        </select>
        <span className="text-xs text-gray-400">{filtered.length} records</span>
      </div>

      {filtered.length === 0 ? (
        <EmptyState title="No records match" />
      ) : (
        <div className="overflow-x-auto rounded-lg border border-gray-200">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Learner</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Grade</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">School</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Vaccine</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Dose</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Due</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Given</th>
                <th className="px-4 py-3 text-center font-medium text-gray-500">Status</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">Clinic</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.map((rec) => (
                <tr key={rec.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900">
                    {rec.learnerName}
                  </td>
                  <td className="px-4 py-3">{rec.grade}</td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {rec.school}
                  </td>
                  <td className="px-4 py-3">{rec.vaccine}</td>
                  <td className="px-4 py-3 text-center">{rec.dose}</td>
                  <td className="px-4 py-3 text-center">
                    {new Date(rec.dueDate).toLocaleDateString('en-ZA')}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {rec.administeredDate
                      ? new Date(rec.administeredDate).toLocaleDateString('en-ZA')
                      : '\u2014'}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span
                      className={
                        'inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ' +
                        STYLE[rec.status]
                      }
                    >
                      {LABEL[rec.status]}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {rec.clinic}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <h3 className="font-semibold text-gray-900">
          Automated Reminder Cadence
        </h3>
        <ul className="mt-2 space-y-1 text-sm text-gray-600">
          <li>
            &bull; <strong>30 days before:</strong> SMS to parent + clinic
            notification
          </li>
          <li>
            &bull; <strong>14 days before:</strong> WhatsApp with clinic
            hours
          </li>
          <li>
            &bull; <strong>Due date:</strong> Automated call + clinic
            confirmation
          </li>
          <li>
            &bull; <strong>7 days overdue:</strong> School nurse + social
            worker
          </li>
          <li>
            &bull; <strong>30 days overdue:</strong> DoH liaison case
          </li>
        </ul>
      </div>
    </div>
  );
}
