package com.nhtl.notifications.providers;

public interface InAppProvider {
	void createInApp(String userId, String type, String title, String message);
}