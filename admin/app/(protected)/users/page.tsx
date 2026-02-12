"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

const PAGE_SIZE = 20;

type UserRow = {
  id: string;
  full_name?: string | null;
  email?: string | null;
  avatar_url?: string | null;
  phone?: string | null;
  country_code?: string | null;
  preferred_language?: string | null;
  created_at?: string | null;
  deleted_at?: string | null;
};

export default function UsersPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState("");
  const [selectedUser, setSelectedUser] = useState<UserRow | null>(null);
  const [userReviews, setUserReviews] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const loadUsers = async () => {
    setIsLoading(true);
    let query = supabase
      .from("profiles")
      .select(
        "id, full_name, email, avatar_url, phone, country_code, preferred_language, created_at, deleted_at",
        { count: "exact" },
      )
      .order("created_at", { ascending: false })
      .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

    if (search.trim()) {
      query = query.or(
        `full_name.ilike.%${search.trim()}%,phone.ilike.%${search.trim()}%,email.ilike.%${search.trim()}%`,
      );
    }

    const { data, count } = await query;
    setUsers(data ?? []);
    setTotal(count ?? 0);
    setIsLoading(false);
  };

  useEffect(() => {
    loadUsers();
  }, [page, search]);

  const loadUserDetail = async (user: UserRow) => {
    setSelectedUser(user);
    const { data } = await supabase
      .from("reviews")
      .select("id, rating_overall, status, created_at, provider:providers(name)")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false });
    setUserReviews(data ?? []);
  };

  const suspendUser = async (userId: string) => {
    await supabase
      .from("profiles")
      .update({ deleted_at: new Date().toISOString() })
      .eq("id", userId);
    await loadUsers();
  };

  const banUser = async (userId: string) => {
    await supabase
      .from("profiles")
      .update({ deleted_at: new Date().toISOString() })
      .eq("id", userId);
    await loadUsers();
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Users</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage user accounts and reviews.
        </p>
      </div>

      <div className="flex flex-wrap gap-3 rounded-xl bg-white p-4 shadow-sm">
        <input
          className="flex-1 rounded-lg border border-gray-200 px-3 py-2 text-sm"
          placeholder="Search by name or phone"
          value={search}
          onChange={(event) => {
            setPage(1);
            setSearch(event.target.value);
          }}
        />
      </div>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-400">
            <tr>
              <th className="px-4 py-3">ID</th>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Phone</th>
              <th className="px-4 py-3">Country</th>
              <th className="px-4 py-3">Language</th>
              <th className="px-4 py-3">Joined</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-gray-500">
                  {user.id.slice(0, 8)}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {user.full_name ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-700">
                  {user.phone ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {user.country_code ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {user.preferred_language ?? "-"}
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {user.created_at
                    ? new Date(user.created_at).toLocaleDateString()
                    : "-"}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-2">
                    <button
                      className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                      onClick={() => loadUserDetail(user)}
                      type="button"
                    >
                      View
                    </button>
                    <button
                      className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                      onClick={() => suspendUser(user.id)}
                      type="button"
                    >
                      Suspend
                    </button>
                    <button
                      className="rounded-lg border border-rose-200 px-2 py-1 text-xs text-rose-600"
                      onClick={() => banUser(user.id)}
                      type="button"
                    >
                      Ban
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {isLoading ? (
              <tr>
                <td className="px-4 py-6 text-center text-sm text-gray-500" colSpan={7}>
                  Loading users...
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

      {selectedUser ? (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-3xl rounded-2xl bg-white p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900">
                User Profile
              </h2>
              <button
                className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                onClick={() => setSelectedUser(null)}
                type="button"
              >
                Close
              </button>
            </div>
            <div className="mt-4 grid gap-4 md:grid-cols-2">
              <div className="rounded-xl bg-gray-50 p-4 text-sm">
                <p className="text-xs uppercase text-gray-400">Name</p>
                <p className="mt-2 font-semibold text-gray-900">
                  {selectedUser.full_name ?? "-"}
                </p>
                <p className="mt-2 text-xs text-gray-500">
                  {selectedUser.phone ?? "-"}
                </p>
              </div>
              <div className="rounded-xl bg-gray-50 p-4 text-sm">
                <p className="text-xs uppercase text-gray-400">Country</p>
                <p className="mt-2 font-semibold text-gray-900">
                  {selectedUser.country_code ?? "-"}
                </p>
                <p className="mt-2 text-xs text-gray-500">
                  Language: {selectedUser.preferred_language ?? "-"}
                </p>
                <p className="mt-2 text-xs text-gray-500">
                  Joined: {selectedUser.created_at
                    ? new Date(selectedUser.created_at).toLocaleDateString()
                    : "-"}
                </p>
              </div>
            </div>

            <div className="mt-4">
              <h3 className="text-sm font-semibold text-gray-800">Reviews</h3>
              <div className="mt-2 overflow-hidden rounded-xl border border-gray-200">
                <table className="w-full text-left text-sm">
                  <thead className="bg-gray-50 text-xs uppercase text-gray-400">
                    <tr>
                      <th className="px-3 py-2">Provider</th>
                      <th className="px-3 py-2">Rating</th>
                      <th className="px-3 py-2">Status</th>
                      <th className="px-3 py-2">Date</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {userReviews.map((review) => (
                      <tr key={review.id}>
                        <td className="px-3 py-2 text-gray-700">
                          {review.provider?.name ?? "-"}
                        </td>
                        <td className="px-3 py-2 text-gray-700">
                          {review.rating_overall ?? "-"}
                        </td>
                        <td className="px-3 py-2">
                          <Badge
                            label={review.status ?? "-"}
                            tone={review.status ?? "pending"}
                          />
                        </td>
                        <td className="px-3 py-2 text-gray-500">
                          {review.created_at
                            ? new Date(review.created_at).toLocaleDateString()
                            : "-"}
                        </td>
                      </tr>
                    ))}
                    {userReviews.length === 0 ? (
                      <tr>
                        <td className="px-3 py-3 text-sm text-gray-500" colSpan={4}>
                          No reviews found.
                        </td>
                      </tr>
                    ) : null}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
