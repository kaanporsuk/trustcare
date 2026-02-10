"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

export default function SettingsPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [flags, setFlags] = useState<any[]>([]);
  const [admins, setAdmins] = useState<any[]>([]);
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteRole, setInviteRole] = useState("admin");
  const [systemCounts, setSystemCounts] = useState({
    profiles: 0,
    reviews: 0,
    providers: 0,
  });

  const loadSettings = async () => {
    const { data: flagsData } = await supabase
      .from("feature_flags")
      .select("id, name, is_enabled, rollout_percentage")
      .order("name", { ascending: true });

    const { data: adminData } = await supabase
      .from("user_roles")
      .select("id, role, user:profiles(full_name, email)")
      .in("role", ["admin", "moderator"]);

    const [profilesCount, reviewsCount, providersCount] = await Promise.all([
      supabase.from("profiles").select("id", { count: "exact", head: true }),
      supabase.from("reviews").select("id", { count: "exact", head: true }),
      supabase.from("providers").select("id", { count: "exact", head: true }),
    ]);

    setFlags(flagsData ?? []);
    setAdmins(adminData ?? []);
    setSystemCounts({
      profiles: profilesCount.count ?? 0,
      reviews: reviewsCount.count ?? 0,
      providers: providersCount.count ?? 0,
    });
  };

  useEffect(() => {
    loadSettings();
  }, []);

  const toggleFlag = async (flagId: string, value: boolean) => {
    await supabase
      .from("feature_flags")
      .update({ is_enabled: value })
      .eq("id", flagId);
    await loadSettings();
  };

  const updateRollout = async (flagId: string, value: number) => {
    await supabase
      .from("feature_flags")
      .update({ rollout_percentage: value })
      .eq("id", flagId);
    await loadSettings();
  };

  const inviteAdmin = async () => {
    if (!inviteEmail.trim()) return;
    const { data: profile } = await supabase
      .from("profiles")
      .select("id")
      .eq("email", inviteEmail.trim())
      .single();

    if (!profile?.id) return;
    await supabase.from("user_roles").insert({
      user_id: profile.id,
      role: inviteRole,
    });
    setInviteEmail("");
    await loadSettings();
  };

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Settings</h1>
        <p className="mt-1 text-sm text-gray-500">
          Feature flags, admin access, and system info.
        </p>
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900">Feature Flags</h2>
        <div className="mt-4 overflow-hidden rounded-lg border border-gray-200">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 text-xs uppercase text-gray-400">
              <tr>
                <th className="px-4 py-3">Flag</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Rollout %</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {flags.map((flag) => (
                <tr key={flag.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{flag.name}</td>
                  <td className="px-4 py-3">
                    <label className="flex items-center gap-2 text-sm">
                      <input
                        type="checkbox"
                        checked={flag.is_enabled}
                        onChange={(event) =>
                          toggleFlag(flag.id, event.target.checked)
                        }
                      />
                      <Badge
                        label={flag.is_enabled ? "Enabled" : "Disabled"}
                        tone={flag.is_enabled ? "active" : "removed"}
                      />
                    </label>
                  </td>
                  <td className="px-4 py-3">
                    <input
                      type="number"
                      min={0}
                      max={100}
                      className="w-24 rounded-lg border border-gray-200 px-2 py-1 text-sm"
                      value={flag.rollout_percentage ?? 0}
                      onChange={(event) =>
                        updateRollout(flag.id, Number(event.target.value))
                      }
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900">Admin Management</h2>
        <div className="mt-4 flex flex-wrap gap-3">
          <input
            className="flex-1 rounded-lg border border-gray-200 px-3 py-2 text-sm"
            placeholder="Admin email"
            value={inviteEmail}
            onChange={(event) => setInviteEmail(event.target.value)}
          />
          <select
            className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
            value={inviteRole}
            onChange={(event) => setInviteRole(event.target.value)}
          >
            <option value="admin">Admin</option>
            <option value="moderator">Moderator</option>
          </select>
          <button
            className="rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white"
            onClick={inviteAdmin}
            type="button"
          >
            Invite Admin
          </button>
        </div>
        <div className="mt-4 overflow-hidden rounded-lg border border-gray-200">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 text-xs uppercase text-gray-400">
              <tr>
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Email</th>
                <th className="px-4 py-3">Role</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {admins.map((admin) => (
                <tr key={admin.id}>
                  <td className="px-4 py-3 text-gray-700">
                    {admin.user?.full_name ?? "-"}
                  </td>
                  <td className="px-4 py-3 text-gray-700">
                    {admin.user?.email ?? "-"}
                  </td>
                  <td className="px-4 py-3">
                    <Badge label={admin.role} tone="active" />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900">System Info</h2>
        <div className="mt-4 grid gap-4 md:grid-cols-3">
          <div className="rounded-lg bg-gray-50 p-4">
            <p className="text-xs uppercase text-gray-400">Supabase URL</p>
            <p className="mt-2 text-sm text-gray-700">
              {process.env.NEXT_PUBLIC_SUPABASE_URL ?? "-"}
            </p>
          </div>
          <div className="rounded-lg bg-gray-50 p-4">
            <p className="text-xs uppercase text-gray-400">Profiles</p>
            <p className="mt-2 text-2xl font-semibold text-gray-900">
              {systemCounts.profiles}
            </p>
          </div>
          <div className="rounded-lg bg-gray-50 p-4">
            <p className="text-xs uppercase text-gray-400">Reviews</p>
            <p className="mt-2 text-2xl font-semibold text-gray-900">
              {systemCounts.reviews}
            </p>
          </div>
          <div className="rounded-lg bg-gray-50 p-4">
            <p className="text-xs uppercase text-gray-400">Providers</p>
            <p className="mt-2 text-2xl font-semibold text-gray-900">
              {systemCounts.providers}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
