"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import StatCard from "@/components/StatCard";
import { BarChartCard, LineChartCard } from "@/components/Charts";
import Badge from "@/components/Badge";

const days = 30;
const weeks = 12;

export default function DashboardPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState({
    users: 0,
    reviews: 0,
    pendingVerification: 0,
    pendingClaims: 0,
    activeProviders: 0,
  });
  const [reviewsDaily, setReviewsDaily] = useState<number[]>(
    Array.from({ length: days }, () => 0),
  );
  const [usersWeekly, setUsersWeekly] = useState<number[]>(
    Array.from({ length: weeks }, () => 0),
  );
  const [recentReviews, setRecentReviews] = useState<any[]>([]);

  useEffect(() => {
    const loadDashboard = async () => {
      setIsLoading(true);
      const [usersCount, reviewsCount, pendingReviewsCount, pendingClaimsCount] =
        await Promise.all([
          supabase.from("profiles").select("id", { count: "exact", head: true }),
          supabase.from("reviews").select("id", { count: "exact", head: true }),
          supabase
            .from("reviews")
            .select("id", { count: "exact", head: true })
            .eq("status", "pending_verification"),
          supabase
            .from("provider_claims")
            .select("id", { count: "exact", head: true })
            .eq("status", "pending"),
        ]);

      const activeProvidersCount = await supabase
        .from("providers")
        .select("id", { count: "exact", head: true })
        .eq("is_active", true);

      setStats({
        users: usersCount.count ?? 0,
        reviews: reviewsCount.count ?? 0,
        pendingVerification: pendingReviewsCount.count ?? 0,
        pendingClaims: pendingClaimsCount.count ?? 0,
        activeProviders: activeProvidersCount.count ?? 0,
      });

      const startDate = new Date();
      startDate.setDate(startDate.getDate() - (days - 1));

      const { data: reviewDates } = await supabase
        .from("reviews")
        .select("created_at")
        .gte("created_at", startDate.toISOString());

      const dailyCounts = Array.from({ length: days }, () => 0);
      reviewDates?.forEach((review) => {
        const date = new Date(review.created_at);
        const index = Math.floor(
          (date.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
        );
        if (index >= 0 && index < days) {
          dailyCounts[index] += 1;
        }
      });
      setReviewsDaily(dailyCounts);

      const weeklyStart = new Date();
      weeklyStart.setDate(weeklyStart.getDate() - weeks * 7 + 1);

      const { data: userDates } = await supabase
        .from("profiles")
        .select("created_at")
        .gte("created_at", weeklyStart.toISOString());

      const weeklyCounts = Array.from({ length: weeks }, () => 0);
      userDates?.forEach((profile) => {
        const date = new Date(profile.created_at);
        const diffDays = Math.floor(
          (date.getTime() - weeklyStart.getTime()) / (1000 * 60 * 60 * 24),
        );
        const index = Math.floor(diffDays / 7);
        if (index >= 0 && index < weeks) {
          weeklyCounts[index] += 1;
        }
      });
      setUsersWeekly(weeklyCounts);

      const { data: recent } = await supabase
        .from("reviews")
        .select(
          "id, rating, status, created_at, provider:providers(name), user:profiles(full_name, email)",
        )
        .order("created_at", { ascending: false })
        .limit(10);

      setRecentReviews(recent ?? []);
      setIsLoading(false);
    };

    loadDashboard();
  }, [supabase]);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          TrustCare overview and latest activity.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
        <StatCard label="Total Users" value={stats.users} isLoading={isLoading} />
        <StatCard
          label="Total Reviews"
          value={stats.reviews}
          isLoading={isLoading}
        />
        <StatCard
          label="Pending Verifications"
          value={stats.pendingVerification}
          isLoading={isLoading}
        />
        <StatCard
          label="Pending Claims"
          value={stats.pendingClaims}
          isLoading={isLoading}
        />
        <StatCard
          label="Active Providers"
          value={stats.activeProviders}
          isLoading={isLoading}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <BarChartCard
          title="Reviews per day"
          subtitle="Last 30 days"
          data={reviewsDaily}
        />
        <LineChartCard
          title="New users per week"
          subtitle="Last 12 weeks"
          data={usersWeekly}
        />
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">
              Recent reviews
            </h2>
            <p className="text-xs text-gray-500">
              Last 10 reviews submitted.
            </p>
          </div>
        </div>
        <div className="mt-4 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-xs uppercase text-gray-400">
              <tr>
                <th className="px-3 py-2">Provider</th>
                <th className="px-3 py-2">User</th>
                <th className="px-3 py-2">Rating</th>
                <th className="px-3 py-2">Status</th>
                <th className="px-3 py-2">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {recentReviews.map((review) => (
                <tr key={review.id} className="hover:bg-gray-50">
                  <td className="px-3 py-3 text-gray-700">
                    {review.provider?.name ?? "-"}
                  </td>
                  <td className="px-3 py-3 text-gray-700">
                    {review.user?.full_name ?? review.user?.email ?? "-"}
                  </td>
                  <td className="px-3 py-3 text-gray-700">
                    {review.rating ?? "-"}
                  </td>
                  <td className="px-3 py-3">
                    <Badge
                      label={review.status ?? "unknown"}
                      tone={review.status}
                    />
                  </td>
                  <td className="px-3 py-3 text-gray-500">
                    {review.created_at
                      ? new Date(review.created_at).toLocaleDateString()
                      : "-"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
