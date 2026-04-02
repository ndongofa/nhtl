package com.nhtl.notifications.providers;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile({ "default", "dev" })
public class StubEmailProvider implements EmailProvider {
	@Override
	public void sendEmail(String to, String subject, String body) {
		if (to == null || to.isBlank()) {
			return;
		}
		log.info("[EMAIL-STUB] to={} subject={} body={}", to, subject, body);
	}
}