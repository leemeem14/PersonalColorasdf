package kr.ac.kopo.lyh.personalcolor.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityNotFoundException;
import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
import kr.ac.kopo.lyh.personalcolor.entity.ColorType;
import kr.ac.kopo.lyh.personalcolor.entity.User;
import kr.ac.kopo.lyh.personalcolor.exception.AiInferenceException;
import kr.ac.kopo.lyh.personalcolor.repository.ColorAnalysisRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class ColorAnalysisService {

    private final AiModelClientService aiModelClientService;
    private final ColorAnalysisRepository colorAnalysisRepository;
    private final ObjectMapper objectMapper;

    public ColorAnalysis analyzeImage(User user, String originalFileName, String storedFileName) {
        try {
            log.info("이미지 분석 시작: 사용자={}, 파일={}",
                    user != null ? user.getEmail() : "익명", originalFileName);

            // 1) AI 서버 비동기 호출 (60초 타임아웃)
            Map<String, Object> aiResult = aiModelClientService.predictPersonalColor(storedFileName)
                    .timeout(Duration.ofSeconds(60))
                    .doOnError(error -> log.error("AI 서버 호출 실패: {}", error.getMessage()))
                    .onErrorMap(throwable -> new AiInferenceException("AI 분석 실패", throwable))
                    .block();

            if (aiResult == null) {
                throw new AiInferenceException("AI 서버로부터 응답을 받지 못했습니다.");
            }

            // 2) AI 결과 검증
            validateAiResult(aiResult);

            // 3) ColorAnalysis 엔티티 생성 및 저장
            ColorAnalysis analysis = createAnalysisEntity(user, originalFileName, storedFileName, aiResult);
            ColorAnalysis saved = colorAnalysisRepository.save(analysis);

            log.info("이미지 분석 완료: ID={}, 사용자={}, 결과={} (신뢰도={}%)",
                    saved.getId(),
                    user != null ? user.getEmail() : "익명",
                    saved.getColorType().getDisplayName(),
                    Math.round(saved.getConfidence() * 100));

            return saved;

        } catch (AiInferenceException e) {
            log.error("AI 분석 오류: {}", e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("이미지 분석 중 예기치 못한 오류: {}", e.getMessage(), e);
            throw new AiInferenceException("이미지 분석에 실패했습니다: " + e.getMessage(), e);
        }
    }

    /**
     * AI 결과 검증
     */
    private void validateAiResult(Map<String, Object> aiResult) {
        if (!Boolean.TRUE.equals(aiResult.get("success"))) {
            String error = (String) aiResult.getOrDefault("error", "알 수 없는 오류");
            throw new AiInferenceException("AI 분석 실패: " + error);
        }

        if (aiResult.get("prediction") == null) {
            throw new AiInferenceException("AI 분석 결과에 예측값이 없습니다.");
        }
    }

    /**
     * AI 결과로부터 ColorAnalysis 엔티티 생성
     */
    private ColorAnalysis createAnalysisEntity(User user, String originalFileName, String storedFileName, Map<String, Object> aiResult) {
        try {
            // prediction 추출 및 ColorType 변환
            String prediction = (String) aiResult.get("prediction");
            ColorType colorType = ColorType.fromString(prediction);
            if (colorType == null) {
                log.warn("알 수 없는 컬러 타입 '{}', 기본 SPRING 저장", prediction);
                colorType = ColorType.SPRING;        // 또는 예외를 던져서 실패 처리
            }

            // confidence 추출 (JDK 17 표준형)
            Object confidenceObj = aiResult.get("confidence");
            double confidence;
            if (confidenceObj instanceof Number) {
                confidence = ((Number) confidenceObj).doubleValue();
            } else if (confidenceObj instanceof String) {
                try {
                    confidence = Double.parseDouble((String) confidenceObj);
                } catch (NumberFormatException e) {
                    log.warn("confidence 값 파싱 실패: {}", confidenceObj);
                    confidence = 0.0;
                }
            } else {
                confidence = 0.0;
            }

            // recommendations 추출 및 JSON 변환
            List<String> recs = (List<String>) aiResult.get("recommendations");
            String recJson;
            try {
                recJson = objectMapper.writeValueAsString(recs);
            } catch (JsonProcessingException e) {
                log.warn("recommendations JSON 변환 실패", e);
                recJson = "[]";
            }
            // 엔티티 생성
            ColorAnalysis analysis = new ColorAnalysis();
            analysis.setUser(user);
            analysis.setOriginalFileName(originalFileName);
            analysis.setStoredFileName(storedFileName);
            analysis.setColorType(colorType);
            analysis.setDescription(colorType.getDescription());        // enum 설명
            analysis.setConfidence(confidence);
            analysis.setDominantColors(recJson);
            LocalDateTime now = LocalDateTime.now();
            analysis.setCreatedAt(now);
            analysis.setAnalyzedAt(now);                        // 누락 방지
            return analysis;

        } catch (Exception e) {
            log.error("분석 엔티티 생성 실패: {}", e.getMessage(), e);
            throw new AiInferenceException("분석 결과 처리 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * 객체를 JSON 문자열로 변환
     */
    private String convertToJson(Object obj) {
        if (obj == null) {
            return "[]";
        }
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            log.warn("JSON 변환 실패: {}", e.getMessage());
            return "[]";
        }
    }
    /**
     * 컬러 타입별 샘플 색상 생성
     */
    private String generateSampleColors(ColorType colorType) {
        return switch (colorType) {
            case SPRING -> "[\"#FFB6C1\", \"#FFA07A\", \"#F0E68C\", \"#98FB98\"]";
            case SUMMER -> "[\"#E6E6FA\", \"#B0C4DE\", \"#F0F8FF\", \"#DDA0DD\"]";
            case AUTUMN -> "[\"#D2691E\", \"#CD853F\", \"#B22222\", \"#8B4513\"]";
            case WINTER -> "[\"#000080\", \"#800080\", \"#DC143C\", \"#008B8B\"]";
        };
    }

    public ColorAnalysis findById(Long id) {
        return colorAnalysisRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("분석 결과를 찾을 수 없습니다: " + id));
    }
}
    // 기존 메서드들은 그대로 유지...

//import com.fasterxml.jackson.core.JsonProcessingException;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
//import kr.ac.kopo.lyh.personalcolor.entity.User;
//import kr.ac.kopo.lyh.personalcolor.repository.ColorAnalysisRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.data.domain.Page;
//import org.springframework.data.domain.Pageable;
//import org.springframework.stereotype.Service;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.util.List;
//import java.util.Map;
//import java.util.Random;
//
//@Service
//@RequiredArgsConstructor
//@Transactional
//@Slf4j
//public class ColorAnalysisService {
//
//    private final ColorAnalysisRepository colorAnalysisRepository;
//    private final AiModelClientService aiClient;
//    private final Random random = new Random();
//
//    /**
//     * 이미지 분석 수행 (현재는 임시 랜덤 결과)
//     * 추후 실제 AI 분석 로직으로 대체
//     */
//
//    public ColorAnalysis analyzeImage(User user, String originalFileName, String storedFileName) throws JsonProcessingException {
//        // 1) AI 서버 호출
//        Map<String, Object> aiResult = aiClient.predictPersonalColor(storedFileName);
//        String predicted = (String) aiResult.get("prediction");
//        float confidence = ((Number) aiResult.get("confidence")).floatValue();
//        @SuppressWarnings("unchecked")
//        List<String> dominants = (List<String>) aiResult.get("recommendations");
//
//        // 2) ColorType 매핑
//        ColorAnalysis.ColorType colorType = ColorAnalysis.ColorType.fromDisplayName(predicted);
//
//        // 3) 엔티티 빌드
//        ColorAnalysis analysis = ColorAnalysis.builder()
//                .user(user)
//                .originalFileName(originalFileName)
//                .storedFileName(storedFileName)
//                .colorType(colorType)
//                .description(colorType.getDescription())
//                .confidence(confidence)
//                .dominantColors(new ObjectMapper().writeValueAsString(dominants))
//                .build();
//
//        ColorAnalysis saved = colorAnalysisRepository.save(analysis);
//        log.info("AI 분석 완료: 사용자={}, 결과={} (신뢰도={})",
//                user != null ? user.getEmail() : "익명", predicted, confidence);
//        return saved;
//    }
//
//    /**
//     * ID로 분석 결과 조회
//     */
//    @Transactional(readOnly = true)
//    public ColorAnalysis getAnalysisById(Long analysisId) {
//        return colorAnalysisRepository.findById(analysisId)
//                .orElse(null);
//    }
//
//    /**
//     * 사용자의 분석 결과 목록 조회
//     */
//    @Transactional(readOnly = true)
//    public List<ColorAnalysis> getUserAnalyses(User user) {
//        return colorAnalysisRepository.findByUserOrderByAnalyzedAtDesc(user);
//    }
//
//    /**
//     * 사용자의 분석 결과 페이징 조회
//     */
//    @Transactional(readOnly = true)
//    public Page<ColorAnalysis> getUserAnalyses(User user, Pageable pageable) {
//        return colorAnalysisRepository.findByUserOrderByAnalyzedAtDesc(user, pageable);
//    }
//
//    /**
//     * 사용자의 최근 분석 결과 조회
//     */
//    @Transactional(readOnly = true)
//    public ColorAnalysis getLatestAnalysis(User user) {
//        return colorAnalysisRepository.findFirstByUserOrderByAnalyzedAtDesc(user)
//                .orElse(null);
//    }
//
//    /**
//     * 분석 결과 삭제
//     */
//    public void deleteAnalysis(Long analysisId, User user) {
//        ColorAnalysis analysis = colorAnalysisRepository.findById(analysisId)
//                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 분석 결과입니다."));
//
//        if (!analysis.getUser().getId().equals(user.getId())) {
//            throw new IllegalArgumentException("삭제 권한이 없습니다.");
//        }
//
//        colorAnalysisRepository.delete(analysis);
//        log.info("분석 결과 삭제: ID={}, 사용자={}", analysisId, user.getEmail());
//    }
//
//    /**
//     * 임시 색상 정보 생성 (실제 분석 결과로 대체 예정)
//     */
//    private String generateSampleColors(ColorAnalysis.ColorType colorType) {
//        // JSON 형태로 대표 색상들 저장
//        return switch (colorType) {
//            case SPRING_WARM -> "[\"#FFB6C1\", \"#FFA07A\", \"#F0E68C\", \"#98FB98\"]";
//            case SUMMER_COOL -> "[\"#E6E6FA\", \"#B0C4DE\", \"#F0F8FF\", \"#DDA0DD\"]";
//            case AUTUMN_WARM -> "[\"#D2691E\", \"#CD853F\", \"#B22222\", \"#8B4513\"]";
//            case WINTER_COOL -> "[\"#000080\", \"#800080\", \"#DC143C\", \"#008B8B\"]";
//            default -> "[\"#808080\"]";
//        };
//    }
//    public ColorAnalysis saveAnalysis(
//            User user,
//            String originalFileName,
//            String storedFileName,
//            String predictedDisplayName,
//            float confidence,
//            List<String> recommendations) throws JsonProcessingException {
//        ColorAnalysis.ColorType type = ColorAnalysis.ColorType.fromDisplayName(predictedDisplayName);
//        ColorAnalysis analysis = ColorAnalysis.builder()
//                .user(user)
//                .originalFileName(originalFileName)
//                .storedFileName(storedFileName)
//                .colorType(type)
//                .description(type.getDescription())
//                .confidence(confidence)
//                .dominantColors(new ObjectMapper().writeValueAsString(recommendations))
//                .build();
//        return colorAnalysisRepository.save(analysis);
//    }
//
//}
