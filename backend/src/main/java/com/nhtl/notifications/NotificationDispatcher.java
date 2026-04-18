package com.nhtl.notifications;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.InAppProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class NotificationDispatcher {

	private final EmailProvider emailProvider;
	private final InAppProvider inAppProvider;
	private final WhatsAppProvider whatsAppProvider;

	@Value("${admin.email:}")
	private String adminEmail;

	@Value("${admin.whatsapp.number:}")
	private String adminWhatsAppNumber;

	public NotificationDispatcher(EmailProvider emailProvider, InAppProvider inAppProvider,
			WhatsAppProvider whatsAppProvider) {
		this.emailProvider = emailProvider;
		this.inAppProvider = inAppProvider;
		this.whatsAppProvider = whatsAppProvider;
	}

	@Async("notificationExecutor")
	public void dispatch(NotificationEvent evt) {
		if (evt == null) {
			return;
		}

		if (NotificationTarget.ADMIN.equals(evt.getTarget())) {
			dispatchAdmin(evt);
		} else {
			dispatchUser(evt);
		}
	}

	private void dispatchUser(NotificationEvent evt) {
		// In-app (toujours si userId)
		if (evt.getUserId() != null && !evt.getUserId().isBlank()) {
			try {
				inAppProvider.createInApp(evt.getUserId(), evt.getType().name(), evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("InApp failed type={} userId={}: {}", evt.getType(), evt.getUserId(), e.getMessage());
			}
		}

		// Email utilisateur
		if (evt.getEmail() != null && !evt.getEmail().isBlank()) {
			try {
				emailProvider.sendEmail(evt.getEmail(), evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("Email failed type={} to={}: {}", evt.getType(), evt.getEmail(), e.getMessage());
			}
		}

		// WhatsApp utilisateur
		if (evt.getPhoneNumber() != null && !evt.getPhoneNumber().isBlank()) {
			try {
				whatsAppProvider.sendWhatsApp(evt.getPhoneNumber(), evt.getMessage());
			} catch (Exception e) {
				log.warn("WhatsApp failed type={} to={}: {}", evt.getType(), evt.getPhoneNumber(), e.getMessage());
			}
		}
	}

	private void dispatchAdmin(NotificationEvent evt) {
		// Email admin
		if (adminEmail != null && !adminEmail.isBlank()) {
			try {
				emailProvider.sendEmail(adminEmail, evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("Admin email failed type={}: {}", evt.getType(), e.getMessage());
			}
		}

		// WhatsApp admin
		if (adminWhatsAppNumber != null && !adminWhatsAppNumber.isBlank()) {
			try {
				whatsAppProvider.sendWhatsApp(adminWhatsAppNumber, evt.getMessage());
			} catch (Exception e) {
				log.warn("Admin WhatsApp failed type={}: {}", evt.getType(), e.getMessage());
			}
		}
	}
}