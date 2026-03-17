package com.nhtl.services;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.nhtl.dto.NotificationDTO;
import com.nhtl.models.Notification;
import com.nhtl.repositories.NotificationRepository;

@Service
public class NotificationService {

	private final NotificationRepository repo;

	public NotificationService(NotificationRepository repo) {
		this.repo = repo;
	}

	public void create(String userId, String type, String title, String message) {
		Notification n = new Notification();
		n.setUserId(userId);
		n.setType(type);
		n.setTitle(title);
		n.setMessage(message);
		n.setIsRead(false);
		repo.save(n);
	}

	public List<NotificationDTO> getForUser(String userId) {
		return repo.findByUserIdOrderByCreatedAtDesc(userId).stream().map(this::toDto).collect(Collectors.toList());
	}

	public boolean markRead(Long id, String userId) {
		Optional<Notification> opt = repo.findById(id);
		if (opt.isEmpty()) {
			return false;
		}
		Notification n = opt.get();
		if (!n.getUserId().equals(userId)) {
			return false;
		}
		n.setIsRead(true);
		repo.save(n);
		return true;
	}

	private NotificationDTO toDto(Notification n) {
		NotificationDTO dto = new NotificationDTO();
		dto.setId(n.getId());
		dto.setType(n.getType());
		dto.setTitle(n.getTitle());
		dto.setMessage(n.getMessage());
		dto.setIsRead(n.getIsRead());
		dto.setCreatedAt(n.getCreatedAt());
		return dto;
	}
}