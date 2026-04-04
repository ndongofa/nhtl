package com.nhtl.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "ads")
public class Ad {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String emoji;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String subtitle;

    @Column(nullable = false, length = 20)
    private String colorHex;

    @Column(nullable = false, length = 20)
    private String colorEndHex;

    @Column(nullable = false)
    private int position = 0;

    @Column(nullable = false)
    private boolean isActive = true;

    @Column(nullable = false, length = 20)
    private String adType = "text";

    @Column(columnDefinition = "TEXT")
    private String imageUrl;

    @Column(length = 20)
    private String youtubeId;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

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

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

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
