package kr.ac.kopo.lyh.personalcolor.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
import kr.ac.kopo.lyh.personalcolor.entity.ColorType;
import kr.ac.kopo.lyh.personalcolor.repository.ColorAnalysisRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;
import java.time.LocalDateTime;

import static kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis.*;
import com.fasterxml.jackson.databind.ObjectMapper;
@Service
@Slf4j
public class FileStorageService {
    private final ObjectMapper objectMapper;
    private final String uploadDir;
    private final ColorAnalysisRepository colorAnalysisRepository;

    @Autowired
    public FileStorageService(
            ObjectMapper objectMapper, @Value("${app.upload.path:uploads}") String uploadDir,
            ColorAnalysisRepository colorAnalysisRepository) {
        this.objectMapper = objectMapper;
        this.uploadDir = uploadDir;
        this.colorAnalysisRepository = colorAnalysisRepository;
        createUploadDirectory();
    }

    /**
     * 업로드 디렉토리 생성
     */
    private void createUploadDirectory() {
        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                log.info("업로드 디렉토리 생성: {}", uploadPath.toAbsolutePath());
            }
        } catch (IOException e) {
            log.error("업로드 디렉토리 생성 실패", e);
            throw new RuntimeException("업로드 디렉토리 생성 실패", e);
        }
    }

    /**
     * 파일 저장
     */
    public String storeFile(MultipartFile file) {
        try {
            // 파일 검증
            if (file.isEmpty()) {
                throw new IllegalArgumentException("빈 파일은 저장할 수 없습니다.");
            }

            // 원본 파일명 검증
            String originalFileName = file.getOriginalFilename();
            if (originalFileName == null || originalFileName.isEmpty()) {
                throw new IllegalArgumentException("파일명이 없습니다.");
            }

            // 파일명 정규화 (보안 검증)
            String fileName = StringUtils.cleanPath(originalFileName);
            if (fileName.contains("..")) {
                throw new IllegalArgumentException("파일명에 잘못된 경로가 포함되어 있습니다: " + fileName);
            }

            // 확장자 추출
            String extension = getFileExtension(originalFileName);

            // 고유한 파일명 생성 (UUID + 타임스탬프 + 확장자)
            String uniqueFileName = UUID.randomUUID().toString() +
                    "_" + System.currentTimeMillis() + extension;

            // 파일 저장 경로 생성
            Path targetLocation = Paths.get(uploadDir).resolve(uniqueFileName);

            // 파일 저장
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            log.info("파일 저장 완료: {} -> {}", originalFileName, uniqueFileName);
            return uniqueFileName;

        } catch (IOException e) {
            log.error("파일 저장 중 오류 발생", e);
            throw new RuntimeException("파일 저장 실패", e);
        }
    }

    /**
     * 파일 로드
     */
    public Resource loadFile(String fileName) {
        try {
            // 파일명 검증
            if (fileName == null || fileName.isEmpty()) {
                throw new IllegalArgumentException("파일명이 없습니다.");
            }

            Path filePath = Paths.get(uploadDir).resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() && resource.isReadable()) {
                log.info("파일 로드 성공: {}", fileName);
                return resource;
            } else {
                throw new RuntimeException("파일을 찾을 수 없습니다: " + fileName);
            }
        } catch (MalformedURLException e) {
            log.error("파일 로드 중 오류 발생: {}", fileName, e);
            throw new RuntimeException("파일 로드 실패", e);
        }
    }

    /**
     * 파일 삭제
     */
    public void deleteFile(String fileName) {
        try {
            if (fileName == null || fileName.isEmpty()) {
                throw new IllegalArgumentException("파일명이 없습니다.");
            }

            Path filePath = Paths.get(uploadDir).resolve(fileName).normalize();
            boolean deleted = Files.deleteIfExists(filePath);

            if (deleted) {
                log.info("파일 삭제 완료: {}", fileName);
            } else {
                log.warn("삭제할 파일이 존재하지 않습니다: {}", fileName);
            }
        } catch (IOException e) {
            log.error("파일 삭제 중 오류 발생: {}", fileName, e);
            throw new RuntimeException("파일 삭제 실패", e);
        }
    }

    /**
     * AI 분석 결과와 파일 정보를 받아 ColorAnalysis 엔티티로 저장
     */
    public ColorAnalysis createAnalysisEntity(String originalFileName, String storedFileName, Map<String, Object> aiResult) {
        {
            // 1) Extract prediction
            String prediction = (String) aiResult.get("prediction");

            // 2) Map to ColorType, never null
            ColorType ct = ColorType.fromString(prediction);
            if (ct == null) {
                log.warn("알 수 없는 컬러 타입 '{}', 기본 SPRING 저장", prediction);
                ct = ColorType.SPRING;
            }

            // 3) Build analysis entity
            ColorAnalysis analysis = new ColorAnalysis();
            analysis.setOriginalFileName(originalFileName);
            analysis.setStoredFileName(storedFileName);
            analysis.setColorType(ct);
            analysis.setDescription(ct.getDescription());

            // 4) Confidence
            Object confObj = aiResult.get("confidence");
            double confidence = confObj instanceof Number
                    ? ((Number)confObj).doubleValue()
                    : Double.parseDouble(confObj.toString());
            analysis.setConfidence(confidence);

            // 5) Recommendations → JSON
            try {
                String recJson = objectMapper.writeValueAsString(aiResult.get("recommendations"));
                analysis.setDominantColors(recJson);
            } catch (JsonProcessingException e) {
                log.warn("recommendations JSON 변환 실패", e);
                analysis.setDominantColors("[]");
            }

            // 6) Timestamps (both required)
            LocalDateTime now = LocalDateTime.now();
            analysis.setCreatedAt(now);
            analysis.setAnalyzedAt(now);

            // 7) (Optional) associate current user, etc.

            // 8) Save
            return colorAnalysisRepository.save(analysis);
        }
    }

    /**
     * 파일 확장자 추출
     */
    private String getFileExtension(String fileName) {
        int lastDotIndex = fileName.lastIndexOf('.');
        if (lastDotIndex == -1) {
            return "";
        }
        return fileName.substring(lastDotIndex);
    }

    /**
     * AI 결과에서 confidence 값 추출 및 설정 (JDK 17 패턴 매칭 활용)
     */
    private void extractAndSetConfidence(ColorAnalysis analysis, Map<String, Object> aiResult) {
        Object confidenceObj = aiResult.get("confidence");
        if (confidenceObj instanceof Number confidence) {
            analysis.setConfidence(confidence.doubleValue());
        } else if (confidenceObj instanceof String confidenceStr) {
            try {
                analysis.setConfidence(Double.parseDouble(confidenceStr));
            } catch (NumberFormatException e) {
                log.warn("confidence 값 변환 실패: {}", confidenceStr);
            }
        }
    }

    /**
     * AI 결과에서 color type 추출 및 설정
     */
    private void extractAndSetColorType(ColorAnalysis analysis, Map<String, Object> aiResult) {
        Object predictionObj = aiResult.get("prediction");
        if (predictionObj instanceof String prediction) {
            try {
                // ColorType이 enum이라고 가정
                analysis.setColorType(ColorType.valueOf(prediction.toUpperCase()));
            } catch (IllegalArgumentException e) {
                log.warn("ColorType 변환 실패: {}", prediction);
                // 기본값 설정 또는 예외 처리
            }
        }
    }

    /**
     * AI 결과에서 dominant colors 추출 및 설정
     */
    private void extractAndSetDominantColors(ColorAnalysis analysis, Map<String, Object> aiResult) {
        Object dominantColorsObj = aiResult.get("dominantColors");
        if (dominantColorsObj != null) {
            analysis.setDominantColors(dominantColorsObj.toString());
        }
    }

    /**
     * AI 결과에서 description 추출 및 설정
     */
    private void extractAndSetDescription(ColorAnalysis analysis, Map<String, Object> aiResult) {
        Object descriptionObj = aiResult.get("description");
        if (descriptionObj instanceof String description) {
            analysis.setDescription(description);
        }
    }

    /**
     * 파일 존재 여부 확인
     */
    public boolean fileExists(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return false;
        }
        Path filePath = Paths.get(uploadDir).resolve(fileName);
        return Files.exists(filePath);
    }

    /**
     * 파일 크기 조회
     */
    public long getFileSize(String fileName) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName);
            return Files.size(filePath);
        } catch (IOException e) {
            log.error("파일 크기 조회 실패: {}", fileName, e);
            return 0;
        }
    }

    /**
     * MIME 타입 결정
     */
    public String determineMimeType(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return "application/octet-stream";
        }

        String extension = getFileExtension(fileName).toLowerCase();
        return switch (extension) {
            case ".jpg", ".jpeg" -> "image/jpeg";
            case ".png" -> "image/png";
            case ".gif" -> "image/gif";
            case ".bmp" -> "image/bmp";
            case ".webp" -> "image/webp";
            case ".svg" -> "image/svg+xml";
            case ".pdf" -> "application/pdf";
            default -> "application/octet-stream";
        };
    }
}
