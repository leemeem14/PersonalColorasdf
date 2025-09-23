package kr.ac.kopo.lyh.personalcolor.service;

import kr.ac.kopo.lyh.personalcolor.entity.ColorType;
import kr.ac.kopo.lyh.personalcolor.exception.AiInferenceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.nio.file.*;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiModelClientService {

    private final WebClient webClient;

    @Value("${app.upload.path}")
    private String uploadDir;

    public Mono<Map<String,Object>> predictPersonalColor(String storedFileName) {
        Path path = Paths.get(uploadDir, storedFileName);
        if (!Files.exists(path)) {
            return Mono.error(new AiInferenceException("파일 없음: "+storedFileName));
        }

        return Mono.fromCallable(() -> Files.readAllBytes(path))
                .map(bytes -> Base64.getEncoder().encodeToString(bytes))
                .map(b64 -> Map.<String,String>of(
                        "image", "data:" + mimeType(storedFileName) + ";base64," + b64))
                .flatMap(body -> webClient.post()
                        .uri("/api/analyze")
                        .header(HttpHeaders.CONTENT_TYPE, "application/json")
                        .bodyValue(body)
                        .retrieve()
//                        .onStatus(HttpStatus::isError, resp ->
//                                resp.bodyToMono(String.class)
//                                        .map(err->new AiInferenceException("AI 서버 오류: "+err))
//                                        .flatMap(Mono::error)
//                        )
                        .bodyToMono(new ParameterizedTypeReference<Map<String,Object>>() {})
                        .timeout(Duration.ofSeconds(60))
                        .doOnError(e -> log.error("AI 분석 실패: {}", e.getMessage()))
                );
    }

    private String mimeType(String fn) {
        String ext = fn.substring(fn.lastIndexOf('.')+1).toLowerCase();
        return switch(ext){
            case "jpg","jpeg" -> "image/jpeg";
            case "png" -> "image/png";
            default -> "application/octet-stream";
        };
    }
}

//import lombok.RequiredArgsConstructor;
//import lombok.SneakyThrows;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.core.io.ByteArrayResource;
//import org.springframework.core.io.FileSystemResource;
//import org.springframework.http.*;
//import org.springframework.stereotype.Service;
//import org.springframework.util.LinkedMultiValueMap;
//import org.springframework.util.MultiValueMap;
//import org.springframework.web.client.RestTemplate;
//
//import java.io.IOException;
//import java.nio.file.Files;
//import java.nio.file.Path;
//import java.nio.file.Paths;
//import java.util.*;
//import java.util.Base64;
//import java.util.HashMap;
//import java.util.Map;
//
//
//@Service
//@RequiredArgsConstructor
//public class AiModelClientService {
//    private final RestTemplate restTemplate;
//    @Value("${ai.server.url}") private String aiServerUrl;
//    @Value("${app.upload.path:uploads}") private String uploadDir;
//
//    @SneakyThrows
//    public Map<String,Object> predictPersonalColor(String storedFileName) {
//        Path p = Paths.get(uploadDir).resolve(storedFileName);
//        byte[] bytes = Files.readAllBytes(p);
//        String base64 = Base64.getEncoder().encodeToString(bytes);
//
//        HttpHeaders h = new HttpHeaders();
//        h.setContentType(MediaType.APPLICATION_JSON);
//        Map<String,String> body = Map.of("image","data:image/png;base64,"+base64);
//
//        ResponseEntity<Map> r = restTemplate.postForEntity(
//                aiServerUrl + "/api/analyze",
//                new HttpEntity<>(body,h), Map.class);
//        return r.getBody();
//    }
//}
//import java.time.Duration;
//import java.util.Base64;
//import java.util.Map;
//import java.nio.file.Files;
//import java.nio.file.Path;
//import java.nio.file.Paths;
//
//import kr.ac.kopo.lyh.personalcolor.exception.AiInferenceException;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.core.ParameterizedTypeReference;
//import org.springframework.http.*;
//import org.springframework.stereotype.Service;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.web.reactive.function.client.WebClient;
//import reactor.core.publisher.Mono;
//
//@Service
//@RequiredArgsConstructor
//@Slf4j
//public class AiModelClientService {
//    private final WebClient webClient;  // RestTemplate 대신 WebClient
//
//    @Value("${app.upload.path:uploads}")
//    private String uploadDir;
//
//    public Mono<Map<String, Object>> predictPersonalColor(String storedFileName) {
//        Path filePath = Paths.get(uploadDir, storedFileName);
//        if (!Files.exists(filePath)) {
//            return Mono.error(new AiInferenceException("파일을 찾을 수 없습니다: " + storedFileName));
//        }
//
//        return Mono.fromCallable(() -> Files.readAllBytes(filePath))
//                .map(bytes -> Base64.getEncoder().encodeToString(bytes))
//                .map(base64 -> {
//                    String mime = determineMimeType(storedFileName);
//                    return Map.<String, String>of("image", "data:" + mime + ";base64," + base64);
//                })
//                .flatMap(body -> webClient.post()
//                        .uri("/api/analyze")
//                        .bodyValue(body)
//                        .retrieve()
//                        .onStatus(
//                                status -> HttpStatus.valueOf(status.value()).isError(),
//                                resp -> resp.bodyToMono(String.class)
//                                        .map(err -> new AiInferenceException("AI 서버 오류: " + err))
//                                        .flatMap(Mono::error)
//                        )
//                        .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
//                        .timeout(Duration.ofSeconds(60))
//                        .doOnError(e -> log.error("AI 분석 중 오류 ({}): {}", storedFileName, e.getMessage()))
//                );
//    }
//
//    private String determineMimeType(String fileName) {
//        String ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
//        return switch (ext) {
//            case "jpg","jpeg" -> "image/jpeg";
//            case "png"        -> "image/png";
//            case "gif"        -> "image/gif";
//            case "bmp"        -> "image/bmp";
//            case "webp"       -> "image/webp";
//            default           -> "application/octet-stream";
//        };
//    }
//}

//@Service
//public class AiModelClientService {
//
//    @Value("${ai.server.url}")
//    private String aiServerUrl;  // ex: http://43.201.28.17:
//
//    private static RestTemplate restTemplate;
//
//    public AiModelClientService(RestTemplate rt) { this.restTemplate = rt; }
//
//    public Map<String, Object> predictPersonalColor(String storedFilePath) {
//        String url = aiServerUrl + "/api/analyze";
//        try {
//            // 파일→Base64
//            byte[] bytes = Files.readAllBytes(Paths.get(storedFilePath));
//            String base64 = Base64.getEncoder().encodeToString(bytes);
//            Map<String,String> body = new HashMap<>();
//            body.put("image", "data:image/png;base64," + base64);
//
//            HttpHeaders headers = new HttpHeaders();
//            headers.setContentType(MediaType.APPLICATION_JSON);
//            HttpEntity<Map<String,String>> req = new HttpEntity<>(body, headers);
//
//            ResponseEntity<Map> resp = restTemplate.postForEntity(url, req, Map.class);
//            if (resp.getStatusCode() == HttpStatus.OK) {
//                return resp.getBody();
//            } else {
//                throw new RuntimeException("Flask 분석 실패: " + resp.getStatusCode());
//            }
//        } catch (Exception e) {
//            throw new RuntimeException("Flask 통신 오류: " + e.getMessage(), e);
//        }
//    }
//}