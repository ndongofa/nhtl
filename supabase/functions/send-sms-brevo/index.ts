/**
 * Supabase Auth Hook – Send SMS via Brevo
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   BREVO_API_KEY          – Your Brevo (Sendinblue) API key
 *   BREVO_SMS_SENDER       – Alphanumeric sender name (max 11 chars), e.g. "NHTL"
 *   SEND_SMS_HOOK_SECRET   – Webhook signing secret from the Supabase hook dashboard
 *                            (full value, e.g. "v1,whsec_<base64>")
 *
 * Brevo API reference: https://developers.brevo.com/reference/sendtransacsms
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
    // Signature is only verified when BOTH the env secret is configured AND
    // Supabase actually sends the x-supabase-signature header.
    // If the header is absent (null), we proceed and only warn – this happens
    // when the Auth Hook in the Supabase dashboard has no signing secret set.
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
    const sigHeader = req.headers.get("x-supabase-signature");
    if (hookSecret && sigHeader) {
      const valid = await verifyHookSignature(
        new Uint8Array(rawBody),
        sigHeader,
        hookSecret,
      );
      if (!valid) {
        console.error("[send-sms-brevo] Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid webhook signature" }),
          { status: 401, headers: { "Content-Type": "application/json" } },
        );
      }
    } else if (!hookSecret) {
      console.warn(
        "[send-sms-brevo] SEND_SMS_HOOK_SECRET is not set – skipping signature verification",
      );
    } else {
      // hookSecret is set but Supabase sent no signature header.
      // This happens when the Auth Hook in the dashboard has no signing secret.
      // Configure a matching secret in: Dashboard → Authentication → Hooks → (edit) → Signing secret
      console.warn(
        "[send-sms-brevo] x-supabase-signature header is absent – proceeding without verification. " +
        "Set a signing secret in the Supabase Auth Hook dashboard to enable verification.",
      );
    }
    // ───────────────────────────────────────────────────────────────────────

    const payload: SMSHookPayload = JSON.parse(new TextDecoder().decode(rawBody));

    const phone = payload?.user?.phone;
    const otp = payload?.sms?.otp;

    if (!phone || !otp) {
      console.error("[send-sms-brevo] Missing phone or otp in payload", payload);
      return new Response(
        JSON.stringify({ error: "Missing phone or otp" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const brevoApiKey = Deno.env.get("BREVO_API_KEY");
    if (!brevoApiKey) {
      console.error("[send-sms-brevo] BREVO_API_KEY env var is not set");
      return new Response(
        JSON.stringify({ error: "BREVO_API_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const sender = Deno.env.get("BREVO_SMS_SENDER") ?? "NHTL";

    // Phone should already be in E.164 format with "+" (enforced by the Flutter client).
    // Log a warning if the "+" is unexpectedly missing so upstream issues are visible.
    if (!phone.startsWith("+")) {
      console.warn(
        `[send-sms-brevo] Phone "${phone}" is missing the '+' prefix. Verify the Flutter client sends full E.164 format.`,
      );
    }
    const recipient = phone.startsWith("+") ? phone : `+${phone}`;

    // SMS template: override via BREVO_SMS_TEMPLATE env var.
    // Use the placeholder {otp} in your custom template, e.g.:
    //   "Your NHTL verification code is: {otp}"
    const templateEnv = Deno.env.get("BREVO_SMS_TEMPLATE");
    const message = templateEnv
      ? templateEnv.replace("{otp}", otp)
      : `Votre code de vérification NHTL est : ${otp}`;

    console.log(
      `[send-sms-brevo] Sending OTP to ${recipient} from "${sender}"`,
    );

    const brevoRes = await fetch(
      "https://api.brevo.com/v3/transactionalSMS/sms",
      {
        method: "POST",
        headers: {
          "api-key": brevoApiKey,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          sender,
          recipient,
          content: message,
          type: "transactional",
        }),
      },
    );

    if (!brevoRes.ok) {
      const body = await brevoRes.text();
      console.error(
        `[send-sms-brevo] Brevo API error status=${brevoRes.status} body=${body}`,
      );
      // 402 = insufficient SMS credits. Allow signup to proceed rather than
      // blocking the user entirely; the OTP SMS simply won't be delivered.
      if (brevoRes.status === 402) {
        console.warn(
          "[send-sms-brevo] Insufficient Brevo SMS credits – signup allowed but OTP not sent. Recharge at https://app.sendinblue.com/billing/addon/customize/sms",
        );
        return new Response(JSON.stringify({}), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }
      return new Response(
        JSON.stringify({ error: `Brevo error ${brevoRes.status}: ${body}` }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const brevoBody = await brevoRes.json();
    console.log("[send-sms-brevo] Brevo response:", JSON.stringify(brevoBody));

    // Supabase Auth Hook expects an empty object on success
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[send-sms-brevo] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error. Check function logs." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
