"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

const PAGE_SIZE = 20;

type ReviewRow = {
  id: string;
  provider?: { name?: string } | null;
  user?: { full_name?: string; email?: string } | null;
  rating?: number | null;
  price_level?: number | null;
  status?: string | null;
  ai_confidence?: number | null;
  created_at?: string | null;
};

export default function ReviewsPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [reviews, setReviews] = useState<ReviewRow[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [selectedReview, setSelectedReview] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const loadReviews = async () => {
    setIsLoading(true);
    let query = supabase
      .from("reviews")
      .select(
        "id, rating, price_level, status, ai_confidence, created_at, provider:providers(name), user:profiles(full_name, email)",
        { count: "exact" },
      )
      .order("created_at", { ascending: false })
      .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

    if (statusFilter !== "all") {
      query = query.eq("status", statusFilter);
    }

    if (search.trim()) {
      query = query.ilike("content", `%${search.trim()}%`);
    }

    const { data, count } = await query;
    const normalized = (data ?? []).map((item) => ({
      ...item,
      provider: Array.isArray(item.provider) ? item.provider[0] : item.provider,
      user: Array.isArray(item.user) ? item.user[0] : item.user,
    }));
    setReviews(normalized);
    setTotal(count ?? 0);
    setSelected(new Set());
    setIsLoading(false);
  };

  useEffect(() => {
    loadReviews();
  }, [page, statusFilter, search]);

  const loadReviewDetail = async (reviewId: string) => {
    const { data } = await supabase
      .from("reviews")
      .select(
        "id, content, rating, status, ai_confidence, ai_reason, created_at, price_level, proof_url, ratings_breakdown, provider:providers(name), user:profiles(full_name, email), review_media(id, url, media_type, content_status)",
      )
      .eq("id", reviewId)
      .single();

    setSelectedReview(data ?? null);
  };

  const updateStatus = async (reviewIds: string[], status: string) => {
    const payload: Record<string, any> = { status };
    if (status === "active") {
      payload.is_verified = true;
    }
    await supabase.from("reviews").update(payload).in("id", reviewIds);
    await loadReviews();
  };

  const confidenceTone = (value?: number | null) => {
    if (value === null || value === undefined) return "removed";
    if (value >= 80) return "active";
    if (value >= 50) return "pending";
    return "flagged";
  };

  const toggleSelection = (reviewId: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(reviewId)) {
        next.delete(reviewId);
      } else {
        next.add(reviewId);
      }
      return next;
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Reviews</h1>
        <p className="mt-1 text-sm text-gray-500">
          Moderate reviews and verification.
        </p>
      </div>

      <div className="flex flex-wrap gap-3 rounded-xl bg-white p-4 shadow-sm">
        <select
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
          value={statusFilter}
          onChange={(event) => {
            setPage(1);
            setStatusFilter(event.target.value);
          }}
        >
          <option value="all">All Statuses</option>
          <option value="pending_verification">Pending Verification</option>
          <option value="flagged">Flagged</option>
          <option value="active">Active</option>
        </select>
        <input
          className="flex-1 rounded-lg border border-gray-200 px-3 py-2 text-sm"
          placeholder="Search review text"
          value={search}
          onChange={(event) => {
            setPage(1);
            setSearch(event.target.value);
          }}
        />
        <div className="ml-auto flex gap-2">
          <button
            className="rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white"
            onClick={() => updateStatus(Array.from(selected), "active")}
            disabled={selected.size === 0}
            type="button"
          >
            Verify Selected
          </button>
          <button
            className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-semibold text-gray-700"
            onClick={() => updateStatus(Array.from(selected), "removed")}
            disabled={selected.size === 0}
            type="button"
          >
            Reject Selected
          </button>
        </div>
      </div>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-400">
            <tr>
              <th className="px-4 py-3">
                <input
                  type="checkbox"
                  checked={selected.size === reviews.length && reviews.length > 0}
                  onChange={(event) => {
                    if (event.target.checked) {
                      setSelected(new Set(reviews.map((review) => review.id)));
                    } else {
                      setSelected(new Set());
                    }
                  }}
                />
              </th>
              <th className="px-4 py-3">ID</th>
              <th className="px-4 py-3">Provider</th>
              <th className="px-4 py-3">User</th>
              <th className="px-4 py-3">Rating</th>
              <th className="px-4 py-3">Price</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">AI Confidence</th>
              <th className="px-4 py-3">Date</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {reviews.map((review) => (
              <tr key={review.id} className="hover:bg-gray-50">
                <td className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.has(review.id)}
                    onChange={() => toggleSelection(review.id)}
                  />
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {review.id.slice(0, 8)}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {review.provider?.name ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {review.user?.full_name ?? review.user?.email ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {review.rating ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {review.price_level ?? "-"}
                </td>
                <td className="px-4 py-3">
                  <Badge
                    label={review.status ?? "unknown"}
                    tone={review.status ?? "removed"}
                  />
                </td>
                <td className="px-4 py-3">
                  <Badge
                    label={
                      review.ai_confidence !== null &&
                      review.ai_confidence !== undefined
                        ? `${review.ai_confidence}%`
                        : "-"
                    }
                    tone={confidenceTone(review.ai_confidence)}
                  />
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {review.created_at
                    ? new Date(review.created_at).toLocaleDateString()
                    : "-"}
                </td>
                <td className="px-4 py-3">
                  <button
                    className="rounded-lg border border-gray-200 px-3 py-1 text-xs font-semibold"
                    onClick={() => loadReviewDetail(review.id)}
                    type="button"
                  >
                    View
                  </button>
                </td>
              </tr>
            ))}
            {isLoading ? (
              <tr>
                <td className="px-4 py-6 text-center text-sm text-gray-500" colSpan={10}>
                  Loading reviews...
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between text-sm text-gray-500">
        <span>
          Page {page} of {totalPages}
        </span>
        <div className="flex gap-2">
          <button
            className="rounded-lg border border-gray-200 px-3 py-1"
            disabled={page === 1}
            onClick={() => setPage((prev) => Math.max(1, prev - 1))}
            type="button"
          >
            Previous
          </button>
          <button
            className="rounded-lg border border-gray-200 px-3 py-1"
            disabled={page === totalPages}
            onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
            type="button"
          >
            Next
          </button>
        </div>
      </div>

      {selectedReview ? (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 px-4">
          <div className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-2xl bg-white p-6">
            <div className="flex items-start justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">
                  Review Detail
                </h2>
                <p className="text-xs text-gray-500">
                  {selectedReview.provider?.name ?? "Unknown provider"}
                </p>
              </div>
              <button
                className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                onClick={() => setSelectedReview(null)}
                type="button"
              >
                Close
              </button>
            </div>

            <div className="mt-4 space-y-4 text-sm text-gray-700">
              <div>
                <p className="text-xs uppercase text-gray-400">Review Text</p>
                <p className="mt-2 rounded-lg bg-gray-50 p-3">
                  {selectedReview.content ?? "-"}
                </p>
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <p className="text-xs uppercase text-gray-400">Ratings</p>
                  <pre className="mt-2 whitespace-pre-wrap rounded-lg bg-gray-50 p-3 text-xs">
                    {selectedReview.ratings_breakdown
                      ? JSON.stringify(selectedReview.ratings_breakdown, null, 2)
                      : "No ratings breakdown"}
                  </pre>
                </div>
                <div>
                  <p className="text-xs uppercase text-gray-400">AI Verdict</p>
                  <div className="mt-2 rounded-lg bg-gray-50 p-3">
                    <p className="text-sm font-semibold">
                      {selectedReview.ai_confidence ?? "-"}% confidence
                    </p>
                    <p className="mt-1 text-xs text-gray-500">
                      {selectedReview.ai_reason ?? "No AI summary available."}
                    </p>
                  </div>
                </div>
              </div>
              <div>
                <p className="text-xs uppercase text-gray-400">Proof</p>
                {selectedReview.proof_url ? (
                  <img
                    src={selectedReview.proof_url}
                    alt="Proof"
                    className="mt-2 max-h-64 rounded-lg border"
                  />
                ) : (
                  <p className="mt-2 text-sm text-gray-500">
                    No proof uploaded.
                  </p>
                )}
              </div>
              <div>
                <p className="text-xs uppercase text-gray-400">Media</p>
                <div className="mt-2 grid gap-3 md:grid-cols-3">
                  {selectedReview.review_media?.length ? (
                    selectedReview.review_media.map((media: any) => {
                      const url = media.url;
                      const isVideo = media.media_type === "video";
                      return isVideo ? (
                        <video
                          key={media.id}
                          src={url}
                          className="h-32 w-full rounded-lg border"
                          controls
                        />
                      ) : (
                        <img
                          key={media.id}
                          src={url}
                          alt="Review media"
                          className="h-32 w-full rounded-lg border object-cover"
                        />
                      );
                    })
                  ) : (
                    <p className="text-sm text-gray-500">No media attached.</p>
                  )}
                </div>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap gap-3">
              <button
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white"
                onClick={() => updateStatus([selectedReview.id], "active")}
                type="button"
              >
                Verify
              </button>
              <button
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-semibold"
                onClick={() => updateStatus([selectedReview.id], "removed")}
                type="button"
              >
                Reject
              </button>
              <button
                className="rounded-lg border border-rose-200 px-4 py-2 text-sm font-semibold text-rose-600"
                onClick={() => updateStatus([selectedReview.id], "flagged")}
                type="button"
              >
                Flag
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
