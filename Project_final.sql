
--#1) Does admission selectivity correlate with post-grad earnings?
 SELECT
    (
        (COUNT(*) * SUM(admission_rate_primary * earnings_median_4yr_primary))
        - (SUM(admission_rate_primary) * SUM(earnings_median_4yr_primary))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(admission_rate_primary, 2)) - POW(SUM(admission_rate_primary), 2))
        *
        SQRT(COUNT(*) * SUM(POW(earnings_median_4yr_primary, 2)) - POW(SUM(earnings_median_4yr_primary), 2))
    , 0) AS corr_admitrate_earnings,
    (
        (COUNT(*) * SUM(sat_average_context * earnings_median_4yr_primary))
        - (SUM(sat_average_context) * SUM(earnings_median_4yr_primary))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(sat_average_context, 2)) - POW(SUM(sat_average_context), 2))
        *
        SQRT(COUNT(*) * SUM(POW(earnings_median_4yr_primary, 2)) - POW(SUM(earnings_median_4yr_primary), 2))
    , 0) AS corr_sat_earnings,
    COUNT(*) AS n
FROM `college_value_combined_clean`
WHERE admission_rate_primary IS NOT NULL
  AND earnings_median_4yr_primary IS NOT NULL
  AND sat_average_context IS NOT NULL;
  
--#2) Debt burden vs earnings: worst "debt-to-earnings" ratio schools 
  SELECT
    INSTNM, STABBR, institution_control_label,
    debt_median_completers,
    earnings_median_4yr_primary,
    ROUND(debt_median_completers / NULLIF(earnings_median_4yr_primary, 0), 3) AS debt_to_earnings_ratio
FROM `college_value_combined_clean`
WHERE debt_median_completers IS NOT NULL
  AND earnings_median_4yr_primary IS NOT NULL
ORDER BY debt_to_earnings_ratio DESC
LIMIT 25; 

--# 3) Correlation between Pell share and net price by income bracket 
SELECT
    (
        (COUNT(*) * SUM(pell_share_primary * net_price_income_0_30k))
        - (SUM(pell_share_primary) * SUM(net_price_income_0_30k))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(pell_share_primary, 2)) - POW(SUM(pell_share_primary), 2))
        *
        SQRT(COUNT(*) * SUM(POW(net_price_income_0_30k, 2)) - POW(SUM(net_price_income_0_30k), 2))
    , 0) AS corr_pell_vs_low_income_price,
    (
        (COUNT(*) * SUM(pell_share_primary * net_price_income_over_110k))
        - (SUM(pell_share_primary) * SUM(net_price_income_over_110k))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(pell_share_primary, 2)) - POW(SUM(pell_share_primary), 2))
        *
        SQRT(COUNT(*) * SUM(POW(net_price_income_over_110k, 2)) - POW(SUM(net_price_income_over_110k), 2))
    , 0) AS corr_pell_vs_high_income_price,
    COUNT(*) AS n
FROM `college_value_combined_clean`
WHERE pell_share_primary IS NOT NULL
  AND net_price_income_0_30k IS NOT NULL
  AND net_price_income_over_110k IS NOT NULL;
  
  --#4) Value-for-money leaderboard: earnings relative to published cost 
  SELECT
    INSTNM, STABBR, institution_control_label,
    published_cost_best_available,
    earnings_median_4yr_primary,
    ROUND(earnings_median_4yr_primary / NULLIF(published_cost_best_available, 0), 2) AS earnings_per_dollar_cost
FROM `college_value_combined_clean`
WHERE published_cost_best_available > 0
  AND earnings_median_4yr_primary IS NOT NULL
ORDER BY earnings_per_dollar_cost DESC
LIMIT 25; 

--#5) APR score trend by NCAA division, 2004 -> 2014
SELECT
    NCAA_DIVISION,
    ROUND(AVG(`2004_SCORE`), 1) AS avg_score_2004,
    ROUND(AVG(`2009_SCORE`), 1) AS avg_score_2009,
    ROUND(AVG(FOURYEAR_SCORE), 1) AS avg_score_2014_4yr,
    ROUND(AVG(FOURYEAR_SCORE) - AVG(`2004_SCORE`), 1) AS change_2004_to_2014
FROM `database_clean`
WHERE `2004_SCORE` IS NOT NULL AND FOURYEAR_SCORE IS NOT NULL
GROUP BY NCAA_DIVISION
ORDER BY NCAA_DIVISION; 

--#6) Strongest correlation between athlete eligibility and retention, by sport
SELECT
    SPORT_NAME,
    (
        (COUNT(*) * SUM(FOURYEAR_ELIGIBILITY * FOURYEAR_RETENTION))
        - (SUM(FOURYEAR_ELIGIBILITY) * SUM(FOURYEAR_RETENTION))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(FOURYEAR_ELIGIBILITY, 2)) - POW(SUM(FOURYEAR_ELIGIBILITY), 2))
        *
        SQRT(COUNT(*) * SUM(POW(FOURYEAR_RETENTION, 2)) - POW(SUM(FOURYEAR_RETENTION), 2))
    , 0) AS corr_eligibility_retention,
    ROUND(AVG(FOURYEAR_ELIGIBILITY), 3) AS avg_eligibility,
    ROUND(AVG(FOURYEAR_RETENTION), 3) AS avg_retention,
    COUNT(*) AS n_programs
FROM `database_clean`
WHERE FOURYEAR_ELIGIBILITY IS NOT NULL AND FOURYEAR_RETENTION IS NOT NULL
GROUP BY SPORT_NAME
HAVING COUNT(*) > 30
ORDER BY corr_eligibility_retention ASC
LIMIT 15;

--#7) Cross-dataset: school academic outcomes vs athlete APR (joined on name) 
SELECT
    (
        (COUNT(*) * SUM(cv.completion_rate_150_primary * a.FOURYEAR_SCORE))
        - (SUM(cv.completion_rate_150_primary) * SUM(a.FOURYEAR_SCORE))
    ) /
    NULLIF(
        SQRT(COUNT(*) * SUM(POW(cv.completion_rate_150_primary, 2)) - POW(SUM(cv.completion_rate_150_primary), 2))
        *
        SQRT(COUNT(*) * SUM(POW(a.FOURYEAR_SCORE, 2)) - POW(SUM(a.FOURYEAR_SCORE), 2))
    , 0) AS corr_school_completion_vs_athlete_apr,
    COUNT(*) AS n_matched_rows
FROM `college_value_combined_clean` cv
JOIN `database_clean` a
  ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(a.SCHOOL_NAME))
WHERE cv.completion_rate_150_primary IS NOT NULL
  AND a.FOURYEAR_SCORE IS NOT NULL;

  
--#8) Sports data coverage: weakest coverage areas
SELECT
    sport, gender, division,
    covered, universe, pct
FROM `coverage_report`
WHERE pct < 50
ORDER BY pct ASC, universe DESC
LIMIT 30; 

--#9) Which sports account for the most missing coverage overall? 
SELECT
    sport,
    COUNT(*) AS missing_school_count,
    COUNT(DISTINCT division) AS divisions_affected
FROM `coverage_report`
GROUP BY sport
ORDER BY missing_school_count DESC
LIMIT 15; 

--#10) Are missing-coverage schools disproportionately smaller/lower-resourced?
SELECT
    cm.division,
    COUNT(*) AS missing_count,
    ROUND(AVG(cv.UGDS), 0) AS avg_undergrad_enrollment,
    ROUND(AVG(cv.ADM_RATE), 3) AS avg_admit_rate
FROM `coverage_report` cm
JOIN `college_value_combined_clean` cv
  ON LOWER(TRIM(cm.official_name)) = LOWER(TRIM(cv.INSTNM))
GROUP BY cm.division
ORDER BY missing_count DESC;


--#11)  Master combined view: one row per school, blending academic outcomes with an aggregated athletics profile
SELECT
    cv.INSTNM,
    cv.STABBR,
    cv.institution_control_label,
    cv.UGDS AS undergrad_enrollment,
    cv.ADM_RATE AS admission_rate,
    cv.earnings_median_4yr_primary,
    cv.completion_rate_150_primary AS school_completion_rate,
    ath.avg_athlete_apr_score,
    ath.avg_athlete_eligibility,
    ath.avg_athlete_retention,
    ath.sports_offered_count
FROM `college_value_combined_clean` cv
LEFT JOIN (
    SELECT
        SCHOOL_NAME,
        ROUND(AVG(FOURYEAR_SCORE), 1) AS avg_athlete_apr_score,
        ROUND(AVG(FOURYEAR_ELIGIBILITY), 3) AS avg_athlete_eligibility,
        ROUND(AVG(FOURYEAR_RETENTION), 3) AS avg_athlete_retention,
        COUNT(DISTINCT SPORT_NAME) AS sports_offered_count
    FROM `database_clean`
    GROUP BY SCHOOL_NAME
) ath ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(ath.SCHOOL_NAME))
ORDER BY cv.earnings_median_4yr_primary DESC
LIMIT 50;

--#B) Do schools with more sports programs have better academic outcomes? (breadth of athletics vs institutional completion rate)
SELECT
    sport_count_bucket,
    COUNT(*) AS school_count,
    ROUND(AVG(cv.completion_rate_150_primary), 3) AS avg_completion_rate,
    ROUND(AVG(cv.earnings_median_4yr_primary), 0) AS avg_earnings
FROM `college_value_combined_clean` cv
JOIN (
    SELECT
        SCHOOL_NAME,
        COUNT(DISTINCT SPORT_NAME) AS n_sports,
        CASE
            WHEN COUNT(DISTINCT SPORT_NAME) <= 5  THEN '1-5 sports'
            WHEN COUNT(DISTINCT SPORT_NAME) <= 10 THEN '6-10 sports'
            WHEN COUNT(DISTINCT SPORT_NAME) <= 15 THEN '11-15 sports'
            ELSE '16+ sports'
        END AS sport_count_bucket
    FROM `database_clean`
    GROUP BY SCHOOL_NAME
) sp ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(sp.SCHOOL_NAME))
WHERE cv.completion_rate_150_primary IS NOT NULL
GROUP BY sport_count_bucket
ORDER BY avg_completion_rate DESC;

--# C) Do NCAA divisions map to different earnings/debt outcomes at the school level?  (school's most common division vs its academic-outcome profile)
SELECT
    div.NCAA_DIVISION,
    COUNT(DISTINCT cv.INSTNM) AS schools_matched,
    ROUND(AVG(cv.earnings_median_4yr_primary), 0) AS avg_earnings,
    ROUND(AVG(cv.debt_median_completers), 0) AS avg_debt,
    ROUND(AVG(cv.admission_rate_primary), 3) AS avg_admit_rate
FROM `college_value_combined_clean` cv
JOIN (
    SELECT SCHOOL_NAME, NCAA_DIVISION,
        ROW_NUMBER() OVER (PARTITION BY SCHOOL_NAME ORDER BY school_count DESC) AS rn
    FROM (
        SELECT SCHOOL_NAME, NCAA_DIVISION, COUNT(*) AS school_count
        FROM `database_clean`
        GROUP BY SCHOOL_NAME, NCAA_DIVISION
    ) counts
) div
  ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(div.SCHOOL_NAME))
  AND div.rn = 1
WHERE cv.earnings_median_4yr_primary IS NOT NULL
GROUP BY div.NCAA_DIVISION
ORDER BY avg_earnings DESC;


--#D) Coverage gaps weighted by school value: are we missing data on --high-earning / selective schools, or mostly lower-profile ones?
SELECT
    cm.division,
    cm.sport,
    COUNT(*) AS missing_count,
    ROUND(AVG(cv.earnings_median_4yr_primary), 0) AS avg_earnings_of_missing_schools,
    ROUND(AVG(cv.admission_rate_primary), 3) AS avg_admit_rate_of_missing_schools
FROM `coverage_missing` cm
JOIN `college_value_combined_clean` cv
  ON LOWER(TRIM(cm.official_name)) = LOWER(TRIM(cv.INSTNM))
WHERE cv.earnings_median_4yr_primary IS NOT NULL
GROUP BY cm.division, cm.sport
ORDER BY missing_count DESC
LIMIT 20;


--#E) Full three-way join: coverage completeness + athletics profile + academic outcomes, by division
SELECT
    cr.division,
    ROUND(AVG(cr.pct), 1) AS avg_data_coverage_pct,
    ROUND(AVG(ath.avg_apr), 1) AS avg_athlete_apr,
    ROUND(AVG(cv.earnings_median_4yr_primary), 0) AS avg_school_earnings
FROM `coverage_report` cr
LEFT JOIN (
    SELECT NCAA_DIVISION, SCHOOL_NAME, AVG(FOURYEAR_SCORE) AS avg_apr
    FROM `database_clean`
    GROUP BY NCAA_DIVISION, SCHOOL_NAME
) ath
  ON cr.division = ath.NCAA_DIVISION
LEFT JOIN `college_value_combined_clean` cv
  ON LOWER(TRIM(ath.SCHOOL_NAME)) = LOWER(TRIM(cv.INSTNM))
GROUP BY cr.division
ORDER BY avg_data_coverage_pct DESC;



--#F) Name-matching health check: run this FIRST to see how well the join key (school name) actually lines up across datasets
 SELECT
    (SELECT COUNT(DISTINCT INSTNM) FROM `college_value_combined_clean`) AS total_schools_in_value_data,
    (SELECT COUNT(DISTINCT SCHOOL_NAME) FROM `database_clean`) AS total_schools_in_athletics_data,
    (
        SELECT COUNT(DISTINCT cv.INSTNM)
        FROM `college_value_combined_clean` cv
        JOIN `database_clean` a
          ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(a.SCHOOL_NAME))
    ) AS matched_schools,
    (
        SELECT COUNT(DISTINCT cv.INSTNM)
        FROM `college_value_combined_clean` cv
        LEFT JOIN `database_clean` a
          ON LOWER(TRIM(cv.INSTNM)) = LOWER(TRIM(a.SCHOOL_NAME))
        WHERE a.SCHOOL_NAME IS NULL
    ) AS unmatched_value_schools;

