package com.nhtl.notifications.providers;

import org.springframework.stereotype.Component;

import com.nhtl.services.NotificationService;

@Component
public class InAppProviderImpl implements InAppProvider {

	private final NotificationService notificationService;

	public InAppProviderImpl(NotificationService notificationService) {
		this.notificationService = notificationService;
	}

	@Override
	public void createInApp(String userId, String type, String title, String message) {
		notificationService.create(userId, type, title, message);
	}
}