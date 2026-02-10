import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const jsonHeaders = {
  "Content-Type": "application/json",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

Deno.serve(async (req) => {
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse(500, { error: "Missing Supabase configuration" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "Missing Authorization header" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData?.user) {
    return jsonResponse(401, { error: "Invalid token" });
  }

  const userId = userData.user.id;
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const [
    profile,
    reviews,
    reviewMedia,
    reviewVotes,
    consentRecords,
    userEvents,
  ] = await Promise.all([
    adminClient.from("profiles").select().eq("id", userId).maybeSingle(),
    adminClient.from("reviews").select().eq("user_id", userId),
    adminClient.from("review_media").select().eq("user_id", userId),
    adminClient.from("review_votes").select().eq("user_id", userId),
    adminClient.from("consent_records").select().eq("user_id", userId),
    adminClient.from("user_events").select().eq("user_id", userId),
  ]);

  const exportPayload = {
    profile: profile.data,
    reviews: reviews.data ?? [],
    review_media: reviewMedia.data ?? [],
    review_votes: reviewVotes.data ?? [],
    consent_records: consentRecords.data ?? [],
    user_events: userEvents.data ?? [],
  };

  return new Response(JSON.stringify(exportPayload, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Content-Disposition": "attachment; filename=trustcare-export.json",
    },
  });
});
