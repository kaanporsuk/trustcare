"use client";

import { useEffect, useMemo, useState } from "react";
import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import Badge from "@/components/Badge";

const PAGE_SIZE = 24;

type MediaRow = {
  id: string;
  review_id?: string | null;
  url?: string | null;
  media_type?: string | null;
  content_status?: string | null;
  created_at?: string | null;
  uploader?: { full_name?: string } | null;
};

export default function MediaPage() {
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);
  const [media, setMedia] = useState<MediaRow[]>([]);
  const [filter, setFilter] = useState("all");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const loadMedia = async () => {
    setIsLoading(true);
    let query = supabase
      .from("review_media")
      .select(
        "id, review_id, url, media_type, content_status, created_at, uploader:profiles(full_name)",
        { count: "exact" },
      )
      .order("created_at", { ascending: false })
      .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);

    if (filter === "images") {
      query = query.eq("media_type", "image");
    }
    if (filter === "videos") {
      query = query.eq("media_type", "video");
    }
    if (filter === "flagged") {
      query = query.eq("content_status", "flagged");
    }

    const { data, count } = await query;
    const normalized = (data ?? []).map((item) => ({
      ...item,
      uploader: Array.isArray(item.uploader) ? item.uploader[0] : item.uploader,
    }));
    setMedia(normalized);
    setTotal(count ?? 0);
    setIsLoading(false);
  };

  useEffect(() => {
    loadMedia();
  }, [page, filter]);

  const updateStatus = async (mediaId: string, status: string) => {
    await supabase
      .from("review_media")
      .update({ content_status: status })
      .eq("id", mediaId);
    await loadMedia();
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Media</h1>
        <p className="mt-1 text-sm text-gray-500">
          Moderate uploaded review images and videos.
        </p>
      </div>

      <div className="flex flex-wrap gap-3 rounded-xl bg-white p-4 shadow-sm">
        <select
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
          value={filter}
          onChange={(event) => {
            setPage(1);
            setFilter(event.target.value);
          }}
        >
          <option value="all">All Media</option>
          <option value="images">Images</option>
          <option value="videos">Videos</option>
          <option value="flagged">Flagged</option>
        </select>
      </div>

      <div className="grid gap-4 md:grid-cols-3 xl:grid-cols-4">
        {media.map((item) => {
          const isVideo = item.media_type === "video";
          return (
            <div key={item.id} className="rounded-xl bg-white p-3 shadow-sm">
              <div className="h-36 overflow-hidden rounded-lg bg-gray-100">
                {isVideo ? (
                  <video src={item.url ?? ""} className="h-full w-full" />
                ) : (
                  <img
                    src={item.url ?? ""}
                    alt="Review media"
                    className="h-full w-full object-cover"
                  />
                )}
              </div>
              <div className="mt-3 space-y-1 text-xs text-gray-500">
                <p className="text-sm font-semibold text-gray-900">
                  {item.uploader?.full_name ?? "-"}
                </p>
                <p>Review: {item.review_id?.slice(0, 8) ?? "-"}</p>
                <p>
                  {item.created_at
                    ? new Date(item.created_at).toLocaleDateString()
                    : "-"}
                </p>
              </div>
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <Badge label={item.content_status ?? "pending"} tone={item.content_status ?? "pending"} />
                <button
                  className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                  onClick={() => updateStatus(item.id, "flagged")}
                  type="button"
                >
                  Flag
                </button>
                <button
                  className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                  onClick={() => updateStatus(item.id, "removed")}
                  type="button"
                >
                  Remove
                </button>
                <button
                  className="rounded-lg border border-gray-200 px-2 py-1 text-xs"
                  onClick={() => updateStatus(item.id, "approved")}
                  type="button"
                >
                  Approve
                </button>
              </div>
            </div>
          );
        })}
        {isLoading ? (
          <div className="col-span-full rounded-xl bg-white p-6 text-center text-sm text-gray-500 shadow-sm">
            Loading media...
          </div>
        ) : null}
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
    </div>
  );
}
