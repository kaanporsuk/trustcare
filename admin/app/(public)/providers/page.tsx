import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";

interface Provider {
  id: string;
  name: string;
  specialty: string;
  city: string;
  country: string;
  rating_overall?: number;
  review_count: number;
  slug: string;
  is_claimed: boolean;
}

export default async function ProvidersIndexPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string }>;
}) {
  const { q: query, page: pageParam } = await searchParams;
  const currentPage = parseInt(pageParam || "1", 10);
  const perPage = 20;
  const offset = (currentPage - 1) * perPage;

  const supabase = createSupabaseServerClient();

  // Build the query
  let queryBuilder = supabase
    .from("providers")
    .select("id, name, specialty, city, country, rating_overall, review_count, slug, is_claimed", {
      count: "exact",
    })
    .order("review_count", { ascending: false });

  // Add search filter if query exists
  if (query) {
    queryBuilder = queryBuilder.or(
      `name.ilike.%${query}%,specialty.ilike.%${query}%,city.ilike.%${query}%`
    );
  }

  // Add pagination
  queryBuilder = queryBuilder.range(offset, offset + perPage - 1);

  const { data: providers, count, error } = await queryBuilder;

  const totalPages = count ? Math.ceil(count / perPage) : 0;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      {/* Header */}
      <div className="text-center mb-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Find Healthcare Providers
        </h1>
        <p className="text-lg text-gray-600">
          Browse verified healthcare professionals and read patient reviews
        </p>
      </div>

      {/* Search Bar */}
      <form action="/providers" method="get" className="mb-8">
        <div className="max-w-2xl mx-auto">
          <div className="relative">
            <input
              type="text"
              name="q"
              defaultValue={query}
              placeholder="Search by name, specialty, or city..."
              className="w-full px-4 py-3 pl-12 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#0055FF] focus:border-transparent"
            />
            <svg
              className="absolute left-4 top-3.5 w-5 h-5 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>
        </div>
      </form>

      {/* Results Count */}
      {query && (
        <div className="mb-6">
          <p className="text-gray-600">
            {count || 0} {count === 1 ? "result" : "results"} for &quot;{query}&quot;
          </p>
        </div>
      )}

      {/* Provider Grid */}
      {providers && providers.length > 0 ? (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
            {providers.map((provider: Provider) => (
              <Link
                key={provider.id}
                href={`/provider/${provider.slug}`}
                className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6 border border-gray-200"
              >
                <div className="flex items-start justify-between mb-3">
                  <h3 className="text-lg font-semibold text-gray-900 flex-1">
                    {provider.name}
                  </h3>
                  {provider.is_claimed && (
                    <svg
                      className="w-5 h-5 text-[#34C759] flex-shrink-0 ml-2"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  )}
                </div>

                <p className="text-sm text-[#0055FF] font-medium mb-2">
                  {provider.specialty}
                </p>

                <p className="text-sm text-gray-600 mb-4">
                  {provider.city}, {provider.country}
                </p>

                <div className="flex items-center justify-between pt-4 border-t border-gray-200">
                  <div className="flex items-center gap-1">
                    <svg
                      className="w-5 h-5 fill-[#FFCC00]"
                      viewBox="0 0 20 20"
                    >
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                    <span className="text-sm font-medium text-gray-900">
                      {(provider.rating_overall || 0).toFixed(1)}
                    </span>
                  </div>
                  <span className="text-sm text-gray-600">
                    {provider.review_count}{" "}
                    {provider.review_count === 1 ? "review" : "reviews"}
                  </span>
                </div>
              </Link>
            ))}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center gap-2">
              {currentPage > 1 && (
                <Link
                  href={`/providers?${new URLSearchParams({
                    ...(query && { q: query }),
                    page: (currentPage - 1).toString(),
                  })}`}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Previous
                </Link>
              )}

              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                const pageNum = currentPage - 2 + i;
                if (pageNum < 1 || pageNum > totalPages) return null;

                return (
                  <Link
                    key={pageNum}
                    href={`/providers?${new URLSearchParams({
                      ...(query && { q: query }),
                      page: pageNum.toString(),
                    })}`}
                    className={`px-4 py-2 border rounded-lg ${
                      pageNum === currentPage
                        ? "bg-[#0055FF] text-white border-[#0055FF]"
                        : "border-gray-300 hover:bg-gray-50"
                    }`}
                  >
                    {pageNum}
                  </Link>
                );
              })}

              {currentPage < totalPages && (
                <Link
                  href={`/providers?${new URLSearchParams({
                    ...(query && { q: query }),
                    page: (currentPage + 1).toString(),
                  })}`}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Next
                </Link>
              )}
            </div>
          )}
        </>
      ) : (
        <div className="text-center py-12">
          <svg
            className="w-16 h-16 text-gray-400 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            No providers found
          </h3>
          <p className="text-gray-600">
            Try adjusting your search or browse all providers
          </p>
        </div>
      )}

      {/* Download CTA */}
      <div className="mt-16 bg-gradient-to-br from-[#0055FF] to-[#4D88FF] rounded-lg shadow-lg p-8 text-center text-white">
        <h2 className="text-2xl font-bold mb-3">
          Get the TrustCare App
        </h2>
        <p className="text-white text-opacity-90 mb-6">
          Search providers, read reviews, and book appointments on the go
        </p>
        <a
          href="https://apps.apple.com/app/trustcare"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block px-8 py-4 bg-white text-[#0055FF] font-bold rounded-lg hover:bg-gray-100 transition-colors"
        >
          Download Now
        </a>
      </div>
    </div>
  );
}
