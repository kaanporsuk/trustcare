type ChartProps = {
  title: string;
  subtitle: string;
  data: number[];
};

export function BarChartCard({ title, subtitle, data }: ChartProps) {
  const max = Math.max(1, ...data);
  return (
    <div className="rounded-xl bg-white p-4 shadow-sm">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-semibold text-gray-900">{title}</p>
          <p className="text-xs text-gray-500">{subtitle}</p>
        </div>
      </div>
      <div className="mt-4 flex h-40 items-end gap-1">
        {data.map((value, index) => (
          <div
            key={`${title}-bar-${index}`}
            className="flex-1 rounded-md bg-blue-100"
            style={{ height: `${(value / max) * 100}%` }}
          >
            <div className="h-full w-full rounded-md bg-blue-600" />
          </div>
        ))}
      </div>
    </div>
  );
}

export function LineChartCard({ title, subtitle, data }: ChartProps) {
  const max = Math.max(1, ...data);
  const points = data
    .map((value, index) => {
      const x = (index / (data.length - 1 || 1)) * 100;
      const y = 100 - (value / max) * 100;
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <div className="rounded-xl bg-white p-4 shadow-sm">
      <div>
        <p className="text-sm font-semibold text-gray-900">{title}</p>
        <p className="text-xs text-gray-500">{subtitle}</p>
      </div>
      <div className="mt-4 h-40">
        <svg className="h-full w-full" viewBox="0 0 100 100">
          <polyline
            fill="none"
            stroke="#0055FF"
            strokeWidth="2"
            points={points}
          />
        </svg>
      </div>
    </div>
  );
}
