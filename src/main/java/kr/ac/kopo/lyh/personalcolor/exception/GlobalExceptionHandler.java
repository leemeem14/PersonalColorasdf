package kr.ac.kopo.lyh.personalcolor.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * 파비콘 등 정적 리소스 미존재 처리
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Void> handleNoResourceFound(NoResourceFoundException e) {
        log.debug("리소스 미존재: {}", e.getMessage());
        return ResponseEntity.noContent().build();
    }

    /**
     * AI 추론 예외 처리
     */
    @ExceptionHandler(AiInferenceException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleAiInferenceException(AiInferenceException e) {
        log.error("AI 추론 오류: {} (코드: {})", e.getMessage(), e.getErrorCode(), e);

        HttpStatus status = determineHttpStatus(e.getErrorCode());

        return ResponseEntity.status(status)
                .body(createErrorResponse(
                        e.getMessage(),
                        e.getErrorCode(),
                        status.value()
                ));
    }

    /**
     * 잘못된 인자 예외 처리
     */
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleIllegalArgumentException(IllegalArgumentException e) {
        log.error("잘못된 요청: {}", e.getMessage());

        return ResponseEntity.badRequest()
                .body(createErrorResponse(
                        e.getMessage(),
                        "INVALID_ARGUMENT",
                        HttpStatus.BAD_REQUEST.value()
                ));
    }

    /**
     * 유효성 검증 실패 예외 처리
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleValidationException(MethodArgumentNotValidException e) {
        log.error("유효성 검증 실패: {}", e.getMessage());

        Map<String, String> fieldErrors = new HashMap<>();
        e.getBindingResult().getFieldErrors().forEach(error ->
                fieldErrors.put(error.getField(), error.getDefaultMessage())
        );

        Map<String, Object> errorResponse = createErrorResponse(
                "입력값 검증에 실패했습니다.",
                "VALIDATION_ERROR",
                HttpStatus.BAD_REQUEST.value()
        );
        errorResponse.put("fieldErrors", fieldErrors);

        return ResponseEntity.badRequest().body(errorResponse);
    }

    /**
     * 파일 크기 초과 예외 처리
     */
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException e) {
        log.error("파일 크기 초과: {}", e.getMessage());

        return ResponseEntity.badRequest()
                .body(createErrorResponse(
                        "파일 크기가 너무 큽니다. 최대 10MB까지 업로드 가능합니다.",
                        "FILE_SIZE_EXCEEDED",
                        HttpStatus.BAD_REQUEST.value()
                ));
    }

    /**
     * 네트워크 연결 오류 예외 처리
     */
    @ExceptionHandler(ResourceAccessException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleResourceAccessException(ResourceAccessException e) {
        log.error("네트워크 연결 오류: {}", e.getMessage(), e);

        String userMessage = getUserFriendlyMessage(e.getMessage());

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(createErrorResponse(
                        userMessage,
                        "NETWORK_ERROR",
                        HttpStatus.SERVICE_UNAVAILABLE.value()
                ));
    }

    /**
     * 런타임 예외 처리
     */
    @ExceptionHandler(RuntimeException.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException e) {
        log.error("런타임 오류: {}", e.getMessage(), e);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(createErrorResponse(
                        "처리 중 오류가 발생했습니다.",
                        "RUNTIME_ERROR",
                        HttpStatus.INTERNAL_SERVER_ERROR.value()
                ));
    }

    /**
     * 모든 예외의 최종 처리
     */
    @ExceptionHandler(Exception.class)
    @ResponseBody
    public ResponseEntity<Map<String, Object>> handleException(Exception e) {
        log.error("서버 오류 발생: {}", e.getMessage(), e);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(createErrorResponse(
                        "서버 내부 오류가 발생했습니다. 관리자에게 문의해주세요.",
                        "INTERNAL_SERVER_ERROR",
                        HttpStatus.INTERNAL_SERVER_ERROR.value()
                ));
    }

    /**
     * 에러 응답 생성 (수정된 버전)
     */
    private Map<String, Object> createErrorResponse(String message, String errorCode, int statusCode) {
        Map<String, Object> errorResponse = new HashMap<>();
        errorResponse.put("success", false);
        errorResponse.put("error", message);
        errorResponse.put("errorCode", errorCode);
        errorResponse.put("statusCode", statusCode);
        errorResponse.put("timestamp", LocalDateTime.now().toString());
        errorResponse.put("path", getCurrentRequestPath());
        return errorResponse;
    }

    /**
     * 사용자 친화적 메시지 생성
     */
    private String getUserFriendlyMessage(String originalMessage) {
        if (originalMessage == null) {
            return "외부 서비스 연결 중 오류가 발생했습니다.";
        }

        if (originalMessage.contains("Read timed out")) {
            return "AI 서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.";
        }

        if (originalMessage.contains("Connection refused")) {
            return "AI 서버에 연결할 수 없습니다. 관리자에게 문의해주세요.";
        }

        return "외부 서비스 연결 중 오류가 발생했습니다.";
    }

    /**
     * 에러 코드에 따른 HTTP 상태 결정
     */
    private HttpStatus determineHttpStatus(String errorCode) {
        return switch (errorCode) {
            case "AI_INFERENCE_ERROR", "AI_SERVER_ERROR" -> HttpStatus.SERVICE_UNAVAILABLE;
            case "AI_TIMEOUT_ERROR" -> HttpStatus.GATEWAY_TIMEOUT;
            case "INVALID_INPUT" -> HttpStatus.BAD_REQUEST;
            case "UNAUTHORIZED" -> HttpStatus.FORBIDDEN;
            case "RESOURCE_NOT_FOUND" -> HttpStatus.NOT_FOUND;
            default -> HttpStatus.INTERNAL_SERVER_ERROR;
        };
    }

    /**
     * 현재 요청 경로 조회
     */
    private String getCurrentRequestPath() {
        try {
            return "/api/current-path";
        } catch (Exception e) {
            return "/unknown";
        }
    }
}
