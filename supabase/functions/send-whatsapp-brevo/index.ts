/**
 * Supabase Auth Hook – Send OTP via Brevo WhatsApp Business
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *   URL: https://<project-ref>.supabase.co/functions/v1/send-whatsapp-brevo
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   BREVO_API_KEY                  – Your Brevo (Sendinblue) API key
 *   BREVO_WHATSAPP_PHONE_NUMBER_ID – WhatsApp Business phone number ID from Brevo
 *                                    (found in Brevo Dashboard → WhatsApp → Phone numbers)
 *   SEND_SMS_HOOK_SECRET           – Webhook signing secret from the Supabase hook dashboard
 *                                    (full value, e.g. "v1,whsec_<base64>")
 *
 * Optional environment variables:
 *   BREVO_WHATSAPP_TEMPLATE_NAME   – Approved Meta template name (default: "otp_verification")
 *   BREVO_WHATSAPP_TEMPLATE_LANG   – Template language code (default: "fr")
 *
 * Meta template setup (one-time, done in Brevo dashboard):
 *   Template name : otp_verification  (or your chosen name)
 *   Template body : "Votre code de vérification NHTL est : {{1}}. Il expire dans 10 minutes."
 *   Category      : AUTHENTICATION
 *   Language      : French (fr)
 *   The placeholder {{1}} will be replaced by the 6-digit OTP.
 *
 * Brevo WhatsApp API reference:
 *   https://developers.brevo.com/reference/sendwhatsappmessage
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface SMSHookPayload {
  user: {
    id: string;
    phone: string;
  };
  sms: {
    otp: string;
  };
}

/**
 * Verify the Supabase webhook HMAC-SHA256 signature.
 *
 * Supabase sends:   x-supabase-signature: v1=<base64-encoded-HMAC-SHA256>
 * The hook secret stored in the dashboard has the format: v1,whsec_<base64-key>
 *
 * @param rawBody   Raw request body bytes (must be read before JSON.parse).
 * @param sigHeader Value of the x-supabase-signature header.
 * @param secret    Value of the SEND_SMS_HOOK_SECRET environment variable.
 * @returns true if the signature is valid, false otherwise.
 */
async function verifyHookSignature(
  rawBody: Uint8Array,
  sigHeader: string,
  secret: string,
): Promise<boolean> {
  // Expected header format: "v1=<base64>"
  const match = sigHeader.match(/^v1=(.+)$/);
  if (!match) return false;
  const receivedSig = match[1];

  // Secret format from the Supabase dashboard: "v1,whsec_<base64>"
  const secretMatch = secret.match(/^v1,whsec_(.+)$/);
  if (!secretMatch) return false;
  const rawKey = Uint8Array.from(atob(secretMatch[1]), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    rawKey,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign("HMAC", cryptoKey, rawBody);
  const computedSig = btoa(String.fromCharCode(...new Uint8Array(signature)));

  // Constant-time comparison to prevent timing attacks
  if (computedSig.length !== receivedSig.length) return false;
  let diff = 0;
  for (let i = 0; i < computedSig.length; i++) {
    diff |= computedSig.charCodeAt(i) ^ receivedSig.charCodeAt(i);
  }
  return diff === 0;
}

serve(async (req: Request): Promise<Response> => {
  try {
    const rawBody = await req.arrayBuffer();

    // ── Webhook signature verification ─────────────────────────────────────
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
    if (hookSecret) {
      const sigHeader = req.headers.get("x-supabase-signature") ?? "";
      const valid = await verifyHookSignature(
        new Uint8Array(rawBody),
        sigHeader,
        hookSecret,
      );
      if (!valid) {
        console.error("[send-whatsapp-brevo] Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid webhook signature" }),
          { status: 401, headers: { "Content-Type": "application/json" } },
        );
      }
    } else {
      console.warn(
        "[send-whatsapp-brevo] SEND_SMS_HOOK_SECRET is not set – skipping signature verification",
      );
    }
    // ───────────────────────────────────────────────────────────────────────

    const payload: SMSHookPayload = JSON.parse(
      new TextDecoder().decode(rawBody),
    );

    const phone = payload?.user?.phone;
    const otp = payload?.sms?.otp;

    if (!phone || !otp) {
      console.error(
        "[send-whatsapp-brevo] Missing phone or otp in payload",
        payload,
      );
      return new Response(
        JSON.stringify({ error: "Missing phone or otp" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const brevoApiKey = Deno.env.get("BREVO_API_KEY");
    if (!brevoApiKey) {
      console.error("[send-whatsapp-brevo] BREVO_API_KEY env var is not set");
      return new Response(
        JSON.stringify({ error: "BREVO_API_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const phoneNumberId = Deno.env.get("BREVO_WHATSAPP_PHONE_NUMBER_ID");
    if (!phoneNumberId) {
      console.error(
        "[send-whatsapp-brevo] BREVO_WHATSAPP_PHONE_NUMBER_ID env var is not set",
      );
      return new Response(
        JSON.stringify({ error: "BREVO_WHATSAPP_PHONE_NUMBER_ID not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Phone should already be in E.164 format with "+" (enforced by the Flutter client).
    // Log a warning if the "+" is unexpectedly missing so upstream issues are visible.
    if (!phone.startsWith("+")) {
      console.warn(
        `[send-whatsapp-brevo] Phone "${phone}" is missing the '+' prefix. Verify the Flutter client sends full E.164 format.`,
      );
    }
    // WhatsApp expects E.164 without the leading '+'.
    const rawPhone = phone.startsWith("+") ? phone.slice(1) : phone;

    const templateName =
      Deno.env.get("BREVO_WHATSAPP_TEMPLATE_NAME") ?? "otp_verification";
    const templateLang =
      Deno.env.get("BREVO_WHATSAPP_TEMPLATE_LANG") ?? "fr";

    console.log(
      `[send-whatsapp-brevo] Sending OTP to +${rawPhone} via WhatsApp template="${templateName}" lang="${templateLang}"`,
    );

    // Brevo WhatsApp sendMessage body.
    // The approved Meta template must contain a single body variable {{1}}
    // which will receive the OTP code.
    const brevoRes = await fetch(
      "https://api.brevo.com/v3/whatsapp/sendMessage",
      {
        method: "POST",
        headers: {
          "api-key": brevoApiKey,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          senderPhoneNumberId: phoneNumberId,
          contactNumbers: [rawPhone],
          templateId: templateName,
          messageType: "template",
          template: {
            name: templateName,
            language: { code: templateLang },
            components: [
              {
                type: "body",
                parameters: [
                  { type: "text", text: otp },
                ],
              },
            ],
          },
        }),
      },
    );

    if (!brevoRes.ok) {
      const body = await brevoRes.text();
      console.error(
        `[send-whatsapp-brevo] Brevo API error status=${brevoRes.status} body=${body}`,
      );
      return new Response(
        JSON.stringify({ error: `Brevo WhatsApp error ${brevoRes.status}: ${body}` }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const brevoBody = await brevoRes.json();
    console.log(
      "[send-whatsapp-brevo] Brevo response:",
      JSON.stringify(brevoBody),
    );

    // Supabase Auth Hook expects an empty object on success
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[send-whatsapp-brevo] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error. Check function logs." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
