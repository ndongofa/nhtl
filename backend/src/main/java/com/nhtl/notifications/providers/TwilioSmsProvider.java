package com.nhtl.notifications.providers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import com.twilio.Twilio;
import com.twilio.exception.ApiException;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile({ "prod", "twilio-sms" })
public class TwilioSmsProvider implements SmsProvider {

	@Value("${twilio.accountSid:}")
	private String accountSid;

	@Value("${twilio.authToken:}")
	private String authToken;

	@Value("${twilio.fromNumber:}")
	private String fromNumber;

	private volatile boolean initialized = false;

	private void initIfNeeded() {
		if (initialized || accountSid == null || accountSid.isBlank()) {
			return;
		}
		if (authToken == null || authToken.isBlank()) {
			return;
		}
		Twilio.init(accountSid, authToken);
		initialized = true;

		log.info("[TWILIO] Initialized accountSid={}", maskSid(accountSid));
	}

	@Override
	public void sendSms(String to, String message) {
		if (to == null || to.isBlank()) {
			log.info("[TWILIO] SMS skipped: empty recipient");
			return;
		}
		if (message == null || message.isBlank()) {
			log.info("[TWILIO] SMS skipped: empty message to='{}'", to);
			return;
		}

		initIfNeeded();

		// Zéro régression: si non configuré, ne rien faire
		if (!initialized) {
			log.warn("[TWILIO] SMS skipped: Twilio not initialized (missing SID/token?) to='{}'", to);
			return;
		}
		if (fromNumber == null || fromNumber.isBlank()) {
			log.warn("[TWILIO] SMS skipped: missing fromNumber to='{}'", to);
			return;
		}

		log.info("[TWILIO] Sending SMS to='{}' from='{}' msg='{}'", to, fromNumber, truncate(message, 140));

		try {
			Message msg = Message.creator(new PhoneNumber(to), new PhoneNumber(fromNumber), message).create();
			log.info("[TWILIO] SMS accepted sid={} to='{}' status={}", msg.getSid(), to, msg.getStatus());
		} catch (ApiException e) {
			log.warn("[TWILIO] SMS failed to='{}' code={} status={} msg='{}'",
					to, e.getCode(), e.getStatusCode(), e.getMessage());
			throw e;
		} catch (Exception e) {
			log.warn("[TWILIO] SMS failed to='{}' err='{}'", to, e.getMessage());
			throw e;
		}
	}

	private static String truncate(String s, int max) {
		if (s == null) return "";
		if (s.length() <= max) return s;
		return s.substring(0, max) + "...(truncated)";
	}

	private static String maskSid(String sid) {
		if (sid == null) return "";
		// ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -> ACxxxxxxxx...xxxx
		if (sid.length() <= 10) return sid;
		return sid.substring(0, 10) + "...";
	}
}