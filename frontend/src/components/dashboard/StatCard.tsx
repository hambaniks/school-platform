interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  trend?: { direction: 'up' | 'down'; label: string };
  color?: string;
  subtitle?: string;
}

const colorMap: Record<string, string> = {
  blue: 'border-l-blue-500 bg-blue-50',
  green: 'border-l-green-500 bg-green-50',
  purple: 'border-l-purple-500 bg-purple-50',
  orange: 'border-l-orange-500 bg-orange-50',
  red: 'border-l-red-500 bg-red-50',
  teal: 'border-l-teal-500 bg-teal-50',
};

const iconMap: Record<string, string> = {
  blue: 'bg-blue-100 text-blue-600',
  green: 'bg-green-100 text-green-600',
  purple: 'bg-purple-100 text-purple-600',
  orange: 'bg-orange-100 text-orange-600',
  red: 'bg-red-100 text-red-600',
  teal: 'bg-teal-100 text-teal-600',
};

export default function StatCard({
  title,
  value,
  icon,
  trend,
  color = 'blue',
  subtitle,
}: StatCardProps) {
  return (
    <div
      className={
        'rounded-lg border border-gray-200 border-l-4 ' +
        colorMap[color] +
        ' p-5 shadow-sm transition hover:shadow-md'
      }
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>
          {subtitle && <p className="mt-1 text-xs text-gray-400">{subtitle}</p>}
        </div>
        <div className={'rounded-lg p-3 ' + iconMap[color]}>{icon}</div>
      </div>
      {trend && (
        <p
          className={
            'mt-3 text-xs font-medium ' +
            (trend.direction === 'up' ? 'text-green-600' : 'text-red-600')
          }
        >
          {trend.direction === 'up' ? '\u25B2' : '\u25BC'} {trend.label}
        </p>
      )}
    </div>
  );
}
