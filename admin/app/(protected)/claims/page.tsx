"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

const PAGE_SIZE = 20;

type ClaimRow = {
  id: string;
  provider_id?: string | null;
  claimant_user_id?: string | null;
  claimant_role?: string | null;
  status?: string | null;
  created_at?: string | null;
  proof_document_url?: string | null;
  provider?: { name?: string; website?: string; email?: string } | null;
  claimant?: { full_name?: string } | null;
};

export default function ClaimsPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [claims, setClaims] = useState<ClaimRow[]>([]);
  const [showAll, setShowAll] = useState(false);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [selectedClaim, setSelectedClaim] = useState<ClaimRow | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const loadClaims = async () => {
    setIsLoading(true);
    let query = supabase
      .from("provider_claims")
      .select(
        "id, provider_id, claimant_user_id, claimant_role, status, created_at, proof_document_url, provider:providers(name, website, email), claimant:profiles(full_name)",
        { count: "exact" },
      )
      .order("created_at", { ascending: false })
      .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

    if (!showAll) {
      query = query.eq("status", "pending");
    }

    const { data, count } = await query;
    const normalized = (data ?? []).map((item) => ({
      ...item,
      provider: Array.isArray(item.provider) ? item.provider[0] : item.provider,
      claimant: Array.isArray(item.claimant) ? item.claimant[0] : item.claimant,
    }));
    setClaims(normalized);
    setTotal(count ?? 0);
    setIsLoading(false);
  };

  useEffect(() => {
    loadClaims();
  }, [page, showAll]);

  const approveClaim = async (claim: ClaimRow) => {
    await supabase
      .from("provider_claims")
      .update({ status: "approved" })
      .eq("id", claim.id);

    if (claim.provider_id && claim.claimant_user_id) {
      await supabase
        .from("providers")
        .update({
          is_claimed: true,
          claimed_by: claim.claimant_user_id,
        })
        .eq("id", claim.provider_id);

      await supabase.from("provider_subscriptions").insert({
        provider_id: claim.provider_id,
        tier: "basic",
        is_trial: true,
        status: "active",
      });
    }

    setSelectedClaim(null);
    await loadClaims();
  };

  const rejectClaim = async (claim: ClaimRow) => {
    if (!rejectionReason.trim()) return;
    const cooloffDate = new Date();
    cooloffDate.setDate(cooloffDate.getDate() + 90);

    await supabase
      .from("provider_claims")
      .update({
        status: "rejected",
        rejection_reason: rejectionReason.trim(),
        cooloff_until: cooloffDate.toISOString(),
      })
      .eq("id", claim.id);

    setSelectedClaim(null);
    setRejectionReason("");
    await loadClaims();
  };

  const extractDomain = (value?: string | null) => {
    if (!value) return "-";
    return value.replace(/^https?:\/\//, "").split("/")[0];
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Claims</h1>
        <p className="mt-1 text-sm text-gray-500">
          Review provider ownership claims.
        </p>
      </div>

      <div className="flex items-center gap-3 rounded-xl bg-white p-4 shadow-sm">
        <label className="flex items-center gap-2 text-sm text-gray-600">
          <input
            type="checkbox"
            checked={showAll}
            onChange={(event) => setShowAll(event.target.checked)}
          />
          Show all claims
        </label>
      </div>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-400">
            <tr>
              <th className="px-4 py-3">Claim ID</th>
              <th className="px-4 py-3">Provider</th>
              <th className="px-4 py-3">Claimant</th>
              <th className="px-4 py-3">Role</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Date</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {claims.map((claim) => (
              <tr key={claim.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-gray-500">
                  {claim.id.slice(0, 8)}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {claim.provider?.name ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {claim.claimant?.full_name ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {claim.claimant_role ?? "-"}
                </td>
                <td className="px-4 py-3">
                  <Badge label={claim.status ?? "-"} tone={claim.status ?? "pending"} />
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {claim.created_at
                    ? new Date(claim.created_at).toLocaleDateString()
                    : "-"}
                </td>
                <td className="px-4 py-3">
                  <button
                    className="rounded-lg border border-gray-200 px-3 py-1 text-xs font-semibold"
                    onClick={() => setSelectedClaim(claim)}
                    type="button"
                  >
                    Review
                  </button>
                </td>
              </tr>
            ))}
            {isLoading ? (
              <tr>
                <td className="px-4 py-6 text-center text-sm text-gray-500" colSpan={7}>
                  Loading claims...
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

      {selectedClaim ? (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-3xl rounded-2xl bg-white p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">
                Claim Review
              </h2>
              <button
                className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                onClick={() => setSelectedClaim(null)}
                type="button"
              >
                Close
              </button>
            </div>

            <div className="mt-4 grid gap-4 md:grid-cols-2">
              <div className="rounded-xl bg-gray-50 p-4">
                <h3 className="text-sm font-semibold text-gray-800">Provider</h3>
                <p className="mt-2 text-sm text-gray-600">
                  {selectedClaim.provider?.name ?? "-"}
                </p>
                <p className="mt-1 text-xs text-gray-500">
                  Website: {selectedClaim.provider?.website ?? "-"}
                </p>
                <p className="mt-1 text-xs text-gray-500">
                  Business Email: {selectedClaim.provider?.email ?? "-"}
                </p>
              </div>
              <div className="rounded-xl bg-gray-50 p-4">
                <h3 className="text-sm font-semibold text-gray-800">Claim</h3>
                <p className="mt-2 text-sm text-gray-600">
                  Claimant: {selectedClaim.claimant?.full_name ?? "-"}
                </p>
                <p className="mt-1 text-xs text-gray-500">
                  Role: {selectedClaim.claimant_role ?? "-"}
                </p>
                <p className="mt-1 text-xs text-gray-500">
                  Proof: {selectedClaim.proof_document_url ? "Uploaded" : "Missing"}
                </p>
              </div>
            </div>

            <div className="mt-4 rounded-xl bg-gray-50 p-4 text-sm text-gray-600">
              Domain check: claimant email domain ({extractDomain(
                undefined,
              )}) vs provider website domain ({extractDomain(
                selectedClaim.provider?.website,
              )}).
            </div>

            {selectedClaim.proof_document_url ? (
              <img
                src={selectedClaim.proof_document_url}
                alt="Proof"
                className="mt-4 max-h-64 w-full rounded-lg border object-contain"
              />
            ) : null}

            <div className="mt-6 flex flex-wrap gap-3">
              <button
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white"
                onClick={() => approveClaim(selectedClaim)}
                type="button"
              >
                Approve
              </button>
              <div className="flex flex-1 flex-col gap-2">
                <textarea
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  rows={2}
                  placeholder="Rejection reason (required)"
                  value={rejectionReason}
                  onChange={(event) => setRejectionReason(event.target.value)}
                />
                <button
                  className="rounded-lg border border-rose-200 px-4 py-2 text-sm font-semibold text-rose-600"
                  onClick={() => rejectClaim(selectedClaim)}
                  type="button"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
