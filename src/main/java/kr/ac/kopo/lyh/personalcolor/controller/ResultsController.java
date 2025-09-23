//package kr.ac.kopo.lyh.personalcolor.controller;
//
//import com.fasterxml.jackson.core.type.TypeReference;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import jakarta.servlet.http.HttpSession;
//import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
//import kr.ac.kopo.lyh.personalcolor.service.ColorAnalysisService;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.stereotype.Controller;
//import org.springframework.web.bind.annotation.GetMapping;
//import org.springframework.ui.Model;
//
//import java.util.Collections;
//import java.util.List;
//import java.util.Map;
//import java.util.HashMap;
//import java.util.ArrayList;
//
//@Slf4j
//@Controller
//public class ResultsController {
//
//    private final ColorAnalysisService colorAnalysisService;
//
//    public ResultsController(ColorAnalysisService colorAnalysisService) {
//        this.colorAnalysisService = colorAnalysisService;
//    }
//
//    @GetMapping("/results")
//    public String showResults(HttpSession session, Model model) {
//        Long analysisId = (Long) session.getAttribute("latestAnalysisId");
//        if (analysisId == null) {
//            model.addAttribute("error", "분석 결과가 없습니다. 다시 업로드해 주세요.");
//            return "redirect:/upload";
//        }
//
//        try {
//            ColorAnalysis analysis = colorAnalysisService.findById(analysisId);
//            List<String> recommendations = parseRecommendations(analysis.getDominantColors());
//
//            // 기존 데이터
//            model.addAttribute("analysis", analysis);
//            model.addAttribute("recommendations", recommendations);
//            model.addAttribute("description", analysis.getDescription());
//            model.addAttribute("confidence", Math.round(analysis.getConfidence() * 100));
//            model.addAttribute("colorType", analysis.getColorType().getDisplayName());
//            model.addAttribute("storedFileName", analysis.getStoredFileName());
//
//            // 그래프를 위한 추가 데이터
//            model.addAttribute("typeComparisonData", createTypeComparisonData(analysis));
//
//        } catch (Exception e) {
//            log.error("분석 결과 조회 실패: {}", analysisId, e);
//            model.addAttribute("error", "분석 결과를 불러올 수 없습니다.");
//            return "error";
//        }
//
//        return "results";
//    }
//
//    private List<String> parseRecommendations(String dominantColorsJson) {
//        try {
//            return new ObjectMapper().readValue(
//                    dominantColorsJson, new TypeReference<List<String>>() {});
//        } catch (Exception e) {
//            return Collections.emptyList();
//        }
//    }
//
//    /**
//     * 퍼스널 컬러 타입 비교 데이터 생성
//     */
//    private Map<String, Object> createTypeComparisonData(ColorAnalysis analysis) {
//        Map<String, Object> data = new HashMap<>();
//
//        String currentType = analysis.getColorType().name();
//        double confidence = analysis.getConfidence();
//
//        // 각 타입별 유사도 계산 (실제로는 AI 분석 결과에서 가져와야 함)
//        Map<String, Double> similarities = new HashMap<>();
//        similarities.put("SPRING", currentType.equals("SPRING") ? confidence : Math.random() * 0.3 + 0.1);
//        similarities.put("SUMMER", currentType.equals("SUMMER") ? confidence : Math.random() * 0.3 + 0.1);
//        similarities.put("AUTUMN", currentType.equals("AUTUMN") ? confidence : Math.random() * 0.3 + 0.1);
//        similarities.put("WINTER", currentType.equals("WINTER") ? confidence : Math.random() * 0.3 + 0.1);
//
//        data.put("currentType", currentType);
//        data.put("similarities", similarities);
//        data.put("typeLabels", Map.of(
//            "SPRING", "봄 웜톤",
//            "SUMMER", "여름 쿨톤",
//            "AUTUMN", "가을 웜톤",
//            "WINTER", "겨울 쿨톤"
//        ));
//
//        return data;
//    }
//
//}

package kr.ac.kopo.lyh.personalcolor.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpSession;
import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
import kr.ac.kopo.lyh.personalcolor.service.ColorAnalysisService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.ui.Model;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Slf4j
@Controller
public class ResultsController {

    private final ColorAnalysisService colorAnalysisService;

    public ResultsController(ColorAnalysisService colorAnalysisService) {
        this.colorAnalysisService = colorAnalysisService;
    }

    @GetMapping("/results")
    public String showResults(HttpSession session, Model model) {
        Long analysisId = (Long) session.getAttribute("latestAnalysisId");
        if (analysisId == null) {
            model.addAttribute("error", "분석 결과가 없습니다. 다시 업로드해 주세요.");
            return "redirect:/upload";
        }

        try {
            ColorAnalysis analysis = colorAnalysisService.findById(analysisId);
            List<String> recommendations = parseRecommendations(analysis.getDominantColors());

            // 기존 데이터
            model.addAttribute("analysis", analysis);
            model.addAttribute("recommendations", recommendations);
            model.addAttribute("description", analysis.getDescription());
            model.addAttribute("confidence", Math.round(analysis.getConfidence() * 100));

            // 🔹 수정: colorType을 name().toLowerCase() 로 전달
            model.addAttribute("colorType", analysis.getColorType().name().toLowerCase());

            model.addAttribute("storedFileName", analysis.getStoredFileName());

            // 그래프를 위한 추가 데이터
            model.addAttribute("typeComparisonData", createTypeComparisonData(analysis));

        } catch (Exception e) {
            log.error("분석 결과 조회 실패: {}", analysisId, e);
            model.addAttribute("error", "분석 결과를 불러올 수 없습니다.");
            return "error";
        }

        return "results";
    }

    private List<String> parseRecommendations(String dominantColorsJson) {
        try {
            return new ObjectMapper().readValue(
                    dominantColorsJson, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    /**
     * 퍼스널 컬러 타입 비교 데이터 생성
     */
    private Map<String, Object> createTypeComparisonData(ColorAnalysis analysis) {
        Map<String, Object> data = new HashMap<>();

        String currentType = analysis.getColorType().name();
        double confidence = analysis.getConfidence();

        // 각 타입별 유사도 계산 (실제로는 AI 분석 결과에서 가져와야 함)
        Map<String, Double> similarities = new HashMap<>();
        similarities.put("SPRING", currentType.equals("SPRING") ? confidence : Math.random() * 0.3 + 0.1);
        similarities.put("SUMMER", currentType.equals("SUMMER") ? confidence : Math.random() * 0.3 + 0.1);
        similarities.put("AUTUMN", currentType.equals("AUTUMN") ? confidence : Math.random() * 0.3 + 0.1);
        similarities.put("WINTER", currentType.equals("WINTER") ? confidence : Math.random() * 0.3 + 0.1);

        data.put("currentType", currentType);
        data.put("similarities", similarities);
        data.put("typeLabels", Map.of(
                "SPRING", "봄 웜톤",
                "SUMMER", "여름 쿨톤",
                "AUTUMN", "가을 웜톤",
                "WINTER", "겨울 쿨톤"
        ));

        return data;
    }

}