package com.nhtl.notifications.providers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;

@Component
@Profile("prod")
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
	}

	@Override
	public void sendSms(String to, String message) {
		if (to == null || to.isBlank() || message == null || message.isBlank()) {
			return;
		}

		initIfNeeded();

		// Zéro régression: si non configuré, ne rien faire
		if (!initialized) {
			return;
		}
		if (fromNumber == null || fromNumber.isBlank()) {
			return;
		}

		Message.creator(new PhoneNumber(to), new PhoneNumber(fromNumber), message).create();
	}
}