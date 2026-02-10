import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type VerificationResult = {
  is_legitimate: boolean;
  confidence: number;
  detected_provider: string | null;
  detected_date: string | null;
  reasoning: string;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const openAiKey = Deno.env.get("OPENAI_API_KEY") ?? "";

const jsonHeaders = {
  "Content-Type": "application/json",
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

async function downloadImage(url: string): Promise<string> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download proof image: ${response.status}`);
  }
  const buffer = await response.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

async function callOpenAI(imageBase64: string): Promise<VerificationResult> {
  if (!openAiKey) {
    throw new Error("Missing OPENAI_API_KEY");
  }

  const payload = {
    model: "gpt-4o-mini",
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "You are a verification assistant. Only respond with valid JSON and no extra text.",
      },
      {
        role: "user",
        content: [
          {
            type: "text",
            text:
              "Analyze this medical document. Is it a legitimate receipt, prescription, or appointment confirmation? Does it contain a date and healthcare provider name? Respond with JSON: { is_legitimate: boolean, confidence: 0-100, detected_provider: string|null, detected_date: string|null, reasoning: string }",
          },
          {
            type: "image_url",
            image_url: {
              url: `data:image/jpeg;base64,${imageBase64}`,
            },
          },
        ],
      },
    ],
  };

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`OpenAI error: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("OpenAI returned empty content");
  }

  return JSON.parse(content) as VerificationResult;
}

async function upsertFailure(
  supabase: ReturnType<typeof createClient>,
  reviewId: string,
  message: string
) {
  const { data: existing } = await supabase
    .from("failed_verifications")
    .select("retry_count")
    .eq("review_id", reviewId)
    .maybeSingle();

  const retryCount = (existing?.retry_count ?? 0) + 1;

  await supabase.from("failed_verifications").upsert(
    {
      review_id: reviewId,
      error_message: message,
      retry_count: retryCount,
      last_attempted_at: new Date().toISOString(),
      resolved: false,
      resolved_by: null,
      resolved_at: null,
    },
    { onConflict: "review_id" }
  );
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(500, { error: "Missing Supabase configuration" });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const expected = `Bearer ${serviceRoleKey}`;
  if (authHeader !== expected) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  let body: { review_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON" });
  }

  if (!body.review_id) {
    return jsonResponse(400, { error: "Missing review_id" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: review, error: reviewError } = await supabase
    .from("reviews")
    .select("id, user_id, proof_image_url")
    .eq("id", body.review_id)
    .maybeSingle();

  if (reviewError || !review) {
    return jsonResponse(404, { error: "Review not found" });
  }

  if (!review.proof_image_url) {
    return jsonResponse(400, { error: "Review has no proof image" });
  }

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    try {
      const imageBase64 = await downloadImage(review.proof_image_url);
      const result = await callOpenAI(imageBase64);

      const confidence = Math.max(0, Math.min(100, result.confidence ?? 0));
      let status = "active";
      let isVerified = false;
      let notificationType = "review_flagged";
      let notificationBody = "Your review could not be verified but is now published.";

      if (confidence >= 80) {
        isVerified = true;
        status = "active";
        notificationType = "review_verified";
        notificationBody = "Your review was verified by our system.";
      } else if (confidence >= 50) {
        isVerified = false;
        status = "pending_verification";
        notificationType = "review_flagged";
        notificationBody = "Your review is pending verification by our team.";
      }

      await supabase
        .from("reviews")
        .update({
          is_verified: isVerified,
          status,
          verification_confidence: confidence,
          verification_reason: result.reasoning,
          verified_at: isVerified ? new Date().toISOString() : null,
        })
        .eq("id", review.id);

      await supabase.from("notifications").insert({
        user_id: review.user_id,
        type: notificationType,
        title: "Review verification",
        body: notificationBody,
        data: {
          review_id: review.id,
          detected_provider: result.detected_provider,
          detected_date: result.detected_date,
        },
      });

      return jsonResponse(200, {
        review_id: review.id,
        is_verified: isVerified,
        status,
        confidence,
      });
    } catch (error) {
      await upsertFailure(supabase, review.id, (error as Error).message);

      if (attempt < 3) {
        await new Promise((resolve) => setTimeout(resolve, 5000));
        continue;
      }

      return jsonResponse(500, { error: "Verification failed" });
    }
  }

  return jsonResponse(500, { error: "Verification failed" });
});
