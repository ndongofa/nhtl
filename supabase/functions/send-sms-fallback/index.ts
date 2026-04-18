/**
 * Supabase Auth Hook – Send OTP via Brevo SMS with automatic Twilio fallback
 *
 * Tries Brevo first (free / low-cost). If Brevo fails for any reason
 * (including country not supported – e.g. Sénégal +221), it automatically
 * retries via Twilio so delivery is guaranteed worldwide.
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *   URL: https://<project-ref>.supabase.co/functions/v1/send-sms-fallback
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   SEND_SMS_HOOK_SECRET           – Webhook signing secret (full value "v1,whsec_<base64>")
 *
 * Brevo (primary – free plan, limited countries):
 *   BREVO_API_KEY                  – Your Brevo (Sendinblue) API key
 *   BREVO_SMS_SENDER               – Alphanumeric sender name (max 11 chars), e.g. "SamaService"
 *   BREVO_SMS_TEMPLATE             – Optional custom template; use {otp} as placeholder
 *
 * Twilio (fallback – worldwide, any country including Sénégal +221):
 *   TWILIO_ACCOUNT_SID             – Account SID from https://console.twilio.com
 *   TWILIO_AUTH_TOKEN              – Auth Token from https://console.twilio.com
 *   TWILIO_MESSAGING_SERVICE_SID   – Messaging Service SID (starts with "MG…") – recommended
 *   TWILIO_FROM_NUMBER             – Fallback E.164 Twilio number if no Messaging Service SID
 *   TWILIO_SMS_TEMPLATE            – Optional custom template; use {otp} as placeholder
 *
 * Pricing note:
 *   Brevo SMS does NOT support all countries (e.g. Sénégal +221).
 *   When Brevo fails, Twilio takes over. Twilio rates vary by country:
 *   Sénégal (+221) ≈ $0.085/SMS – see https://www.twilio.com/en-us/sms/pricing
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
 * Supabase sends:   x-supabase-signature: v1=<base64url-encoded-HMAC-SHA256>
 * The hook secret stored in the dashboard has the format: v1,whsec_<base64-key>
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

/**
 * Send SMS via Brevo transactional SMS API.
 * Throws if the API call fails (Brevo error, unsupported country, etc.).
 */
async function sendViaBrevo(
  phone: string,
  otp: string,
  brevoApiKey: string,
  sender: string,
  template: string | undefined,
): Promise<void> {
  // Phone must be in E.164 format (e.g. "+221783042838")
  const recipient = phone.startsWith("+") ? phone : `+${phone}`;
  const message = template
    ? template.replace("{otp}", otp)
    : `Votre code de vérification Sama Services International est : ${otp}`;

  console.log(
    `[send-sms-fallback][BREVO] Sending OTP to ${recipient} from "${sender}"`,
  );

  const res = await fetch("https://api.brevo.com/v3/transactionalSMS/sms", {
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
  });

  if (!res.ok) {
    const body = await res.text();
    console.warn(
      `[send-sms-fallback][BREVO] Failed status=${res.status} body=${body}`,
    );
    throw new Error(`Brevo error ${res.status}: ${body}`);
  }

  const resBody = await res.json();
  console.log(
    "[send-sms-fallback][BREVO] Accepted:",
    JSON.stringify(resBody),
  );
}

/**
 * Send SMS via Twilio Messages API.
 * Throws if the API call fails.
 */
async function sendViaTwilio(
  phone: string,
  otp: string,
  accountSid: string,
  authToken: string,
  messagingServiceSid: string | undefined,
  fromNumber: string | undefined,
  template: string | undefined,
): Promise<void> {
  const to = phone.startsWith("+") ? phone : `+${phone}`;
  const message = template
    ? template.replace("{otp}", otp)
    : `Votre code Sama Services est: ${otp}`;

  const senderParam = messagingServiceSid
    ? `MessagingServiceSid=${encodeURIComponent(messagingServiceSid)}`
    : `From=${encodeURIComponent(fromNumber!)}`;

  console.log(
    `[send-sms-fallback][TWILIO] Sending OTP to ${to} via ${
      messagingServiceSid
        ? "MessagingService " + messagingServiceSid
        : "number " + fromNumber
    }`,
  );

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: `${senderParam}&To=${encodeURIComponent(to)}&Body=${encodeURIComponent(message)}`,
    },
  );

  if (!res.ok) {
    const body = await res.text();
    console.warn(
      `[send-sms-fallback][TWILIO] Failed status=${res.status} body=${body}`,
    );
    // 400 with code 21211 = invalid 'To' number (bad phone format)
    // Throw so the caller's catch block handles it and logs appropriately.
    throw new Error(`Twilio error ${res.status}: ${body}`);
  }

  const resBody = await res.json();
  console.log(
    "[send-sms-fallback][TWILIO] Accepted: sid=%s status=%s",
    resBody.sid,
    resBody.status,
  );
}

serve(async (req: Request): Promise<Response> => {
  try {
    const rawBody = await req.arrayBuffer();

    // ── Webhook signature verification ─────────────────────────────────────
    const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
    const sigHeader = req.headers.get("x-supabase-signature");
    if (hookSecret && sigHeader) {
      const valid = await verifyHookSignature(
        new Uint8Array(rawBody),
        sigHeader,
        hookSecret,
      );
      if (!valid) {
        console.error("[send-sms-fallback] Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid webhook signature" }),
          { status: 401, headers: { "Content-Type": "application/json" } },
        );
      }
    } else if (!hookSecret) {
      console.warn(
        "[send-sms-fallback] SEND_SMS_HOOK_SECRET is not set – skipping signature verification",
      );
    } else {
      console.warn(
        "[send-sms-fallback] x-supabase-signature header is absent – proceeding without verification. " +
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
        "[send-sms-fallback] Missing phone or otp in payload",
        payload,
      );
      return new Response(
        JSON.stringify({ error: "Missing phone or otp" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!phone.startsWith("+")) {
      console.warn(
        `[send-sms-fallback] Phone "${phone}" is missing the '+' prefix. Verify the Flutter client sends full E.164 format.`,
      );
    }

    // ── 1. Try Brevo (primary) ─────────────────────────────────────────────
    const brevoApiKey = Deno.env.get("BREVO_API_KEY");
    if (brevoApiKey) {
      const brevoSender = Deno.env.get("BREVO_SMS_SENDER") ?? "SamaService";
      const brevoTemplate = Deno.env.get("BREVO_SMS_TEMPLATE");
      try {
        await sendViaBrevo(phone, otp, brevoApiKey, brevoSender, brevoTemplate);
        // Brevo succeeded – return early
        return new Response(JSON.stringify({}), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      } catch (brevoErr) {
        console.warn(
          `[send-sms-fallback] Brevo failed for ${phone}, switching to Twilio. err=${brevoErr instanceof Error ? brevoErr.message : brevoErr}`,
        );
        // fall through to Twilio
      }
    } else {
      console.info(
        "[send-sms-fallback] BREVO_API_KEY not set – skipping Brevo, trying Twilio directly",
      );
    }

    // ── 2. Fallback: Twilio (worldwide, including Sénégal +221) ────────────
    const twilioAccountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const twilioAuthToken = Deno.env.get("TWILIO_AUTH_TOKEN");

    if (!twilioAccountSid || !twilioAuthToken) {
      console.error(
        "[send-sms-fallback] Neither Brevo nor Twilio is configured. OTP cannot be sent.",
      );
      // Return 200 so Supabase does not block the auth flow entirely,
      // but log clearly that the OTP was NOT delivered.
      return new Response(
        JSON.stringify({
          error:
            "No SMS provider configured. Set BREVO_API_KEY or TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN.",
        }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const messagingServiceSid = Deno.env.get("TWILIO_MESSAGING_SERVICE_SID");
    const fromNumber = Deno.env.get("TWILIO_FROM_NUMBER");

    if (!messagingServiceSid && !fromNumber) {
      console.error(
        "[send-sms-fallback] TWILIO_ACCOUNT_SID set but neither TWILIO_MESSAGING_SERVICE_SID nor TWILIO_FROM_NUMBER is configured.",
      );
      return new Response(
        JSON.stringify({
          error:
            "Twilio sender not configured. Set TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM_NUMBER.",
        }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const twilioTemplate = Deno.env.get("TWILIO_SMS_TEMPLATE");
    try {
      await sendViaTwilio(
        phone,
        otp,
        twilioAccountSid,
        twilioAuthToken,
        messagingServiceSid,
        fromNumber,
        twilioTemplate,
      );
    } catch (twilioErr) {
      console.error(
        `[send-sms-fallback] Both Brevo and Twilio failed for ${phone}. OTP not delivered. err=${twilioErr instanceof Error ? twilioErr.message : twilioErr}`,
      );
      // Do not block the auth flow; the user can request a new OTP.
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[send-sms-fallback] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error. Check function logs." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
