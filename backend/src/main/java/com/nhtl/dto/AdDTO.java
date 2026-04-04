package com.nhtl.dto;

import java.time.LocalDateTime;

public class AdDTO {

    private Long id;
    private String emoji;
    private String title;
    private String subtitle;
    private String colorHex;
    private String colorEndHex;
    private int position;
    private boolean isActive;
    private String adType;
    private String imageUrl;
    private String youtubeId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getEmoji() { return emoji; }
    public void setEmoji(String emoji) { this.emoji = emoji; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }

    public String getColorHex() { return colorHex; }
    public void setColorHex(String colorHex) { this.colorHex = colorHex; }

    public String getColorEndHex() { return colorEndHex; }
    public void setColorEndHex(String colorEndHex) { this.colorEndHex = colorEndHex; }

    public int getPosition() { return position; }
    public void setPosition(int position) { this.position = position; }

    public boolean getIsActive() { return isActive; }

    public void setIsActive(boolean isActive) { this.isActive = isActive; }

    public String getAdType() { return adType; }
    public void setAdType(String adType) { this.adType = adType; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getYoutubeId() { return youtubeId; }
    public void setYoutubeId(String youtubeId) { this.youtubeId = youtubeId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
