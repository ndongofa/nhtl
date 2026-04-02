package com.nhtl.repositories;

import com.nhtl.models.Departure;
import com.nhtl.models.DepartureStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface DepartureRepository extends JpaRepository<Departure, Long> {

    List<Departure> findByStatusOrderByDepartureDateTimeAsc(DepartureStatus status);

    List<Departure> findByStatusInOrderByDepartureDateTimeAsc(List<DepartureStatus> statuses);

    List<Departure> findByStatusAndDepartureDateTimeAfterOrderByDepartureDateTimeAsc(
            DepartureStatus status, LocalDateTime after);

    List<Departure> findAllByOrderByDepartureDateTimeAsc();
}