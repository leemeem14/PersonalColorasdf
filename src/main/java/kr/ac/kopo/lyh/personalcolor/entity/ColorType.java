package kr.ac.kopo.lyh.personalcolor.entity;

import lombok.Getter;

@Getter
public enum ColorType {
    SPRING("봄웜톤", "밝고 화사한 색상"),
    SUMMER("여름쿨톤", "시원하고 부드러운 색상"),
    AUTUMN("가을웜톤", "깊고 따뜻한 색상"),
    WINTER("겨울쿨톤", "선명하고 차가운 색상");

    // ← 반드시 아래 메서드를 추가!
    private final String displayName;
    private final String description;

    ColorType(String displayName, String description) {
        this.displayName = displayName;
        this.description = description;
    }

    // 예외 상황 대응용, String을 Enum으로 변환
    public static ColorType fromString(String v) {
        if (v == null) return SPRING;
        switch (v.trim().toLowerCase()) {
            case "spring", "봄" -> {
                return SPRING;
            }
            case "summer", "여름" -> {
                return SUMMER;
            }
            case "autumn", "fall", "가을" -> {
                return AUTUMN;
            }
            case "winter", "겨울" -> {
                return WINTER;
            }
            default -> {
                // log warning if desired
                return SPRING;
            }
        }
    }
}