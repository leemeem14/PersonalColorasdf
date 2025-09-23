package kr.ac.kopo.lyh.personalcolor.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;


@Entity
@Table(name = "color_analysis")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ColorAnalysis {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "original_filename", nullable = false)
    private String originalFileName;

    @Column(name = "stored_filename", nullable = false)
    private String storedFileName;

    @Enumerated(EnumType.STRING)
    @Column(name = "color_type", nullable = false)
    private ColorType colorType;

    @Column(name = "confidence")
    private Double confidence;

    @Column(name = "dominant_colors", columnDefinition = "TEXT")
    private String dominantColors;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "analyzed_at", nullable = false)
    private LocalDateTime analyzedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (analyzedAt == null) {
            analyzedAt = now;
        }
    }


}