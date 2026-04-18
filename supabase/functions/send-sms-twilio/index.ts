/**
 * Supabase Auth Hook – Send OTP via Twilio SMS (worldwide)
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *   URL: https://<project-ref>.supabase.co/functions/v1/send-sms-twilio
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   TWILIO_ACCOUNT_SID            – Account SID from https://console.twilio.com
 *   TWILIO_AUTH_TOKEN             – Auth Token from https://console.twilio.com
 *
 * Sender – use ONE of the following (Messaging Service SID recommended for worldwide delivery):
 *   TWILIO_MESSAGING_SERVICE_SID  – Messaging Service SID (starts with "MG…")
 *                                   → Twilio selects the best sender per destination country.
 *                                   Create one at: console.twilio.com/us1/develop/sms/services
 *   TWILIO_FROM_NUMBER            – E.164 Twilio phone number (e.g. "+12025550100")
 *                                   Fallback if TWILIO_MESSAGING_SERVICE_SID is not set.
 *
 * Optional:
 *   TWILIO_SMS_TEMPLATE           – Custom message template. Use {otp} as placeholder.
 *                                   Default: "Votre code Sama Services est: {otp}"
 *
 * ── Senegal (+221) not receiving SMS? ────────────────────────────────────────
 * Twilio disables high-risk regions by default. To enable Senegal:
 *   1. Go to Twilio Console → Account → Settings → SMS Geographic Permissions
 *      https://console.twilio.com/us1/account/sms-geographic-permissions
 *   2. Search for "Senegal" and toggle it ON.
 *   3. If using a Messaging Service, also check per-service geo permissions.
 * Without this, Twilio returns error 21408 for all +221 numbers and this
 * function returns an explicit error (does NOT silently swallow it).
 *
 * ── Common Twilio error codes ─────────────────────────────────────────────────
 *   21211 – Invalid 'To' phone number (bad format, user typo) → logged, signup allowed
 *   21408 – Geographic permission not enabled for this country  → error returned
 *   21614 – Not a valid mobile number (landline)               → error returned
 *   30006 – Landline or unreachable carrier                    → error returned
 *
 * Pricing note:
 *   Twilio rates vary by destination country. Senegal (+221) ≈ $0.085/SMS,
 *   Maroc (+212) ≈ $0.045/SMS. See: https://www.twilio.com/en-us/sms/pricing
 *
 * Twilio REST API reference:
 *   https://www.twilio.com/docs/sms/api/message-resource#create-a-message-resource
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
  // Expected header format: "v1=<base64>" or "v1=<base64url>"
  const match = sigHeader.match(/^v1=(.+)$/);
  if (!match) return false;
  const receivedSigEncoded = match[1];

  // Secret format from the Supabase dashboard: "v1,whsec_<base64>"
  const secretMatch = secret.match(/^v1,whsec_(.+)$/);
  if (!secretMatch) return false;
  const rawKey = Uint8Array.from(atob(secretMatch[1]), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    rawKey,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );

  // Supabase may send the signature as base64url (uses '-' and '_').
  // atob() requires standard base64 (uses '+' and '/'), so normalise first.
  const base64 = receivedSigEncoded.replace(/-/g, "+").replace(/_/g, "/");
  const receivedSigBytes = Uint8Array.from(
    atob(base64),
    (c) => c.charCodeAt(0),
  );

  // crypto.subtle.verify() performs a constant-time comparison internally.
  return await crypto.subtle.verify("HMAC", cryptoKey, receivedSigBytes, rawBody);
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
        console.error("[send-sms-twilio] Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid webhook signature" }),
          { status: 401, headers: { "Content-Type": "application/json" } },
        );
      }
    } else if (!hookSecret) {
      console.warn(
        "[send-sms-twilio] SEND_SMS_HOOK_SECRET is not set – skipping signature verification",
      );
    } else {
      // hookSecret is set but Supabase sent no signature header.
      // This happens when the Auth Hook in the dashboard has no signing secret.
      // Configure a matching secret in: Dashboard → Authentication → Hooks → (edit) → Signing secret
      console.warn(
        "[send-sms-twilio] x-supabase-signature header is absent – proceeding without verification. " +
        "Set a signing secret in the Supabase Auth Hook dashboard to enable verification.",
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
        "[send-sms-twilio] Missing phone or otp in payload",
        payload,
      );
      return new Response(
        JSON.stringify({ error: "Missing phone or otp" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");

    if (!accountSid || !authToken) {
      console.error(
        "[send-sms-twilio] TWILIO_ACCOUNT_SID or TWILIO_AUTH_TOKEN env var is not set",
      );
      return new Response(
        JSON.stringify({ error: "Twilio credentials not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const messagingServiceSid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID");
    const fromNumber = Deno.env.get("TWILIO_FROM_NUMBER");

    if (!messagingServiceSid && !fromNumber) {
      console.error(
        "[send-sms-twilio] Neither TWILIO_MESSAGING_SERVICE_SID nor TWILIO_FROM_NUMBER is set",
      );
      return new Response(
        JSON.stringify({
          error:
            "Twilio sender not configured. Set TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM_NUMBER.",
        }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Phone must be E.164 (with leading "+"). Log a warning if missing.
    if (!phone.startsWith("+")) {
      console.warn(
        `[send-sms-twilio] Phone "${phone}" is missing the '+' prefix. Verify the Flutter client sends full E.164 format.`,
      );
    }
    const to = phone.startsWith("+") ? phone : `+${phone}`;

    const templateEnv = Deno.env.get("TWILIO_SMS_TEMPLATE");
    const messageBody = templateEnv
      ? templateEnv.replace("{otp}", otp)
      : `Votre code Sama Services est: ${otp}`;

    const senderParam = messagingServiceSid
      ? `MessagingServiceSid=${encodeURIComponent(messagingServiceSid)}`
      : `From=${encodeURIComponent(fromNumber!)}`;

    console.log(
      `[send-sms-twilio] Sending OTP to ${to} via ${messagingServiceSid ? "MessagingService " + messagingServiceSid : "number " + fromNumber}`,
    );

    // Twilio Messages API – application/x-www-form-urlencoded
    const twilioRes = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: `${senderParam}&To=${encodeURIComponent(to)}&Body=${encodeURIComponent(messageBody)}`,
      },
    );

    if (!twilioRes.ok) {
      const body = await twilioRes.text();
      console.error(
        `[send-sms-twilio] Twilio API error status=${twilioRes.status} body=${body}`,
      );

      if (twilioRes.status === 400) {
        // Parse the Twilio error code to distinguish between different 400 causes.
        let twilioCode: number | null = null;
        try {
          twilioCode = (JSON.parse(body) as { code?: number }).code ?? null;
        } catch (_) { /* non-JSON body, leave twilioCode as null */ }

        // 21211 = Invalid 'To' phone number (bad format / user typo).
        // Allow signup so a malformed number doesn't permanently block the flow.
        // All other 400 codes (especially 21408 = Geographic permission not enabled)
        // are returned as errors so the problem is visible in logs.
        if (twilioCode === 21211) {
          console.warn(
            `[send-sms-twilio] Twilio 21211 – invalid phone format for to='${to}'. Signup allowed but OTP not sent.`,
          );
          return new Response(JSON.stringify({}), {
            status: 200,
            headers: { "Content-Type": "application/json" },
          });
        }

        // 21408 = Geographic permission not enabled for this country.
        // ➜ Enable the destination country in Twilio Console:
        //   Account → Settings → SMS Geographic Permissions
        //   https://console.twilio.com/us1/account/sms-geographic-permissions
        if (twilioCode === 21408) {
          console.error(
            `[send-sms-twilio] Twilio 21408 – Geographic permission not enabled for to='${to}'. ` +
            "Enable the destination country in Twilio Console → Account → Settings → SMS Geographic Permissions.",
          );
        }

        return new Response(
          JSON.stringify({
            error: `Twilio error 400 (code ${twilioCode ?? "unknown"}): ${body}`,
          }),
          { status: 502, headers: { "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({
          error: `Twilio error ${twilioRes.status}: ${body}`,
        }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const twilioBody = await twilioRes.json();
    console.log(
      "[send-sms-twilio] Twilio response: sid=%s status=%s",
      twilioBody.sid,
      twilioBody.status,
    );

    // Supabase Auth Hook expects an empty object on success
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[send-sms-twilio] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error. Check function logs." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
