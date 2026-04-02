package com.nhtl.notifications.providers;

public interface SmsProvider {
	void sendSms(String to, String message);
}