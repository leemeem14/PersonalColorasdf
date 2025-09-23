package kr.ac.kopo.lyh.personalcolor.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
import kr.ac.kopo.lyh.personalcolor.entity.ColorType;
import kr.ac.kopo.lyh.personalcolor.service.AiModelClientService;
import kr.ac.kopo.lyh.personalcolor.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import java.io.Serializable;
import java.util.List;
import java.util.Map;

import java.time.Duration;
import java.util.Optional;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import reactor.core.publisher.Mono;
@Controller
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@Slf4j
public class UploadController {

    private final FileStorageService fileStorageService;
    private final AiModelClientService aiModelClientService;
    private final ObjectMapper objectMapper;

    @Value("${app.upload.path:uploads}")
    private String uploadDir;

    @ResponseBody
    @PostMapping(value = "/upload",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public Mono<ResponseEntity<Map<String, Object>>> uploadFile(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {

        // 1) 파일 유효성 검사
        if (file.isEmpty() || !Optional.ofNullable(file.getContentType())
                .filter(ct -> ct.startsWith("image/"))
                .isPresent()) {
            return Mono.just(ResponseEntity.badRequest()
                    .body(Map.of("success", false, "error",
                            file.isEmpty() ? "파일이 비어있습니다."
                                    : "이미지 파일만 업로드 가능합니다.")));
        }

        String storedFileName;
        try {
            storedFileName = fileStorageService.storeFile(file);
            log.info("파일 저장 완료: {}", storedFileName);
        } catch (Exception e) {
            log.error("파일 저장 실패", e);
            return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("success", false, "error", "파일 저장 중 오류가 발생했습니다.")));
        }

        // 2) AI 서버 호출 (리액티브 체인)
        return aiModelClientService.predictPersonalColor(storedFileName)
                .timeout(Duration.ofSeconds(600))
//                .onErrorResume(ex -> Mono.just(
//                        ResponseEntity.status(HttpStatus.GATEWAY_TIMEOUT)
//                                .body(Map.of("success", false, "error", "AI 서버 응답 지연"))
//                ))
                // now map the successful AI result into a ResponseEntity
                .map(aiResult -> {
                    Boolean success = (Boolean) aiResult.get("success");
                    if (Boolean.TRUE.equals(success)) {
                        ColorAnalysis analysis = fileStorageService.createAnalysisEntity(
                                file.getOriginalFilename(), storedFileName, aiResult);
                        log.debug("AI 응답: {}", aiResult);
                        String display = Optional.ofNullable(analysis.getColorType())
                                .map(ColorType::getDisplayName)
                                .orElse("기본 SPRING");
                        HttpSession session = request.getSession(true);
                        session.setAttribute("latestAnalysisId", analysis.getId());
                        String seasonKey = analysis.getColorType().name();  // SPRING, SUMMER 등
                        List<String> recList = null;
                        try {
                            recList = objectMapper.readValue(analysis.getDominantColors(),
                                    new TypeReference<List<String>>() {});
                        } catch (JsonProcessingException e) {
                            throw new RuntimeException(e);
                        }
                        return ResponseEntity.ok(Map.of(
                                "success", true,
                                "message", "분석 완료",
                                "analysisId", analysis.getId(),
                                "prediction", display,
                                "confidence", Math.round(analysis.getConfidence()*100),
                                "recommendations", recList, // JSON 문자열 or List
                                "redirectUrl", "/results2?season=" + seasonKey
                        ));
                    } else {
                        String error = aiResult.getOrDefault("error", "알 수 없는 오류").toString();
                        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                                .body(Map.of("success", false, "error", "AI 분석 실패: " + error));
                    }
                });
    }
}


//@Controller
//@RequiredArgsConstructor
//@CrossOrigin(origins = "*")
//@Slf4j
//public class UploadController {
//
//    @Value("${app.upload.path:uploads}")               // ① 업로드 폴더 경로 주입
//    private String uploadDir;
//
//    private final FileStorageService fileStorageService;
//    private final ColorAnalysisService colorAnalysisService;
//    private final AiModelClientService aiModelClientService;
//
//    @GetMapping("/upload/page")
//    public String uploadPage() {
//        return "upload";
//    }
//
//    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
//    @ResponseBody
//    public ResponseEntity<?> uploadFile(
//            @RequestParam("file") MultipartFile file,
//            HttpServletRequest request) {
//        try {
//            // 로그인 정보(선택)
//            User user = null;
//            HttpSession s0 = request.getSession(false);
//            if (s0 != null && s0.getAttribute("user") != null) {
//                user = (User) s0.getAttribute("user");
//            }
//
//            // ② 파일 검증
//            if (file.isEmpty()) {
//                return ResponseEntity.badRequest()
//                        .body(Map.of("success", false, "error", "파일이 비어있습니다."));
//            }
//            if (!Objects.requireNonNull(file.getContentType()).startsWith("image/")) {
//                return ResponseEntity.badRequest()
//                        .body(Map.of("success", false, "error", "이미지 파일만 업로드 가능합니다."));
//            }
//
//            // ③ 파일 저장
//            String storedFileName = fileStorageService.storeFile(file);
//            String storedFilePath = Paths.get(uploadDir).resolve(storedFileName).toString();
//
//            // ④ AI 서버 예측
//            Map<String, Object> aiResult = aiModelClientService.predictPersonalColor(storedFilePath);
//            String prediction     = (String) aiResult.get("prediction");
//            float confidence      = ((Number) aiResult.get("confidence")).floatValue();
//            @SuppressWarnings("unchecked")
//            List<String> recs     = (List<String>) aiResult.get("recommendations");
//
//            // ⑤ DB 저장
//            ColorAnalysis analysis = colorAnalysisService.saveAnalysis(
//                    user,
//                    file.getOriginalFilename(),
//                    storedFileName,
//                    prediction,
//                    confidence,
//                    recs
//            );
//
//            // ⑥ 세션에 ID 저장
//            HttpSession session = request.getSession(true);
//            session.setAttribute("latestAnalysisId", analysis.getId());
//
//            return ResponseEntity.ok(Map.of(
//                    "success", true,
//                    "message", "분석이 완료되었습니다!",
//                    "analysisId", analysis.getId(),
//                    "redirectUrl", "/results"
//            ));
//
//        } catch (Exception e) {
//            log.error("파일 업로드 및 AI 분석 중 오류", e);
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//                    .body(Map.of("success", false, "error", "분석 중 오류가 발생했습니다."));
//        }
//    }
//
//    @GetMapping("/results")
//    public String results(HttpServletRequest request, Model model) {
//        HttpSession session = request.getSession(false);
//        if (session == null || session.getAttribute("latestAnalysisId") == null) {
//            return "redirect:/upload/page";
//        }
//
//        Long id = (Long) session.getAttribute("latestAnalysisId");
//        ColorAnalysis analysis = colorAnalysisService.getAnalysisById(id);
//        if (analysis == null) {
//            return "redirect:/upload/page";
//        }
//
//        model.addAttribute("analysis",    analysis);
//        model.addAttribute("colorType",   analysis.getColorType().getDisplayName());
//        model.addAttribute("description", analysis.getDescription());
//        model.addAttribute("confidence",  Math.round(analysis.getConfidence() * 100));
//        model.addAttribute("recommendations", analysis.getDominantColors());
//        model.addAttribute("uploadedFile",     analysis.getStoredFileName());
//
//        return "results";
//    }
//}


//package kr.ac.kopo.lyh.personalcolor.controller;
//
//import jakarta.servlet.http.HttpServletRequest;
//import jakarta.servlet.http.HttpSession;
//import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
//import kr.ac.kopo.lyh.personalcolor.entity.User;
//import kr.ac.kopo.lyh.personalcolor.service.AiModelClientService;
//import kr.ac.kopo.lyh.personalcolor.service.ColorAnalysisService;
//import kr.ac.kopo.lyh.personalcolor.service.FileStorageService;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.http.HttpStatus;
//import org.springframework.http.ResponseEntity;
//import org.springframework.stereotype.Controller;
//import org.springframework.ui.Model;
//import org.springframework.web.bind.annotation.*;
//import org.springframework.web.multipart.MultipartFile;
//
//import java.util.Map;
//import java.util.List;
//
//@Controller
//@RequiredArgsConstructor
//@CrossOrigin(origins = "*")
//@Slf4j
//public class UploadController {
//
//    private final FileStorageService fileStorageService;
//    private final ColorAnalysisService colorAnalysisService;
//    private final AiModelClientService aiModelClientService;
//    @GetMapping("/upload")
//    public String index() {
//        return "upload";
//    }
//
//    @PostMapping("/upload")
//    @ResponseBody
//    public ResponseEntity<?> uploadFile(@RequestParam("file") MultipartFile file,
//                                        HttpServletRequest request) {
//        try {
//            // 로그인 확인 (없으면 익명도 허용, 필요시 아래 주석 해제)
//            /*
//            HttpSession session = request.getSession(false);
//            if (session == null || session.getAttribute("user") == null) {
//                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
//                        .body(Map.of("success", false, "error", "로그인이 필요합니다."));
//            }
//            User user = (User) session.getAttribute("user");
//            */
//            User user = null; // 로그인 없이 사용 가능하게
//            HttpSession session0 = request.getSession(false);
//            if (session0 != null && session0.getAttribute("user") != null) {
//                user = (User) session0.getAttribute("user");
//            }
//            // 파일 검증
//            if (file.isEmpty()) {
//                return ResponseEntity.badRequest()
//                        .body(Map.of("success", false, "error", "파일이 비어있습니다."));
//            }
//
//            String contentType = file.getContentType();
//            if (contentType == null || !contentType.startsWith("image/")) {
//                return ResponseEntity.badRequest()
//                        .body(Map.of("success", false, "error", "이미지 파일만 업로드 가능합니다."));
//            }
//
//            // 파일 저장
//            String storedFileName = fileStorageService.storeFile(file);
//
//            Map<String, Object> aiResult = aiModelClientService.predictPersonalColor(storedFileName);
//            String prediction = (String) aiResult.get("prediction");
//            float confidence = ((Number) aiResult.get("confidence")).floatValue();
//            @SuppressWarnings("unchecked")
//            List<String> recommendations = (List<String>) aiResult.get("recommendations");
//
//            ColorAnalysis analysis = colorAnalysisService.saveAnalysis(
//                    user,
//                    file.getOriginalFilename(),
//                    storedFileName,
//                    prediction,
//                    confidence,
//                    recommendations
//            );
//
//            // 이미지 분석 수행
//            ColorAnalysis analysis = colorAnalysisService.analyzeImage(
//                    user,
//                    file.getOriginalFilename(),
//                    storedFileName
//            );
//
//            // 세션에 분석 결과 ID 저장 (로그인 없이 사용시 세션 생성)
//            HttpSession session = request.getSession(true);
//            session.setAttribute("latestAnalysisId", analysis.getId());
//
//            return ResponseEntity.ok(Map.of(
//                    "success", true,
//                    "message", "분석이 완료되었습니다!",
//                    "analysisId", analysis.getId(),
//                    "redirectUrl", "/results"
//            ));
//
//        } catch (Exception e) {
//            log.error("파일 업로드 및 분석 중 오류 발생", e);
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
//                    .body(Map.of("success", false, "error", "분석 중 오류가 발생했습니다."));
//        }
//    }
//
//    @GetMapping("/results")
//    public String results(HttpServletRequest request, Model model) {
//        HttpSession session = request.getSession(false);
//        if (session == null || session.getAttribute("latestAnalysisId") == null) {
//            return "redirect:/";
//        }
//
//        Long analysisId = (Long) session.getAttribute("latestAnalysisId");
//        ColorAnalysis analysis = colorAnalysisService.getAnalysisById(analysisId);
//
//        if (analysis == null) {
//            return "redirect:/";
//        }
//
//        model.addAttribute("analysis", analysis);
//        model.addAttribute("colorType", analysis.getColorType().getDisplayName());
//        model.addAttribute("description", analysis.getDescription());
//        model.addAttribute("confidence", Math.round(analysis.getConfidence() * 100));
//        model.addAttribute("uploadedFile", analysis.getStoredFileName());
//
//        return "results"; // results.html로 결과 표시
//    }
//}
