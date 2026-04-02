package com.nhtl.notifications.providers;

public interface EmailProvider {
	void sendEmail(String to, String subject, String body);
}