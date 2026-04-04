package com.nhtl.repositories;

import com.nhtl.models.Ad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AdRepository extends JpaRepository<Ad, Long> {

    List<Ad> findByIsActiveTrueOrderByPositionAscCreatedAtAsc();

    List<Ad> findAllByOrderByPositionAscCreatedAtAsc();
}
