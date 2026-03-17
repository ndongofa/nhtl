package com.nhtl.dto;

public class AssignGpRequest {
	private Long gpId;
	private String newStatut; // optionnel

	public Long getGpId() {
		return gpId;
	}

	public void setGpId(Long gpId) {
		this.gpId = gpId;
	}

	public String getNewStatut() {
		return newStatut;
	}

	public void setNewStatut(String newStatut) {
		this.newStatut = newStatut;
	}
}