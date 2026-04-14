/**
 * Supabase Auth Hook – Send SMS via Brevo
 *
 * Configure this Edge Function as the "Send SMS" auth hook in:
 *   Supabase Dashboard → Authentication → Hooks → Send SMS hook
 *
 * Required environment variables (set via Supabase Dashboard → Edge Functions → Secrets):
 *   BREVO_API_KEY       – Your Brevo (Sendinblue) API key
 *   BREVO_SMS_SENDER    – Alphanumeric sender name (max 11 chars), e.g. "NHTL"
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

serve(async (req: Request): Promise<Response> => {
  try {
    const payload: SMSHookPayload = await req.json();

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
