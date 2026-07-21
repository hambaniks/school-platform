'use client';

import { useState, useEffect } from 'react';
import StatCard from '@/components/dashboard/StatCard';
import {
  LoadingSpinner,
  ErrorState,
  EmptyState,
} from '@/components/dashboard/LoadingState';
import { mockApi } from '@/lib/api';

interface Invoice {
  id: string;
  learnerName: string;
  description: string;
  amount: number;
  currency: string;
  amountZAR: number;
  exchangeRate: number;
  issuedDate: string;
  dueDate: string;
  status: 'paid' | 'pending' | 'overdue' | 'partial';
  paymentMethod: string | null;
  paidDate: string | null;
}

interface Metrics {
  totalOutstanding: number;
  invoicesThisMonth: number;
  paidThisMonth: number;
  overdueAmount: number;
  currenciesActive: number;
  avgCollectionTime: number;
}

interface Rate {
  pair: string;
  rate: number;
  change24h: number;
  lastUpdated: string;
}

const METRICS: Metrics = {
  totalOutstanding: 485000,
  invoicesThisMonth: 189,
  paidThisMonth: 142,
  overdueAmount: 127000,
  currenciesActive: 3,
  avgCollectionTime: 14,
};

const RATES: Rate[] = [
  { pair: 'USD/ZAR', rate: 18.42, change24h: -0.31, lastUpdated: '2026-07-21T10:00:00Z' },
  { pair: 'GBP/ZAR', rate: 23.57, change24h: 0.15, lastUpdated: '2026-07-21T10:00:00Z' },
  { pair: 'EUR/ZAR', rate: 20.18, change24h: -0.08, lastUpdated: '2026-07-21T10:00:00Z' },
];

const INVOICES: Invoice[] = [
  {
    id: 'INV-2026-0841',
    learnerName: 'Amara Okafor',
    description: 'Term 3 Tuition \u2014 International',
    amount: 4500,
    currency: 'USD',
    amountZAR: 82890,
    exchangeRate: 18.42,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'pending',
    paymentMethod: null,
    paidDate: null,
  },
  {
    id: 'INV-2026-0842',
    learnerName: 'James Mitchell',
    description: 'Term 3 Tuition \u2014 International',
    amount: 3200,
    currency: 'GBP',
    amountZAR: 75424,
    exchangeRate: 23.57,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'paid',
    paymentMethod: 'SWIFT',
    paidDate: '2026-07-15',
  },
  {
    id: 'INV-2026-0843',
    learnerName: 'Sophie Dubois',
    description: 'Term 3 Tuition \u2014 International',
    amount: 3800,
    currency: 'EUR',
    amountZAR: 76684,
    exchangeRate: 20.18,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'pending',
    paymentMethod: null,
    paidDate: null,
  },
  {
    id: 'INV-2026-0844',
    learnerName: 'Lindiwe Nkosi',
    description: 'Term 3 \u2014 Local',
    amount: 8500,
    currency: 'ZAR',
    amountZAR: 8500,
    exchangeRate: 1,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'overdue',
    paymentMethod: null,
    paidDate: null,
  },
  {
    id: 'INV-2026-0845',
    learnerName: 'Thato Molefe',
    description: 'Term 3 \u2014 Local',
    amount: 8500,
    currency: 'ZAR',
    amountZAR: 8500,
    exchangeRate: 1,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'paid',
    paymentMethod: 'EFT',
    paidDate: '2026-07-10',
  },
  {
    id: 'INV-2026-0846',
    learnerName: 'Zanele Khumalo',
    description: 'Term 3 + Bus Transport',
    amount: 11200,
    currency: 'ZAR',
    amountZAR: 11200,
    exchangeRate: 1,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'partial',
    paymentMethod: 'EFT (partial)',
    paidDate: '2026-07-18',
  },
  {
    id: 'INV-2026-0847',
    learnerName: 'Chen Wei',
    description: 'Term 3 \u2014 International',
    amount: 4500,
    currency: 'USD',
    amountZAR: 82890,
    exchangeRate: 18.42,
    issuedDate: '2026-07-01',
    dueDate: '2026-07-31',
    status: 'paid',
    paymentMethod: 'PayPal',
    paidDate: '2026-07-12',
  },
];

const SYM: Record<string, string> = { USD: '$', GBP: '\u00a3', EUR: '\u20ac', ZAR: 'R' };
const ST: Record<string, string> = {
  paid: 'bg-green-100 text-green-700',
  pending: 'bg-blue-100 text-blue-700',
  overdue: 'bg-red-100 text-red-700',
  partial: 'bg-yellow-100 text-yellow-700',
};
const LB: Record<string, string> = {
  paid: 'Paid \u2713',
  pending: 'Pending',
  overdue: 'Overdue!',
  partial: 'Partial',
};

function fmt(amount: number, currency: string): string {
  const s = SYM[currency] || currency + ' ';
  return s + amount.toLocaleString('en-ZA', { minimumFractionDigits: 2 });
}

function fmtZ(amount: number): string {
  return 'R' + amount.toLocaleString('en-ZA', { minimumFractionDigits: 2 });
}

export default function MultiCurrencyPage() {
  const [metrics, setMetrics] = useState<Metrics | null>(null);
  const [rates, setRates] = useState<Rate[]>([]);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [fStatus, setFStatus] = useState<'all' | Invoice['status']>('all');
  const [fCurr, setFCurr] = useState<'all' | string>('all');

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError(null);
    const [m, r, i] = await Promise.all([
      mockApi<Metrics>(METRICS, 600),
      mockApi<Rate[]>(RATES, 400),
      mockApi<Invoice[]>(INVOICES, 900),
    ]);
    if (m.error || r.error || i.error) {
      setError(m.error || r.error || i.error || 'Failed');
    } else {
      setMetrics(m.data);
      setRates(r.data || []);
      setInvoices(i.data || []);
    }
    setLoading(false);
  }

  const filtered = invoices.filter((x) => {
    if (fStatus !== 'all' && x.status !== fStatus) return false;
    if (fCurr !== 'all' && x.currency !== fCurr) return false;
    return true;
  });

  const currs = Array.from(new Set(invoices.map((i) => i.currency)));

  if (loading) return <LoadingSpinner size="lg" />;
  if (error) return <ErrorState message={error} onRetry={load} />;

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Multi-Currency Billing
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Cross-border tuition with live ZAR/USD/GBP/EUR conversion
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <StatCard
          title="Outstanding (ZAR)"
          value={fmtZ(metrics?.totalOutstanding ?? 0)}
          color="blue"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
        <StatCard
          title="This Month"
          value={metrics?.invoicesThisMonth ?? 0}
          color="orange"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          }
        />
        <StatCard
          title="Paid"
          value={metrics?.paidThisMonth ?? 0}
          color="green"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{
            direction: 'up',
            label:
              Math.round(
                ((metrics?.paidThisMonth ?? 0) /
                  (metrics?.invoicesThisMonth ?? 1)) *
                  100
              ) + '% collected',
          }}
        />
        <StatCard
          title="Overdue"
          value={fmtZ(metrics?.overdueAmount ?? 0)}
          color="red"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          trend={{ direction: 'down', label: 'Follow up needed' }}
        />
        <StatCard
          title="Currencies"
          value={metrics?.currenciesActive ?? 0}
          color="purple"
          icon={
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
            </svg>
          }
          subtitle={currs.join(', ')}
        />
      </div>

      {/* Exchange Rate Ticker */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {rates.map((r) => (
          <div
            key={r.pair}
            className="rounded-lg border border-gray-200 bg-white p-3 shadow-sm"
          >
            <p className="text-xs text-gray-500">{r.pair}</p>
            <p className="text-lg font-bold text-gray-900">
              {r.rate.toFixed(4)}
            </p>
            <p
              className={
                'text-xs ' +
                (r.change24h >= 0 ? 'text-green-600' : 'text-red-600')
              }
            >
              {r.change24h >= 0 ? '\u25b2' : '\u25bc'}{' '}
              {Math.abs(r.change24h).toFixed(4)} (24h)
            </p>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-3">
        <select
          value={fStatus}
          onChange={(e) => setFStatus(e.target.value as typeof fStatus)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="all">All Status</option>
          <option value="paid">Paid</option>
          <option value="pending">Pending</option>
          <option value="overdue">Overdue</option>
          <option value="partial">Partial</option>
        </select>
        <select
          value={fCurr}
          onChange={(e) => setFCurr(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
        >
          <option value="all">All Currencies</option>
          {currs.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <span className="text-xs text-gray-400">{filtered.length} invoices</span>
      </div>

      {filtered.length === 0 ? (
        <EmptyState title="No invoices match" />
      ) : (
        <div className="space-y-3">
          {filtered.map((inv) => (
            <div
              key={inv.id}
              className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <span className="text-xs font-mono text-gray-400">
                      {inv.id}
                    </span>
                    <span
                      className={
                        'rounded-full px-2.5 py-0.5 text-xs font-medium ' +
                        ST[inv.status]
                      }
                    >
                      {LB[inv.status]}
                    </span>
                    <span className="rounded bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
                      {inv.currency}
                    </span>
                  </div>
                  <p className="mt-1 font-semibold text-gray-900">
                    {inv.learnerName}
                  </p>
                  <p className="text-sm text-gray-500">{inv.description}</p>
                  <div className="mt-1 flex items-center gap-4 text-xs text-gray-400">
                    <span>
                      Issued:{' '}
                      {new Date(inv.issuedDate).toLocaleDateString('en-ZA')}
                    </span>
                    <span>
                      Due:{' '}
                      {new Date(inv.dueDate).toLocaleDateString('en-ZA')}
                    </span>
                    {inv.paidDate && (
                      <span>
                        Paid:{' '}
                        {new Date(inv.paidDate).toLocaleDateString('en-ZA')}
                      </span>
                    )}
                    {inv.paymentMethod && (
                      <span>Via: {inv.paymentMethod}</span>
                    )}
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xl font-bold text-gray-900">
                    {fmt(inv.amount, inv.currency)}
                  </p>
                  <p className="text-xs text-gray-400">
                    {fmtZ(inv.amountZAR)} @ {inv.exchangeRate.toFixed(4)}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
