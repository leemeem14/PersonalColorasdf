package kr.ac.kopo.lyh.personalcolor.exception;

import lombok.Getter;

/**
 * AI 추론 과정에서 발생하는 예외를 처리하는 커스텀 예외 클래스
 */
@Getter
public class AiInferenceException extends RuntimeException {

    private final String errorCode;

    public AiInferenceException(String message) {
        super(message);
        this.errorCode = "AI_INFERENCE_ERROR";
    }

    public AiInferenceException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "AI_INFERENCE_ERROR";
    }

    public AiInferenceException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
    }

    public AiInferenceException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }

}