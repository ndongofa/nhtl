package com.nhtl.services;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.nhtl.dto.GpAgentDTO;
import com.nhtl.models.GpAgent;
import com.nhtl.repositories.GpAgentRepository;

@Service
public class GpAgentService {

	private final GpAgentRepository repo;

	public GpAgentService(GpAgentRepository repo) {
		this.repo = repo;
	}

	public List<GpAgentDTO> getAll() {
		return repo.findAll().stream().map(this::toDto).collect(Collectors.toList());
	}

	public List<GpAgentDTO> getActive() {
		return repo.findByIsActiveTrue().stream().map(this::toDto).collect(Collectors.toList());
	}

	public Optional<GpAgent> getEntity(Long id) {
		return repo.findById(id);
	}

	public GpAgentDTO create(GpAgentDTO dto) {
		GpAgent gp = new GpAgent();
		gp.setPrenom(dto.getPrenom());
		gp.setNom(dto.getNom());
		gp.setPhoneNumber(dto.getPhoneNumber());
		gp.setEmail(dto.getEmail());
		gp.setIsActive(dto.getIsActive() == null ? true : dto.getIsActive());
		return toDto(repo.save(gp));
	}

	public GpAgentDTO update(Long id, GpAgentDTO dto) {
		Optional<GpAgent> opt = repo.findById(id);
		if (opt.isEmpty()) {
			return null;
		}

		GpAgent gp = opt.get();
		gp.setPrenom(dto.getPrenom());
		gp.setNom(dto.getNom());
		gp.setPhoneNumber(dto.getPhoneNumber());
		gp.setEmail(dto.getEmail());
		if (dto.getIsActive() != null) {
			gp.setIsActive(dto.getIsActive());
		}

		return toDto(repo.save(gp));
	}

	public boolean delete(Long id) {
		if (!repo.existsById(id)) {
			return false;
		}
		repo.deleteById(id);
		return true;
	}

	private GpAgentDTO toDto(GpAgent gp) {
		GpAgentDTO dto = new GpAgentDTO();
		dto.setId(gp.getId());
		dto.setPrenom(gp.getPrenom());
		dto.setNom(gp.getNom());
		dto.setPhoneNumber(gp.getPhoneNumber());
		dto.setEmail(gp.getEmail());
		dto.setIsActive(gp.getIsActive());
		return dto;
	}
}