import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

declare const Deno: {
  env: {
    get: (key: string) => string | undefined;
  };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

type RehberRequest = {
  session_id?: string;
  messages?: ChatMessage[];
};

type RehberResponse = {
  message: string;
  recommended_specialties: string[] | null;
  is_emergency: boolean;
  is_rate_limited?: boolean;
  is_fallback?: boolean;
};

const RATE_LIMIT_WINDOW_HOURS = 1;
const RATE_LIMIT_MAX_MESSAGES = 30;

const EMERGENCY_KEYWORDS = [
  "chest pain",
  "can't breathe",
  "difficulty breathing",
  "heart attack",
  "stroke",
  "severe bleeding",
  "unconscious",
  "overdose",
  "suicidal",
  "göğüs ağrısı",
  "nefes alamıyorum",
  "kalp krizi",
  "intihar",
];

const SYSTEM_PROMPT = `Sen TrustCare Rehber, Türkiye'de bir sağlık bilgilendirme asistanısın.
SEN DOKTOR DEĞİLSİN. TEŞHİS KOYAMAZSIN. REÇETE YAZAMAZSIN. TEST SONUCU YORUMLAYAMAZSIN.

GÖREV: Kullanıcının belirtilerini dinle, en fazla 2 açıklayıcı soru sor, ardından hangi tıp uzmanlığının bu belirtileri değerlendireceğini öner.

ACİL DURUM KURALI: Kullanıcı şunlardan birini tarif ederse — göğüs ağrısı, nefes alamama, ciddi kanama, bilinç kaybı, felç belirtileri, intihar düşüncesi, kalp krizi — SADECE şu yanıtı ver: [EMERGENCY_TRIGGER_112]

ŞİDDET DERECELENDİRME KURALI: Her yönlendirmede şiddete göre ayrım yap:
- Eğer ateş, şiddetli ağrı veya hızlı kötüleşme varsa: "Bu belirtiler acil değerlendirme gerektirebilir. Acil servise gitmenizi öneririz."
- Aksi halde: "Bu belirtiler genellikle [Uzmanlık Alanı] tarafından değerlendirilir."

TÜRKÇE KONUŞMA DİLİ KURALI: Kullanıcılar tıbbi terim yerine günlük dil kullanabilir. Örnekler:
- "Başım dönüyor" → Nöroloji, Kardiyoloji veya KBB olabilir, soru sor
- "Boğazımda yanma" → Gastroenteroloji veya KBB olabilir, soru sor
- "Belim ağrıyor" → Ortopedi, Nöroloji veya Fizik Tedavi olabilir, soru sor
Belirsiz durumlarda MUTLAKA açıklayıcı soru sor.

KULLANILMAMASI GEREKEN KELİMELER: Tanı, teşhis, hastalık, tedavi planı.
KULLANILMASI GEREKEN KELİMELER: Değerlendirme, inceleme, konsültasyon, yönlendirme.

YANIT FORMATI ZORUNLU KURALI:
1) İlk bölümde kullanıcıya doğal ve lokalize (kullanıcının dilinde) metin ver.
2) Hemen ardından AYRI bir fenced JSON bloğu ver. JSON bloğu aşağıdaki şemaya birebir uymalı:
\`\`\`json
{
  "recommended_specialty_ids": ["SPEC_ENT_OTOLARYNGOLOGY"],
  "urgency": "low",
  "follow_up_questions": ["Semptomlar ne zamandır var?"]
}
\`\`\`

JSON KURALLARI:
- recommended_specialty_ids: yalnızca canonical ID döndür (SPEC_ ile başlamalı), en fazla 3 adet.
- urgency: sadece şu değerlerden biri olmalı: low, medium, high, emergency.
- follow_up_questions: 0-2 kısa soru.
- JSON dışında doğal metin olabilir; ama JSON bloğu mutlaka tek ve geçerli olmalı.
- Eğer yeterli bilgi yoksa recommended_specialty_ids boş dizi olabilir.

Kullanıcı İngilizce yazarsa İngilizce yanıt ver, Türkçe yazarsa Türkçe yanıt ver.
Önerdiğin canonical specialty ID'leri TrustCare taxonomy yapısına uygun üret.`;

const ALLOWED_SPECIALTIES = new Set([
  "General Practice",
  "Family Medicine",
  "Internal Medicine",
  "Pediatrics",
  "Cardiology",
  "Dermatology",
  "Neurology",
  "Oncology",
  "Obstetrics & Gynecology",
  "General Dentistry",
  "Orthodontics",
  "Ophthalmology",
  "ENT / Otolaryngology",
  "Psychiatry",
  "Psychology / Therapy",
  "Urology",
  "Physical Therapy / Physiotherapy",
  "Aesthetic Medicine",
  "Emergency Medicine",
  "Pharmacy",
]);

function extractTextFromAnthropic(data: any): string {
  if (!data?.content || !Array.isArray(data.content)) {
    return "";
  }

  return data.content
    .filter((item: any) => item?.type === "text")
    .map((item: any) => item?.text ?? "")
    .join("\n")
    .trim();
}

function tryParseStructuredJson(raw: string): RehberResponse | null {
  const text = raw.trim();
  if (!text) return null;

  try {
    const parsed = JSON.parse(text);
    return normalizeResponse(parsed);
  } catch {
    const firstBrace = text.indexOf("{");
    const lastBrace = text.lastIndexOf("}");

    if (firstBrace >= 0 && lastBrace > firstBrace) {
      const jsonCandidate = text.slice(firstBrace, lastBrace + 1);
      try {
        const parsed = JSON.parse(jsonCandidate);
        return normalizeResponse(parsed);
      } catch {
        return null;
      }
    }
    return null;
  }
}

function normalizeResponse(parsed: any): RehberResponse {
  const isEmergency = Boolean(parsed?.is_emergency);
  const message = typeof parsed?.message === "string"
    ? parsed.message.trim()
    : "Yanıt oluşturulamadı. Lütfen tekrar deneyin.";

  let specialties: string[] | null = null;
  if (Array.isArray(parsed?.recommended_specialties)) {
    const normalizedSpecialties = parsed.recommended_specialties
      .filter((item: unknown): item is string => typeof item === "string")
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0)
      .filter((item: string) => ALLOWED_SPECIALTIES.has(item))
      .slice(0, 2);

    if (normalizedSpecialties.length === 0) {
      specialties = null;
    } else {
      specialties = normalizedSpecialties;
    }
  }

  return {
    message,
    recommended_specialties: specialties,
    is_emergency: isEmergency,
    is_rate_limited: Boolean(parsed?.is_rate_limited),
    is_fallback: Boolean(parsed?.is_fallback),
  };
}

function base64UrlDecode(input: string): string {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padding = normalized.length % 4;
  const withPadding = padding === 0 ? normalized : normalized + "=".repeat(4 - padding);
  return atob(withPadding);
}

function extractUserIdFromJwt(authHeader: string | null): string | null {
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }

  const token = authHeader.slice("Bearer ".length).trim();
  const parts = token.split(".");
  if (parts.length < 2) {
    return null;
  }

  try {
    const payloadText = base64UrlDecode(parts[1]);
    const payload = JSON.parse(payloadText);
    if (typeof payload?.sub === "string" && payload.sub.length > 0) {
      return payload.sub;
    }
    return null;
  } catch {
    return null;
  }
}

function normalizeForMatch(text: string): string {
  return text
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function containsEmergencyKeyword(text: string): boolean {
  const normalizedText = normalizeForMatch(text);
  return EMERGENCY_KEYWORDS.some((keyword) => normalizedText.includes(normalizeForMatch(keyword)));
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: "Missing Supabase configuration" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!anthropicApiKey) {
      return new Response(JSON.stringify({ error: "Missing ANTHROPIC_API_KEY" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = (await req.json()) as RehberRequest;
    const messages = Array.isArray(body.messages)
      ? body.messages.filter((msg) => msg && typeof msg.content === "string" && (msg.role === "user" || msg.role === "assistant"))
      : [];

    if (messages.length === 0) {
      return new Response(JSON.stringify({ error: "messages is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const latestUserMessage = [...messages].reverse().find((msg) => msg.role === "user")?.content ?? "";
    const emergencyBypass = containsEmergencyKeyword(latestUserMessage);

    const userId = extractUserIdFromJwt(req.headers.get("Authorization"));
    if (!userId) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    if (!emergencyBypass) {
      const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_HOURS * 60 * 60 * 1000).toISOString();

      const { count, error: rateLimitError } = await supabase
        .from("rehber_messages")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId)
        .gte("created_at", windowStart);

      if (rateLimitError) {
        console.error("Failed to evaluate rate limit", rateLimitError);
      } else if ((count ?? 0) >= RATE_LIMIT_MAX_MESSAGES) {
        const rateLimitedResponse: RehberResponse = {
          message:
            "You've reached the message limit. Please wait a bit before sending more messages. If you're experiencing a medical emergency, please call 112 immediately.",
          recommended_specialties: null,
          is_emergency: false,
          is_rate_limited: true,
        };

        return new Response(JSON.stringify(rateLimitedResponse), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    let rawText = "";
    try {
      const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": anthropicApiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-3-5-sonnet-20241022",
          max_tokens: 700,
          temperature: 0.2,
          system: SYSTEM_PROMPT,
          messages: messages.map((msg) => ({
            role: msg.role,
            content: msg.content,
          })),
        }),
      });

      if (!anthropicResponse.ok) {
        const errorText = await anthropicResponse.text();
        throw new Error(`Anthropic error: ${anthropicResponse.status} ${errorText}`);
      }

      const anthropicData = await anthropicResponse.json();
      rawText = extractTextFromAnthropic(anthropicData);
    } catch (llmError) {
      console.error("LLM call failed", llmError);

      const fallbackResponse: RehberResponse = {
        message:
          "I'm temporarily unable to process your request. If you're experiencing a medical emergency, please call 112 immediately. For non-urgent concerns, please try again in a few minutes or use the Discover tab to search for healthcare providers by specialty.",
        recommended_specialties: null,
        is_emergency: false,
        is_fallback: true,
      };

      return new Response(JSON.stringify(fallbackResponse), {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (rawText.includes("[EMERGENCY_TRIGGER_112]")) {
      const emergencyResponse: RehberResponse = {
        message: "[EMERGENCY_TRIGGER_112]",
        recommended_specialties: null,
        is_emergency: true,
      };

      return new Response(JSON.stringify(emergencyResponse), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const structured = tryParseStructuredJson(rawText);
    if (structured) {
      return new Response(JSON.stringify(structured), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const fallback: RehberResponse = {
      message: rawText || "Yanıt oluşturulamadı. Lütfen tekrar deneyin.",
      recommended_specialties: null,
      is_emergency: false,
    };

    return new Response(JSON.stringify(fallback), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unexpected server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
