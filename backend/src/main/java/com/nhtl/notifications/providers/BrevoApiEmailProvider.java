package com.nhtl.notifications.providers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile("prod")
public class BrevoApiEmailProvider implements EmailProvider {

	private static final String BREVO_SEND_EMAIL_URL = "https://api.brevo.com/v3/smtp/email";

	private final RestTemplate restTemplate = new RestTemplate();

	@Value("${brevo.apiKey:}")
	private String apiKey;

	@Value("${app.mail.from:tech@ngom-holding.com}")
	private String fromEmail;

	@Value("${app.mail.fromName:NHTL}")
	private String fromName;

	@Override
	public void sendEmail(String to, String subject, String body) {
		if (to == null || to.isBlank()) {
			return;
		}
		if (apiKey == null || apiKey.isBlank()) {
			log.warn("Brevo API key missing: email not sent (to={})", to);
			return;
		}

		// 1) Log avant appel (sans exposer le body complet)
		log.info("[BREVO] Sending email to='{}' subject='{}' from='{}'", to, safe(subject), fromEmail);

		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_JSON);
		headers.set("api-key", apiKey);

		Map<String, Object> payload = new HashMap<>();

		Map<String, Object> sender = new HashMap<>();
		sender.put("email", fromEmail);
		sender.put("name", fromName);
		payload.put("sender", sender);

		payload.put("to", new Object[] { Map.of("email", to) });
		payload.put("subject", subject != null ? subject : "");
		payload.put("textContent", body != null ? body : "");

		HttpEntity<Map<String, Object>> req = new HttpEntity<>(payload, headers);

		try {
			ResponseEntity<String> resp = restTemplate.postForEntity(BREVO_SEND_EMAIL_URL, req, String.class);

			// 2) Log succès
			log.info("[BREVO] Email accepted status={} to='{}'", resp.getStatusCode().value(), to);
		} catch (HttpStatusCodeException e) {
			// 3) Log erreur avec body de réponse (utile pour debug)
			String responseBody = e.getResponseBodyAsString();
			log.warn("[BREVO] Email failed status={} to='{}' response='{}'",
					e.getStatusCode().value(), to, truncate(responseBody, 800));
			throw e;
		} catch (Exception e) {
			log.warn("[BREVO] Email failed to='{}' err='{}'", to, e.getMessage());
			throw e;
		}
	}

	private static String safe(String s) {
		if (s == null) return "";
		return truncate(s.replaceAll("[\\r\\n\\t]+", " "), 140);
	}

	private static String truncate(String s, int max) {
		if (s == null) return "";
		if (s.length() <= max) return s;
		return s.substring(0, max) + "...(truncated)";
	}
}