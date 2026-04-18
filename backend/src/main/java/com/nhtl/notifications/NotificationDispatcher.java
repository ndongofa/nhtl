package com.nhtl.notifications;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.InAppProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class NotificationDispatcher {

	private final EmailProvider emailProvider;
	private final InAppProvider inAppProvider;
	private final WhatsAppProvider whatsAppProvider;
	private final SmsProvider smsProvider;

	@Value("${admin.email:}")
	private String adminEmail;

	@Value("${admin.whatsapp.number:}")
	private String adminWhatsAppNumber;

	@Value("${admin.user.id:}")
	private String adminUserId;

	public NotificationDispatcher(EmailProvider emailProvider, InAppProvider inAppProvider,
			WhatsAppProvider whatsAppProvider, SmsProvider smsProvider) {
		this.emailProvider = emailProvider;
		this.inAppProvider = inAppProvider;
		this.whatsAppProvider = whatsAppProvider;
		this.smsProvider = smsProvider;
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
		// In-app (si userId présent)
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

		// WhatsApp utilisateur, SMS en fallback
		if (evt.getPhoneNumber() != null && !evt.getPhoneNumber().isBlank()) {
			sendWhatsAppWithSmsFallback(evt.getPhoneNumber(), evt.getMessage(), evt.getType().name());
		}
	}

	private void dispatchAdmin(NotificationEvent evt) {
		// In-app admin (si admin.user.id configuré)
		if (adminUserId != null && !adminUserId.isBlank()) {
			try {
				inAppProvider.createInApp(adminUserId, evt.getType().name(), evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("Admin InApp failed type={}: {}", evt.getType(), e.getMessage());
			}
		}

		// Email admin
		if (adminEmail != null && !adminEmail.isBlank()) {
			try {
				emailProvider.sendEmail(adminEmail, evt.getTitle(), evt.getMessage());
			} catch (Exception e) {
				log.warn("Admin email failed type={}: {}", evt.getType(), e.getMessage());
			}
		}

		// WhatsApp admin, SMS en fallback
		if (adminWhatsAppNumber != null && !adminWhatsAppNumber.isBlank()) {
			sendWhatsAppWithSmsFallback(adminWhatsAppNumber, evt.getMessage(), evt.getType().name());
		}
	}

	/**
	 * Tente d'envoyer via WhatsApp. En cas d'échec, bascule automatiquement sur SMS.
	 */
	private void sendWhatsAppWithSmsFallback(String to, String message, String type) {
		try {
			whatsAppProvider.sendWhatsApp(to, message);
		} catch (Exception waEx) {
			log.warn("WhatsApp failed type={} to='{}', falling back to SMS. err='{}'", type, to, waEx.getMessage());
			try {
				smsProvider.sendSms(to, message);
			} catch (Exception smsEx) {
				log.warn("SMS fallback also failed type={} to='{}': {}", type, to, smsEx.getMessage());
			}
		}
	}
}