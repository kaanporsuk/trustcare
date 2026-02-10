"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

const PAGE_SIZE = 20;

type ProviderRow = {
  id: string;
  name?: string | null;
  specialty?: string | null;
  city?: string | null;
  country?: string | null;
  rating?: number | null;
  reviews_count?: number | null;
  is_claimed?: boolean | null;
  is_featured?: boolean | null;
  is_active?: boolean | null;
};

export default function ProvidersPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [providers, setProviders] = useState<ProviderRow[]>([]);
  const [statusFilter, setStatusFilter] = useState("all");
  const [claimedFilter, setClaimedFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [selectedProvider, setSelectedProvider] = useState<ProviderRow | null>(
    null,
  );
  const [showAddModal, setShowAddModal] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [form, setForm] = useState({
    name: "",
    specialty: "",
    city: "",
    country: "",
  });

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const loadProviders = async () => {
    setIsLoading(true);
    let query = supabase
      .from("providers")
      .select("*", { count: "exact" })
      .order("name", { ascending: true })
      .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

    if (statusFilter !== "all") {
      query = query.eq("is_active", statusFilter === "active");
    }

    if (claimedFilter !== "all") {
      query = query.eq("is_claimed", claimedFilter === "claimed");
    }

    if (search.trim()) {
      query = query.ilike("name", `%${search.trim()}%`);
    }

    const { data, count } = await query;
    setProviders(data ?? []);
    setTotal(count ?? 0);
    setIsLoading(false);
  };

  useEffect(() => {
    loadProviders();
  }, [page, statusFilter, claimedFilter, search]);

  const toggleProvider = async (providerId: string, field: string, value: any) => {
    await supabase.from("providers").update({ [field]: value }).eq("id", providerId);
    await loadProviders();
  };

  const saveProvider = async () => {
    if (!form.name.trim()) return;
    await supabase.from("providers").insert({
      name: form.name.trim(),
      specialty: form.specialty.trim(),
      city: form.city.trim(),
      country: form.country.trim(),
      is_active: true,
    });
    setShowAddModal(false);
    setForm({ name: "", specialty: "", city: "", country: "" });
    await loadProviders();
  };

  const updateProviderDetails = async () => {
    if (!selectedProvider) return;
    await supabase
      .from("providers")
      .update({
        name: selectedProvider.name,
        specialty: selectedProvider.specialty,
        city: selectedProvider.city,
        country: selectedProvider.country,
      })
      .eq("id", selectedProvider.id);
    setSelectedProvider(null);
    await loadProviders();
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Providers</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage provider listings and featured status.
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
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
        <select
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
          value={claimedFilter}
          onChange={(event) => {
            setPage(1);
            setClaimedFilter(event.target.value);
          }}
        >
          <option value="all">Claimed + Unclaimed</option>
          <option value="claimed">Claimed</option>
          <option value="unclaimed">Unclaimed</option>
        </select>
        <input
          className="flex-1 rounded-lg border border-gray-200 px-3 py-2 text-sm"
          placeholder="Search provider name"
          value={search}
          onChange={(event) => {
            setPage(1);
            setSearch(event.target.value);
          }}
        />
        <button
          className="ml-auto rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white"
          onClick={() => setShowAddModal(true)}
          type="button"
        >
          Add Provider
        </button>
      </div>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-400">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Specialty</th>
              <th className="px-4 py-3">City</th>
              <th className="px-4 py-3">Country</th>
              <th className="px-4 py-3">Rating</th>
              <th className="px-4 py-3">Reviews</th>
              <th className="px-4 py-3">Claimed</th>
              <th className="px-4 py-3">Featured</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {providers.map((provider) => (
              <tr key={provider.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-gray-900">
                  {provider.name ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {provider.specialty ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {provider.city ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {provider.country ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {provider.rating ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {provider.reviews_count ?? "-"}
                </td>
                <td className="px-4 py-3">
                  <Badge
                    label={provider.is_claimed ? "Claimed" : "Unclaimed"}
                    tone={provider.is_claimed ? "active" : "pending"}
                  />
                </td>
                <td className="px-4 py-3">
                  <Badge
                    label={provider.is_featured ? "Featured" : "Standard"}
                    tone={provider.is_featured ? "active" : "removed"}
                  />
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-2">
                    <button
                      className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                      onClick={() => setSelectedProvider(provider)}
                      type="button"
                    >
                      Edit
                    </button>
                    <button
                      className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                      onClick={() =>
                        toggleProvider(
                          provider.id,
                          "is_active",
                          !provider.is_active,
                        )
                      }
                      type="button"
                    >
                      {provider.is_active ? "Deactivate" : "Activate"}
                    </button>
                    <button
                      className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                      onClick={() =>
                        toggleProvider(
                          provider.id,
                          "is_featured",
                          !provider.is_featured,
                        )
                      }
                      type="button"
                    >
                      {provider.is_featured ? "Unfeature" : "Feature"}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {isLoading ? (
              <tr>
                <td className="px-4 py-6 text-center text-sm text-gray-500" colSpan={9}>
                  Loading providers...
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

      {showAddModal ? (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">
                Add Provider
              </h2>
              <button
                className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                onClick={() => setShowAddModal(false)}
                type="button"
              >
                Close
              </button>
            </div>
            <div className="mt-4 space-y-3">
              <input
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                placeholder="Name"
                value={form.name}
                onChange={(event) =>
                  setForm((prev) => ({ ...prev, name: event.target.value }))
                }
              />
              <input
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                placeholder="Specialty"
                value={form.specialty}
                onChange={(event) =>
                  setForm((prev) => ({ ...prev, specialty: event.target.value }))
                }
              />
              <div className="grid gap-3 md:grid-cols-2">
                <input
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  placeholder="City"
                  value={form.city}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, city: event.target.value }))
                  }
                />
                <input
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  placeholder="Country"
                  value={form.country}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, country: event.target.value }))
                  }
                />
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
                onClick={() => setShowAddModal(false)}
                type="button"
              >
                Cancel
              </button>
              <button
                className="rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white"
                onClick={saveProvider}
                type="button"
              >
                Save Provider
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {selectedProvider ? (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">
                Edit Provider
              </h2>
              <button
                className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                onClick={() => setSelectedProvider(null)}
                type="button"
              >
                Close
              </button>
            </div>
            <div className="mt-4 space-y-3">
              <input
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                value={selectedProvider.name ?? ""}
                onChange={(event) =>
                  setSelectedProvider((prev) =>
                    prev ? { ...prev, name: event.target.value } : prev,
                  )
                }
              />
              <input
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                value={selectedProvider.specialty ?? ""}
                onChange={(event) =>
                  setSelectedProvider((prev) =>
                    prev ? { ...prev, specialty: event.target.value } : prev,
                  )
                }
              />
              <div className="grid gap-3 md:grid-cols-2">
                <input
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  value={selectedProvider.city ?? ""}
                  onChange={(event) =>
                    setSelectedProvider((prev) =>
                      prev ? { ...prev, city: event.target.value } : prev,
                    )
                  }
                />
                <input
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  value={selectedProvider.country ?? ""}
                  onChange={(event) =>
                    setSelectedProvider((prev) =>
                      prev ? { ...prev, country: event.target.value } : prev,
                    )
                  }
                />
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
                onClick={() => setSelectedProvider(null)}
                type="button"
              >
                Cancel
              </button>
              <button
                className="rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white"
                onClick={updateProviderDetails}
                type="button"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
