import { redirect } from "next/navigation";

export default async function ShortProviderPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  redirect(`/provider/${slug}`);
}
