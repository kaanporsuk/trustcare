const colorMap: Record<string, string> = {
  active: "bg-emerald-100 text-emerald-700",
  pending: "bg-amber-100 text-amber-700",
  pending_verification: "bg-amber-100 text-amber-700",
  flagged: "bg-rose-100 text-rose-700",
  removed: "bg-gray-200 text-gray-700",
  approved: "bg-emerald-100 text-emerald-700",
  rejected: "bg-rose-100 text-rose-700",
};

export default function Badge({
  label,
  tone,
}: {
  label: string;
  tone?: string;
}) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ${
        tone ? colorMap[tone] : "bg-gray-100 text-gray-700"
      }`}
    >
      {label}
    </span>
  );
}
