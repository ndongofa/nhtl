package com.nhtl.dto;

import com.nhtl.models.DepartureStatus;
import java.time.LocalDateTime;

public class DepartureDTO {

    private Long id;
    private String route;
    private String pointDepart;
    private String pointArrivee;
    private String flagEmoji;
    private LocalDateTime departureDateTime;
    private DepartureStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getRoute() { return route; }
    public void setRoute(String route) { this.route = route; }

    public String getPointDepart() { return pointDepart; }
    public void setPointDepart(String pointDepart) { this.pointDepart = pointDepart; }

    public String getPointArrivee() { return pointArrivee; }
    public void setPointArrivee(String pointArrivee) { this.pointArrivee = pointArrivee; }

    public String getFlagEmoji() { return flagEmoji; }
    public void setFlagEmoji(String flagEmoji) { this.flagEmoji = flagEmoji; }

    public LocalDateTime getDepartureDateTime() { return departureDateTime; }
    public void setDepartureDateTime(LocalDateTime departureDateTime) { this.departureDateTime = departureDateTime; }

    public DepartureStatus getStatus() { return status; }
    public void setStatus(DepartureStatus status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}