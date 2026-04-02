package com.nhtl.notifications.providers;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile({ "default", "dev" })
public class StubSmsProvider implements SmsProvider {
	@Override
	public void sendSms(String to, String message) {
		if (to == null || to.isBlank()) {
			return;
		}
		log.info("[SMS-STUB] to={} message={}", to, message);
	}
}