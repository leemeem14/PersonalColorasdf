package kr.ac.kopo.lyh.personalcolor.repository;

import kr.ac.kopo.lyh.personalcolor.entity.ColorAnalysis;
import kr.ac.kopo.lyh.personalcolor.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public interface ColorAnalysisRepository extends JpaRepository<ColorAnalysis, Long> {

    /**
     * 특정 사용자의 모든 분석 결과를 최신순으로 조회
     */
    List<ColorAnalysis> findAllByUserOrderByAnalyzedAtDesc(User user);

    /**
     * 특정 사용자의 분석 결과를 페이지 단위로 최신순 조회
     */
    Page<ColorAnalysis> findAllByUserOrderByAnalyzedAtDesc(User user, Pageable pageable);

    /**
     * 특정 사용자의 가장 최신 분석 결과 1개 조회
     */
    Optional<ColorAnalysis> findFirstByUserOrderByAnalyzedAtDesc(User user);

    /**
     * 특정 사용자의, 지정된 기간(startDate~endDate) 내의 분석 결과를 최신순으로 조회
     */
    @Query("""
        SELECT ca
          FROM ColorAnalysis ca
         WHERE ca.user = :user
           AND ca.analyzedAt BETWEEN :startDate AND :endDate
      ORDER BY ca.analyzedAt DESC
        """)
    List<ColorAnalysis> findByUserAndAnalyzedAtBetween(
            @Param("user")      User user,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate")   LocalDateTime endDate
    );

    /**
     * 모든 분석 결과를 컬러 타입별로 집계하여
     * Map&lt;"colorType", ColorType&gt; 와 Map&lt;"count", Long&gt; 구조로 반환
     */
    @Query("""
        SELECT new map(ca.colorType as colorType, COUNT(ca) as count)
          FROM ColorAnalysis ca
      GROUP BY ca.colorType
        """)
    List<Map<String, Object>> getColorTypeStatistics();

    /**
     * 특정 사용자의 전체 분석 건수 조회
     */
    long countByUser(User user);
}
