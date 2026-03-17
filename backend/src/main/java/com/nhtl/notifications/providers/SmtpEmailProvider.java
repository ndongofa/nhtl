package com.nhtl.notifications.providers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

@Component
@Profile("prod")
public class SmtpEmailProvider implements EmailProvider {

	private final JavaMailSender mailSender;

	@Value("${app.mail.from:no-reply@nhtl.com}")
	private String from;

	public SmtpEmailProvider(JavaMailSender mailSender) {
		this.mailSender = mailSender;
	}

	@Override
	public void sendEmail(String to, String subject, String body) {
		if (to == null || to.isBlank()) {
			return;
		}

		SimpleMailMessage msg = new SimpleMailMessage();
		msg.setFrom(from);
		msg.setTo(to);
		msg.setSubject(subject != null ? subject : "");
		msg.setText(body != null ? body : "");

		mailSender.send(msg);
	}
}