"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";

const navItems = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/reviews", label: "Reviews" },
  { href: "/providers", label: "Providers" },
  { href: "/claims", label: "Claims" },
  { href: "/users", label: "Users" },
  { href: "/media", label: "Media" },
  { href: "/settings", label: "Settings" },
];

export default function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [adminName, setAdminName] = useState("Admin");

  useEffect(() => {
    const loadUser = async () => {
      const { data } = await supabase.auth.getUser();
      const email = data.user?.email;
      if (email) {
        setAdminName(email);
      }
    };

    loadUser();
  }, [supabase]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.replace("/login");
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="lg:hidden">
        <div className="flex items-center justify-between border-b border-gray-200 bg-white px-4 py-3">
          <button
            className="rounded-md border border-gray-200 px-3 py-2 text-sm font-medium"
            onClick={() => setMobileOpen(true)}
            type="button"
          >
            Menu
          </button>
          <span className="text-sm font-semibold text-gray-900">
            TrustCare Admin
          </span>
        </div>
      </div>

      <div className="flex">
        <aside
          className={`fixed inset-y-0 left-0 z-30 w-60 transform bg-gray-900 text-gray-100 transition lg:static lg:translate-x-0 ${
            mobileOpen ? "translate-x-0" : "-translate-x-full"
          }`}
        >
          <div className="flex h-full flex-col px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600 text-sm font-semibold">
                  TC
                </div>
                <div>
                  <p className="text-sm font-semibold">TrustCare</p>
                  <p className="text-xs text-gray-400">Admin Panel</p>
                </div>
              </div>
              <button
                className="rounded-md border border-gray-700 px-2 py-1 text-xs lg:hidden"
                onClick={() => setMobileOpen(false)}
                type="button"
              >
                Close
              </button>
            </div>

            <nav className="mt-8 space-y-1">
              {navItems.map((item) => {
                const isActive = pathname === item.href;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`flex items-center justify-between rounded-lg px-3 py-2 text-sm font-medium transition ${
                      isActive
                        ? "bg-blue-600 text-white"
                        : "text-gray-300 hover:bg-gray-800 hover:text-white"
                    }`}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </nav>

            <div className="mt-auto rounded-xl bg-gray-800 p-4">
              <p className="text-xs uppercase text-gray-400">Signed in</p>
              <p className="mt-1 text-sm font-semibold text-white">
                {adminName}
              </p>
              <button
                onClick={handleLogout}
                type="button"
                className="mt-4 w-full rounded-lg border border-gray-600 px-3 py-2 text-xs font-semibold text-gray-100 transition hover:border-gray-400"
              >
                Log Out
              </button>
            </div>
          </div>
        </aside>

        {mobileOpen ? (
          <div
            className="fixed inset-0 z-20 bg-black/40 lg:hidden"
            onClick={() => setMobileOpen(false)}
          />
        ) : null}

        <main className="min-h-screen w-full px-6 py-8 lg:ml-60">
          {children}
        </main>
      </div>
    </div>
  );
}
