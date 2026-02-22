import "jsr:@supabase/functions-js/edge-runtime.d.ts";

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
};

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

YANIT FORMATI: Her zaman JSON olarak yanıt ver:
{
    "message": "Kullanıcıya gösterilecek Türkçe metin",
    "recommended_specialties": ["Uzmanlık Adı 1", "Uzmanlık Adı 2"] veya null,
    "is_emergency": false
}

Kullanıcı İngilizce yazarsa İngilizce yanıt ver, Türkçe yazarsa Türkçe yanıt ver.
Önerdiğin uzmanlık adları şu listeden olmalı: General Practice, Family Medicine, Internal Medicine, Pediatrics, Cardiology, Dermatology, Neurology, Oncology, Obstetrics & Gynecology, General Dentistry, Orthodontics, Ophthalmology, ENT / Otolaryngology, Psychiatry, Psychology / Therapy, Urology, Physical Therapy / Physiotherapy, Aesthetic Medicine, Emergency Medicine, Pharmacy.`;

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
  };
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
      return new Response(JSON.stringify({ error: `Anthropic error: ${errorText}` }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const anthropicData = await anthropicResponse.json();
    const rawText = extractTextFromAnthropic(anthropicData);

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
