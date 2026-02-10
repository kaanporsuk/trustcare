export default function StatCard({
  label,
  value,
  isLoading,
}: {
  label: string;
  value: number | string;
  isLoading?: boolean;
}) {
  return (
    <div className="rounded-xl bg-white p-4 shadow-sm">
      <p className="text-xs uppercase tracking-wide text-gray-500">{label}</p>
      <div className="mt-3 text-2xl font-semibold text-gray-900">
        {isLoading ? "..." : value}
      </div>
    </div>
  );
}
