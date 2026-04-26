/**
 * Supabase Auth Hook – Send OTP via WhatsApp (primary) then SMS (fallback)
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *   URL: https://<project-ref>.supabase.co/functions/v1/send-sms-twilio
 *
 * ── Delivery strategy ────────────────────────────────────────────────────────
 *   1. If TWILIO_WHATSAPP_FROM is set, the OTP is sent via WhatsApp first.
 *   2. If the WhatsApp attempt fails (e.g. the number is not on WhatsApp,
 *      error 63001 / 63003), the function automatically falls back to SMS.
 *   3. If TWILIO_WHATSAPP_FROM is NOT set, only SMS is attempted (legacy mode).
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   TWILIO_ACCOUNT_SID            – Account SID from https://console.twilio.com
 *   TWILIO_AUTH_TOKEN             – Auth Token from https://console.twilio.com
 *
 * WhatsApp sender (optional – enables WhatsApp-first mode):
 *   TWILIO_WHATSAPP_FROM          – WhatsApp-enabled number in E.164 format
 *                                   (e.g. "+33652383258").  Do NOT include the
 *                                   "whatsapp:" prefix here; the function adds it.
 *   TWILIO_WHATSAPP_CONTENT_SID   – Meta-approved Content Template SID (HXxxx…).
 *                                   Required in production for business-initiated
 *                                   messages sent outside the 24-hour reply window.
 *                                   The template must expose a single {{1}} variable
 *                                   that receives the full OTP message text.
 *                                   If omitted the message is sent as free-form text
 *                                   (only works inside the 24-hour window / sandbox).
 *
 * SMS sender – use ONE of the following (Messaging Service SID recommended):
 *   TWILIO_MESSAGING_SERVICE_SID  – Messaging Service SID (starts with "MG…")
 *                                   → Twilio selects the best sender per country.
 *                                   Create one at: console.twilio.com/us1/develop/sms/services
 *   TWILIO_FROM_NUMBER            – E.164 Twilio phone number (e.g. "+12025550100")
 *                                   Used when TWILIO_MESSAGING_SERVICE_SID is not set.
 *
 * Optional:
 *   TWILIO_SMS_TEMPLATE           – Custom message template for SMS. Use {otp} as placeholder.
 *                                   Default: "Votre code Sama Services est: {otp}"
 *
 * ── Senegal (+221) not receiving SMS? ────────────────────────────────────────
 * Twilio disables high-risk regions by default. To enable Senegal:
 *   1. Go to Twilio Console → Account → Settings → SMS Geographic Permissions
 *      https://console.twilio.com/us1/account/sms-geographic-permissions
 *   2. Search for "Senegal" and toggle it ON.
 *   3. If using a Messaging Service, also check per-service geo permissions.
 * Without this, Twilio returns error 21408 for all +221 numbers.
 *
 * ── Common Twilio error codes ─────────────────────────────────────────────────
 *   21211 – Invalid 'To' phone number (bad format, user typo) → logged, signup allowed
 *   21408 – Geographic permission not enabled for this country  → error returned
 *   21614 – Not a valid mobile number (landline)               → error returned
 *   30006 – Landline or unreachable carrier                    → error returned
 *   63001 – WhatsApp: number not found / not on WhatsApp       → SMS fallback
 *   63003 – WhatsApp: channel returned an error                → SMS fallback
 *
 * Pricing note:
 *   Twilio rates vary by destination country. Senegal (+221) ≈ $0.085/SMS,
 *   Maroc (+212) ≈ $0.045/SMS. See: https://www.twilio.com/en-us/sms/pricing
 *
 * Twilio REST API reference:
 *   https://www.twilio.com/docs/sms/api/message-resource#create-a-message-resource
 *   https://www.twilio.com/docs/whatsapp/api#sending-messages-with-whatsapp
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

// ── WhatsApp-specific error codes that should trigger an SMS fallback ─────────
// 63001 – WhatsApp number not found (number not registered on WhatsApp)
// 63003 – WhatsApp channel returned an error (unreachable, opt-out, etc.)
const WHATSAPP_FALLBACK_CODES = new Set([63001, 63003]);

/**
 * Attempt to send an OTP via WhatsApp.
 *
 * @param to           Destination in E.164 format (e.g. "+221XXXXXXXXX").
 * @param messageBody  Plain-text OTP message (used as free-form body or as the
 *                     {{1}} template variable when a ContentSid is configured).
 * @param accountSid   Twilio Account SID.
 * @param authToken    Twilio Auth Token.
 * @param whatsappFrom WhatsApp-enabled sender number in E.164 format (without prefix).
 * @param contentSid   Optional Meta-approved Content Template SID (HXxxx…).
 *
 * @returns `{ ok: true }` on success, or `{ ok: false, fallback: boolean }`
 *          where `fallback` is true when the error is recoverable via SMS.
 */
async function sendViaWhatsApp(
  to: string,
  messageBody: string,
  accountSid: string,
  authToken: string,
  whatsappFrom: string,
  contentSid: string | undefined,
): Promise<{ ok: true } | { ok: false; fallback: boolean; reason: string }> {
  const waFrom = `whatsapp:${whatsappFrom}`;
  const waTo = `whatsapp:${to}`;

  let bodyParams: string;
  if (contentSid) {
    // Meta-approved template: pass the full OTP text as the {{1}} variable.
    const contentVariables = JSON.stringify({ "1": messageBody });
    bodyParams =
      `From=${encodeURIComponent(waFrom)}` +
      `&To=${encodeURIComponent(waTo)}` +
      `&ContentSid=${encodeURIComponent(contentSid)}` +
      `&ContentVariables=${encodeURIComponent(contentVariables)}`;
  } else {
    // Free-form message (sandbox / inside the 24-hour reply window).
    bodyParams =
      `From=${encodeURIComponent(waFrom)}` +
      `&To=${encodeURIComponent(waTo)}` +
      `&Body=${encodeURIComponent(messageBody)}`;
  }

  console.log(
    `[send-sms-twilio] Attempting WhatsApp OTP to ${waTo}` +
      (contentSid ? ` via template ${contentSid}` : " (free-form)"),
  );

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: bodyParams,
    },
  );

  if (res.ok) {
    const body = await res.json();
    console.log(
      "[send-sms-twilio] WhatsApp sent: sid=%s status=%s",
      body.sid,
      body.status,
    );
    return { ok: true };
  }

  const rawBody = await res.text();
  let twilioCode: number | null = null;
  try {
    twilioCode = (JSON.parse(rawBody) as { code?: number }).code ?? null;
  } catch (_) { /* non-JSON */ }

  const fallback = twilioCode !== null && WHATSAPP_FALLBACK_CODES.has(twilioCode);
  console.warn(
    `[send-sms-twilio] WhatsApp failed: status=${res.status} code=${twilioCode ?? "unknown"} fallback=${fallback} body=${rawBody}`,
  );
  return {
    ok: false,
    fallback,
    reason: `Twilio WhatsApp error ${res.status} (code ${twilioCode ?? "unknown"})`,
  };
}

/**
 * Send an OTP via regular SMS.
 *
 * @returns `{ ok: true }` on success, or
 *          `{ ok: false, status: number, twilioCode: number|null, body: string }` on failure.
 */
async function sendViaSms(
  to: string,
  messageBody: string,
  accountSid: string,
  authToken: string,
  messagingServiceSid: string | undefined,
  fromNumber: string | undefined,
): Promise<{ ok: true } | { ok: false; status: number; twilioCode: number | null; rawBody: string }> {
  if (!messagingServiceSid && !fromNumber) {
    return { ok: false, status: 500, twilioCode: null, rawBody: "No SMS sender configured" };
  }
  const senderParam = messagingServiceSid
    ? `MessagingServiceSid=${encodeURIComponent(messagingServiceSid)}`
    : `From=${encodeURIComponent(fromNumber as string)}`;

  console.log(
    `[send-sms-twilio] Sending SMS OTP to ${to} via ${
      messagingServiceSid ? "MessagingService " + messagingServiceSid : "number " + fromNumber
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
      body: `${senderParam}&To=${encodeURIComponent(to)}&Body=${encodeURIComponent(messageBody)}`,
    },
  );

  if (res.ok) {
    const body = await res.json();
    console.log(
      "[send-sms-twilio] SMS sent: sid=%s status=%s",
      body.sid,
      body.status,
    );
    return { ok: true };
  }

  const rawBody = await res.text();
  let twilioCode: number | null = null;
  try {
    twilioCode = (JSON.parse(rawBody) as { code?: number }).code ?? null;
  } catch (_) { /* non-JSON */ }

  return { ok: false, status: res.status, twilioCode, rawBody };
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
    const whatsappFrom = Deno.env.get("TWILIO_WHATSAPP_FROM");
    const whatsappContentSid = Deno.env.get("TWILIO_WHATSAPP_CONTENT_SID");

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

    // ── 1. Try WhatsApp first (if configured) ──────────────────────────────
    if (whatsappFrom) {
      if (!whatsappContentSid) {
        console.warn(
          `[send-sms-twilio] TWILIO_WHATSAPP_FROM is set but TWILIO_WHATSAPP_CONTENT_SID is missing. ` +
          `Free-form WhatsApp messages are only delivered inside the 24-hour reply window or the Twilio sandbox. ` +
          `Set TWILIO_WHATSAPP_CONTENT_SID to a Meta-approved template SID for production use, ` +
          `or unset TWILIO_WHATSAPP_FROM to skip WhatsApp and send directly via SMS.`,
        );
      }
      const waResult = await sendViaWhatsApp(
        to,
        messageBody,
        accountSid,
        authToken,
        whatsappFrom,
        whatsappContentSid,
      );

      if (waResult.ok) {
        return new Response(JSON.stringify({}), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }

      // WhatsApp failed for any reason (number not on WhatsApp, template rejected,
      // template pending approval, channel error, etc.) – always fall back to SMS
      // so the OTP is never silently lost.
      console.warn(
        `[send-sms-twilio] WhatsApp failed for ${to} (${waResult.reason}) – falling back to SMS`,
      );
    }

    // ── 2. SMS (primary when WhatsApp not configured, fallback otherwise) ──
    const smsResult = await sendViaSms(
      to,
      messageBody,
      accountSid,
      authToken,
      messagingServiceSid,
      fromNumber,
    );

    if (smsResult.ok) {
      return new Response(JSON.stringify({}), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ── Handle SMS errors ──────────────────────────────────────────────────
    const { status: smsStatus, twilioCode, rawBody } = smsResult;
    console.error(
      `[send-sms-twilio] Twilio SMS API error status=${smsStatus} body=${rawBody}`,
    );

    if (smsStatus === 400) {
      // 21211 = Invalid 'To' phone number (bad format / user typo).
      // Allow signup so a malformed number doesn't permanently block the flow.
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
      if (twilioCode === 21408) {
        console.error(
          `[send-sms-twilio] Twilio 21408 – Geographic permission not enabled for to='${to}'. ` +
          "Enable the destination country in Twilio Console → Account → Settings → SMS Geographic Permissions.",
        );
      }

      return new Response(
        JSON.stringify({
          error: `Twilio error 400 (code ${twilioCode ?? "unknown"}): ${rawBody}`,
        }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        error: `Twilio error ${smsStatus}: ${rawBody}`,
      }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("[send-sms-twilio] Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error. Check function logs." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
