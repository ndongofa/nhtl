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
 * Pricing note:
 *   Twilio rates vary by destination country. Sénégal (+221) ≈ $0.085/SMS,
 *   Maroc (+212) ≈ $0.045/SMS – much higher than the US rate ($0.008/SMS).
 *   Budget accordingly. See: https://www.twilio.com/en-us/sms/pricing
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

serve(async (req: Request): Promise<Response> => {
  try {
    const rawBody = await req.arrayBuffer();

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
      // 400 with code 21211 = invalid 'To' number – allow Supabase signup
      // so a bad phone entry doesn't block the auth flow entirely.
      if (twilioRes.status === 400) {
        console.warn(
          "[send-sms-twilio] Twilio 400 – invalid request (bad number?). Signup allowed but OTP not sent.",
        );
        return new Response(JSON.stringify({}), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
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
