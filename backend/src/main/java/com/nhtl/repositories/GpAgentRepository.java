package com.nhtl.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhtl.models.GpAgent;

@Repository
public interface GpAgentRepository extends JpaRepository<GpAgent, Long> {
	List<GpAgent> findByIsActiveTrue();
}