package com.nhtl.notifications;

import java.util.HashMap;
import java.util.Map;

public class NotificationEvent {
	private String userId; // supabase uuid (string)
	private String email; // optionnel
	private String phoneNumber; // optionnel
	private NotificationEventType type;

	private String title;
	private String message;

	// Données supplémentaires (commandeId, transportId, statut, gpName, etc.)
	private Map<String, Object> data = new HashMap<>();

	public NotificationEvent() {
	}

	public NotificationEvent(String userId, String email, String phoneNumber, NotificationEventType type, String title,
			String message) {
		this.userId = userId;
		this.email = email;
		this.phoneNumber = phoneNumber;
		this.type = type;
		this.title = title;
		this.message = message;
	}

	public String getUserId() {
		return userId;
	}

	public void setUserId(String userId) {
		this.userId = userId;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPhoneNumber() {
		return phoneNumber;
	}

	public void setPhoneNumber(String phoneNumber) {
		this.phoneNumber = phoneNumber;
	}

	public NotificationEventType getType() {
		return type;
	}

	public void setType(NotificationEventType type) {
		this.type = type;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public Map<String, Object> getData() {
		return data;
	}

	public void setData(Map<String, Object> data) {
		this.data = data;
	}

	public NotificationEvent put(String key, Object value) {
		this.data.put(key, value);
		return this;
	}
}