import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import Link from "next/link";
import type { Metadata } from "next";

interface ProviderData {
  id: string;
  name: string;
  specialty: string;
  address: string;
  city: string;
  country: string;
  phone?: string;
  email?: string;
  website?: string;
  description?: string;
  rating_overall?: number;
  review_count: number;
  verified_review_count: number;
  gallery_urls?: string[];
  opening_hours?: Record<string, string>;
  social_links?: Record<string, string>;
  is_claimed: boolean;
  slug: string;
  meta_title?: string;
  meta_description?: string;
  languages?: string[];
  price_level?: number;
}

interface Service {
  id: string;
  name: string;
  description?: string;
  price?: number;
  currency?: string;
  duration_minutes?: number;
  category?: string;
  display_order?: number;
  is_active?: boolean;
}

interface Review {
  id: string;
  rating: number;
  comment?: string;
  is_verified: boolean;
  helpful_count: number;
  created_at: string;
  reviewer_name?: string;
  reviewer_avatar?: string;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const supabase = createSupabaseServerClient();

  const { data: providerResponse } = await supabase.rpc("get_provider_by_slug", {
    provider_slug: slug,
  });

  if (!providerResponse || !providerResponse.provider) {
    return {
      title: "Provider Not Found | TrustCare",
    };
  }

  const p = providerResponse.provider as ProviderData;
  const title =
    p.meta_title || `${p.name} - ${p.specialty} | TrustCare`;
  const description =
    p.meta_description ||
    `Read verified patient reviews for ${p.name}, ${p.specialty} in ${p.city}. ${p.review_count} reviews, rated ${(p.rating_overall || 0).toFixed(1)}/5.`;

  const image = p.gallery_urls?.[0] || "/default-provider.jpg";

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "profile",
      images: [image],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [image],
    },
  };
}

export default async function ProviderProfilePage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const supabase = createSupabaseServerClient();

  // Fetch provider data
  const { data: providerResponse, error: providerError } = await supabase.rpc(
    "get_provider_by_slug",
    { provider_slug: slug }
  );

  if (providerError || !providerResponse) {
    notFound();
  }

  const provider = providerResponse.provider as ProviderData;
  const services = (providerResponse.services || []) as Service[];
  const reviewsData = (providerResponse.reviews || []) as any[];

  if (!provider) {
    notFound();
  }

  // Format reviews
  const formattedReviews: Review[] = reviewsData.map((r: any) => ({
    id: r.id,
    rating: r.rating_overall || 0,
    comment: r.comment,
    is_verified: r.is_verified,
    helpful_count: 0, // Not in the RPC response yet
    created_at: r.created_at,
    reviewer_name: r.reviewer?.full_name || "Anonymous",
    reviewer_avatar: r.reviewer?.avatar_url,
  }));

  const verifiedPercent =
    provider.review_count > 0
      ? Math.round(
          (provider.verified_review_count / provider.review_count) * 100
        )
      : 0;

  return (
    <div className="max-w-7xl mx-auto">
      {/* Hero Section */}
      <div className="relative h-64 md:h-80 bg-gradient-to-br from-[#0055FF] to-[#4D88FF] overflow-hidden">
        {provider.gallery_urls && provider.gallery_urls[0] && (
          <img
            src={provider.gallery_urls[0]}
            alt={provider.name}
            className="absolute inset-0 w-full h-full object-cover"
          />
        )}
        <div className="absolute inset-0 bg-black bg-opacity-40" />
        <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-full flex flex-col justify-end pb-8">
          <div className="flex flex-wrap gap-2 mb-3">
            <span className="px-3 py-1 bg-white rounded-full text-sm font-medium text-gray-900">
              {provider.specialty}
            </span>
            {provider.is_claimed && (
              <span className="px-3 py-1 bg-[#34C759] rounded-full text-sm font-medium text-white flex items-center gap-1">
                <svg
                  className="w-4 h-4"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clipRule="evenodd"
                  />
                </svg>
                Verified Practice
              </span>
            )}
          </div>
          <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">
            {provider.name}
          </h1>
          <p className="text-white text-opacity-90">
            {provider.city}, {provider.country}
          </p>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="flex items-center justify-center gap-1 text-2xl font-bold text-gray-900">
                {(provider.rating_overall || 0).toFixed(1)}
                <svg
                  className="w-6 h-6"
                  fill="#FFCC00"
                  viewBox="0 0 20 20"
                >
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
              </div>
              <p className="text-sm text-gray-600 mt-1">Rating</p>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-gray-900">
                {provider.review_count}
              </div>
              <p className="text-sm text-gray-600 mt-1">Reviews</p>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-[#34C759]">
                {verifiedPercent}%
              </div>
              <p className="text-sm text-gray-600 mt-1">Verified</p>
            </div>
            {provider.price_level && (
              <div className="text-center">
                <div className="text-2xl font-bold text-gray-900">
                  {"€".repeat(provider.price_level)}
                </div>
                <p className="text-sm text-gray-600 mt-1">Price Level</p>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* About Section */}
        {provider.description && (
          <section className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">About</h2>
            <p className="text-gray-700 whitespace-pre-line">
              {provider.description}
            </p>
            {provider.languages && provider.languages.length > 0 && (
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-600 mb-2">
                  Languages:
                </p>
                <div className="flex flex-wrap gap-2">
                  {provider.languages.map((lang) => (
                    <span
                      key={lang}
                      className="px-3 py-1 bg-gray-100 rounded-full text-sm text-gray-700"
                    >
                      {lang}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </section>
        )}

        {/* Contact & Location */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Contact Info */}
          <section className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-4">
              Contact Information
            </h2>
            <div className="space-y-3">
              {provider.phone && (
                <div className="flex items-start gap-3">
                  <svg
                    className="w-5 h-5 text-gray-400 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                    />
                  </svg>
                  <a
                    href={`tel:${provider.phone}`}
                    className="text-[#0055FF] hover:underline"
                  >
                    {provider.phone}
                  </a>
                </div>
              )}
              {provider.email && (
                <div className="flex items-start gap-3">
                  <svg
                    className="w-5 h-5 text-gray-400 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                    />
                  </svg>
                  <a
                    href={`mailto:${provider.email}`}
                    className="text-[#0055FF] hover:underline"
                  >
                    {provider.email}
                  </a>
                </div>
              )}
              {provider.website && (
                <div className="flex items-start gap-3">
                  <svg
                    className="w-5 h-5 text-gray-400 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"
                    />
                  </svg>
                  <a
                    href={provider.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-[#0055FF] hover:underline"
                  >
                    {provider.website.replace(/^https?:\/\//, "")}
                  </a>
                </div>
              )}
              <div className="flex items-start gap-3">
                <svg
                  className="w-5 h-5 text-gray-400 mt-0.5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <p className="text-gray-700">{provider.address}</p>
              </div>
            </div>
          </section>

          {/* Opening Hours */}
          {provider.opening_hours && Object.keys(provider.opening_hours).length > 0 && (
            <section className="bg-white rounded-lg shadow-sm p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">
                Opening Hours
              </h2>
              <div className="space-y-2">
                {[
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday",
                  "Saturday",
                  "Sunday",
                ].map((day) => {
                  const hours = provider.opening_hours?.[day.toLowerCase()];
                  const today = new Date()
                    .toLocaleDateString("en-US", { weekday: "long" });
                  const isToday = day === today;

                  return (
                    <div
                      key={day}
                      className={`flex justify-between py-2 ${
                        isToday
                          ? "bg-[#0055FF] bg-opacity-5 px-3 rounded font-medium"
                          : ""
                      }`}
                    >
                      <span className="text-gray-700">{day}</span>
                      <span
                        className={
                          hours ? "text-gray-900" : "text-gray-400"
                        }
                      >
                        {hours || "Closed"}
                      </span>
                    </div>
                  );
                })}
              </div>
            </section>
          )}
        </div>

        {/* Services & Prices */}
        {services && services.length > 0 && (
          <section className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Services & Prices
            </h2>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="border-b border-gray-200">
                  <tr>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-900">
                      Service
                    </th>
                    <th className="text-left py-3 px-4 text-sm font-semibold text-gray-900">
                      Description
                    </th>
                    <th className="text-right py-3 px-4 text-sm font-semibold text-gray-900">
                      Price
                    </th>
                    <th className="text-right py-3 px-4 text-sm font-semibold text-gray-900">
                      Duration
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {services.map((service: Service) => (
                    <tr key={service.id}>
                      <td className="py-3 px-4 text-sm font-medium text-gray-900">
                        {service.name}
                      </td>
                      <td className="py-3 px-4 text-sm text-gray-600">
                        {service.description || "-"}
                      </td>
                      <td className="py-3 px-4 text-sm text-right text-gray-900">
                        {service.price
                          ? `${service.currency || "€"}${service.price}`
                          : "-"}
                      </td>
                      <td className="py-3 px-4 text-sm text-right text-gray-600">
                        {service.duration_minutes
                          ? `${service.duration_minutes} min`
                          : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* Reviews Section */}
        {formattedReviews.length > 0 && (
          <section className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-900">
                Patient Reviews ({provider.review_count})
              </h2>
            </div>

            {/* Rating Visualization */}
            <div className="flex items-center gap-6 mb-6 pb-6 border-b border-gray-200">
              <div className="text-center">
                <div className="text-5xl font-bold text-gray-900">
                  {(provider.rating_overall || 0).toFixed(1)}
                </div>
                <div className="flex justify-center mt-2">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <svg
                      key={star}
                      className={`w-5 h-5 ${
                        star <= Math.round(provider.rating_overall || 0)
                          ? "fill-[#FFCC00]"
                          : "fill-gray-300"
                      }`}
                      viewBox="0 0 20 20"
                    >
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                </div>
                <p className="text-sm text-gray-600 mt-2">
                  {provider.review_count} reviews
                </p>
              </div>
            </div>

            {/* Review List */}
            <div className="space-y-6">
              {formattedReviews.map((review) => (
                <div key={review.id} className="border-b border-gray-200 pb-6 last:border-0">
                  <div className="flex items-start gap-4">
                    {/* Avatar */}
                    <div className="w-10 h-10 rounded-full bg-[#0055FF] flex items-center justify-center text-white font-semibold flex-shrink-0">
                      {review.reviewer_name?.[0]?.toUpperCase() || "A"}
                    </div>

                    {/* Review Content */}
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="font-medium text-gray-900">
                          {review.reviewer_name}
                        </span>
                        {review.is_verified && (
                          <span className="px-2 py-0.5 bg-[#34C759] bg-opacity-10 text-[#34C759] text-xs font-medium rounded">
                            Verified
                          </span>
                        )}
                      </div>

                      <div className="flex items-center gap-2 mb-2">
                        <div className="flex">
                          {[1, 2, 3, 4, 5].map((star) => (
                            <svg
                              key={star}
                              className={`w-4 h-4 ${
                                star <= review.rating
                                  ? "fill-[#FFCC00]"
                                  : "fill-gray-300"
                              }`}
                              viewBox="0 0 20 20"
                            >
                              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                            </svg>
                          ))}
                        </div>
                        <span className="text-sm text-gray-500">
                          {new Date(review.created_at).toLocaleDateString()}
                        </span>
                      </div>

                      {review.comment && (
                        <p className="text-gray-700 mb-2">{review.comment}</p>
                      )}

                      {review.helpful_count > 0 && (
                        <p className="text-sm text-gray-500">
                          {review.helpful_count} people found this helpful
                        </p>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* CTA to download app */}
            <div className="mt-8 p-6 bg-[#0055FF] bg-opacity-5 rounded-lg text-center">
              <p className="text-gray-700 mb-3">
                Have you visited this provider? Share your experience!
              </p>
              <a
                href="https://apps.apple.com/app/trustcare"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-6 py-3 bg-[#0055FF] text-white font-medium rounded-lg hover:bg-[#4D88FF] transition-colors"
              >
                Download TrustCare to Write a Review
              </a>
            </div>
          </section>
        )}

        {/* Download CTA Card */}
        <section className="bg-gradient-to-br from-[#0055FF] to-[#4D88FF] rounded-lg shadow-lg p-8 text-center text-white">
          <h2 className="text-2xl font-bold mb-3">
            Find Trusted Healthcare Providers Near You
          </h2>
          <p className="text-white text-opacity-90 mb-6">
            Download TrustCare to search, read reviews, and book appointments with verified healthcare professionals.
          </p>
          <a
            href="https://apps.apple.com/app/trustcare"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block px-8 py-4 bg-white text-[#0055FF] font-bold rounded-lg hover:bg-gray-100 transition-colors"
          >
            Download TrustCare
          </a>
        </section>
      </div>
    </div>
  );
}
