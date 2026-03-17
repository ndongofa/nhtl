package com.nhtl.notifications;

import org.springframework.stereotype.Service;

import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.InAppProvider;
import com.nhtl.notifications.providers.SmsProvider;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class NotificationDispatcher {

	private final EmailProvider emailProvider;
	private final SmsProvider smsProvider;
	private final InAppProvider inAppProvider;

	public NotificationDispatcher(EmailProvider emailProvider, SmsProvider smsProvider, InAppProvider inAppProvider) {
		this.emailProvider = emailProvider;
		this.smsProvider = smsProvider;
		this.inAppProvider = inAppProvider;
	}

	public void dispatch(NotificationEvent evt) {
		if (evt == null) {
			return;
		}

		// In-app (toujours si userId) - ✅ ultra-safe
		if (evt.getUserId() != null && !evt.getUserId().isBlank()) {
			try {
				inAppProvider.createInApp(evt.getUserId(), evt.getType().name(), evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("InApp failed type={} userId={}: {}", evt.getType(), evt.getUserId(), e.getMessage());
			}
		}

		// Email
		if (evt.getEmail() != null && !evt.getEmail().isBlank()) {
			try {
				emailProvider.sendEmail(evt.getEmail(), evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("Email failed type={} to={}: {}", evt.getType(), evt.getEmail(), e.getMessage());
			}
		}

		// SMS
		if (evt.getPhoneNumber() != null && !evt.getPhoneNumber().isBlank()) {
			try {
				smsProvider.sendSms(evt.getPhoneNumber(), evt.getMessage());
			} catch (Exception e) {
				log.warn("SMS failed type={} to={}: {}", evt.getType(), evt.getPhoneNumber(), e.getMessage());
			}
		}
	}
}