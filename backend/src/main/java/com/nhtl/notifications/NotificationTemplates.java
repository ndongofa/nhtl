package com.nhtl.notifications;

import org.springframework.stereotype.Component;

import com.nhtl.models.CommandeStatus;
import com.nhtl.models.TransportStatus;

@Component
public class NotificationTemplates {

	public NotificationEvent signupValidated(String userId, String email, String phone) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.SIGNUP_VALIDATED,
				"Inscription confirmée", "Bienvenue ! Votre compte a été créé avec succès.");
	}

	public NotificationEvent passwordResetOtpSent(String userId, String email, String phone, String otp) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.PASSWORD_RESET_OTP_SENT,
				"Code de réinitialisation", "Votre code OTP est : " + otp + " (valide pour une durée limitée).");
	}

	public NotificationEvent passwordResetSuccess(String userId, String email, String phone) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.PASSWORD_RESET_SUCCESS,
				"Mot de passe modifié", "Votre mot de passe a été réinitialisé avec succès.");
	}

	public NotificationEvent commandeCreated(String userId, String email, String phone, Long commandeId) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.COMMANDE_CREATED, "Commande reçue",
				"Votre commande a été reçue. Référence: #" + commandeId + ".");
	}

	public NotificationEvent transportCreated(String userId, String email, String phone, Long transportId) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.TRANSPORT_CREATED,
				"Demande de transport reçue",
				"Votre demande de transport a été reçue. Référence: #" + transportId + ".");
	}

	public NotificationEvent commandeGpAssigned(String userId, String email, String phone, Long commandeId,
			String gpFullName, String gpPhone, CommandeStatus newStatus) {
		String msg = "Votre commande #" + commandeId + " est prise en charge par " + gpFullName
				+ (gpPhone != null && !gpPhone.isBlank() ? " (Tél: " + gpPhone + ")" : "")
				+ (newStatus != null ? ". Statut: " + newStatus.name() : ".");
		return new NotificationEvent(userId, email, phone, NotificationEventType.COMMANDE_GP_ASSIGNED,
				"Commande prise en charge", msg);
	}

	public NotificationEvent transportGpAssigned(String userId, String email, String phone, Long transportId,
			String gpFullName, String gpPhone, TransportStatus newStatus) {
		String msg = "Votre transport #" + transportId + " est pris en charge par " + gpFullName
				+ (gpPhone != null && !gpPhone.isBlank() ? " (Tél: " + gpPhone + ")" : "")
				+ (newStatus != null ? ". Statut: " + newStatus.name() : ".");
		return new NotificationEvent(userId, email, phone, NotificationEventType.TRANSPORT_GP_ASSIGNED,
				"Transport pris en charge", msg);
	}

	public NotificationEvent commandeStatusUpdated(String userId, String email, String phone, Long commandeId,
			CommandeStatus status) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.COMMANDE_STATUS_UPDATED,
				"Statut commande mis à jour", "Commande #" + commandeId + " : nouveau statut = " + status.name());
	}

	public NotificationEvent transportStatusUpdated(String userId, String email, String phone, Long transportId,
			TransportStatus status) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.TRANSPORT_STATUS_UPDATED,
				"Statut transport mis à jour", "Transport #" + transportId + " : nouveau statut = " + status.name());
	}

	public NotificationEvent commandeCompleted(String userId, String email, String phone, Long commandeId) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.COMMANDE_COMPLETED,
				"Commande terminée", "Votre commande #" + commandeId + " est terminée. Merci !");
	}

	public NotificationEvent transportCompleted(String userId, String email, String phone, Long transportId) {
		return new NotificationEvent(userId, email, phone, NotificationEventType.TRANSPORT_COMPLETED,
				"Transport terminé", "Votre transport #" + transportId + " est terminé. Merci !");
	}
}