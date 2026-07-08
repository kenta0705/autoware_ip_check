-- Implementation-grounded Google Patents Public Data candidate search for
-- Autoware behavior_path_lane_change_module snapshot.
-- Technical triage only: results are candidates for human IP-professional review.
-- Not executed by this repository; validate with BigQuery dry run or LIMIT 10 before use.

CREATE TEMP FUNCTION norm(s STRING) AS (LOWER(IFNULL(s, '')));

CREATE TEMP FUNCTION text_has(term STRING, texts ARRAY<STRUCT<language STRING, text STRING, truncated BOOL>>) AS (
  EXISTS (
    SELECT 1
    FROM UNNEST(texts) AS t
    WHERE norm(t.text) LIKE CONCAT('%', norm(term), '%')
  )
);

CREATE TEMP FUNCTION any_text_has(
  term STRING,
  title_localized ARRAY<STRUCT<language STRING, text STRING, truncated BOOL>>,
  abstract_localized ARRAY<STRUCT<language STRING, text STRING, truncated BOOL>>
) AS (
  text_has(term, title_localized)
  OR text_has(term, abstract_localized)
);

WITH implementation_terms AS (
  SELECT 'lane-change candidate path sampling' AS feature, [
    'lane change candidate path',
    'lane change path generation',
    'candidate trajectory lane change',
    'prepare phase lateral acceleration',
    'longitudinal acceleration sampling',
    'path shifter lane change',
    'frenet lane change',
    'terminal lane change',
    '車線変更 候補経路',
    '車線変更 経路生成',
    '準備区間 横加速度',
    '縦加速度 サンプリング',
    'フレネ 車線変更',
    '終端 車線変更'
  ] AS terms
  UNION ALL
  SELECT 'predicted-object lane-change filtering', [
    'predicted object lane change',
    'target lane leading vehicle',
    'target lane trailing vehicle',
    'stopped object lane change',
    'oncoming object yaw threshold',
    'lane expansion object filtering',
    '予測物体 車線変更',
    '目標車線 先行車',
    '目標車線 後続車',
    '停止物体 車線変更',
    'ヨー角 閾値 対向車',
    '車線拡張 物体 フィルタリング'
  ]
  UNION ALL
  SELECT 'predicted-path collision and RSS safety margins', [
    'ego predicted path object predicted path',
    'predicted path collision check',
    'object polygon collision lane change',
    'RSS safety distance lane change',
    'safe braking distance lane change',
    'current lane target lane collision polygon',
    '自車予測経路 物体予測経路',
    '予測経路 衝突判定',
    '物体 ポリゴン 衝突 車線変更',
    'RSS 安全距離 車線変更',
    '安全制動距離 車線変更',
    '現在車線 目標車線 衝突 ポリゴン'
  ]
  UNION ALL
  SELECT 'approval cancel abort fallback state machine', [
    'approved lane change path safety monitoring',
    'unsafe hysteresis lane change',
    'lane change cancel prepare phase',
    'lane change abort return to current lane',
    'abort path lateral jerk',
    'force deactivation lane change',
    'stop fallback lane change',
    '承認済み 車線変更 経路 安全監視',
    '車線変更 ヒステリシス',
    '車線変更 キャンセル 準備区間',
    '車線変更 アボート 現在車線 復帰',
    'アボート経路 横ジャーク',
    '車線変更 強制解除',
    '車線変更 停止 フォールバック'
  ]
  UNION ALL
  SELECT 'regulatory and blocking-object stop behavior', [
    'lane change crosswalk intersection traffic light',
    'regulatory element lane change suppression',
    'lane change stop point blocking object',
    'terminal boundary stop lane change',
    'stuck detection stopped vehicle lane change',
    '車線変更 横断歩道 交差点 信号機',
    '規制要素 車線変更 抑制',
    '車線変更 停止位置 障害物',
    '終端境界 停止 車線変更',
    'スタック検出 停止車両 車線変更'
  ]
),
publication_hits AS (
  SELECT
    p.publication_number,
    p.application_number,
    p.publication_date,
    p.filing_date,
    (SELECT t.text FROM UNNEST(p.title_localized) AS t LIMIT 1) AS title,
    (SELECT a.text FROM UNNEST(p.abstract_localized) AS a LIMIT 1) AS abstract,
    ARRAY(SELECT a.name FROM UNNEST(p.assignee_harmonized) AS a LIMIT 10) AS assignees,
    ARRAY(SELECT c.code FROM UNNEST(p.cpc) AS c LIMIT 20) AS cpc_codes,
    ARRAY_AGG(DISTINCT it.feature IGNORE NULLS) AS matched_features,
    ARRAY_AGG(DISTINCT term IGNORE NULLS LIMIT 40) AS matched_terms,
    COUNT(DISTINCT term) AS matched_term_count,
    COUNT(DISTINCT it.feature) AS matched_feature_count,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B60W30')), 1, 0) AS cpc_b60w30,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B60W40')), 1, 0) AS cpc_b60w40,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B60W50')), 1, 0) AS cpc_b60w50,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'G05D1')), 1, 0) AS cpc_g05d1,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B62D15')), 1, 0) AS cpc_b62d15,
    IF(EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'G08G1')), 1, 0) AS cpc_g08g1
  FROM `patents-public-data.patents.publications` AS p
  CROSS JOIN implementation_terms AS it
  CROSS JOIN UNNEST(it.terms) AS term
  WHERE
    any_text_has(term, p.title_localized, p.abstract_localized)
    AND (
      EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B60W'))
      OR EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'G05D1'))
      OR EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'B62D15'))
      OR EXISTS (SELECT 1 FROM UNNEST(p.cpc) AS c WHERE STARTS_WITH(c.code, 'G08G1'))
    )
    AND p.publication_date >= 20000101
  GROUP BY
    p.publication_number,
    p.application_number,
    p.publication_date,
    p.filing_date,
    title,
    abstract,
    assignees,
    cpc_codes,
    cpc_b60w30,
    cpc_b60w40,
    cpc_b60w50,
    cpc_g05d1,
    cpc_b62d15,
    cpc_g08g1
)
SELECT
  publication_number,
  application_number,
  publication_date,
  filing_date,
  title,
  abstract,
  assignees,
  cpc_codes,
  matched_features,
  matched_terms,
  matched_term_count,
  matched_feature_count,
  (
    matched_term_count
    + 2 * matched_feature_count
    + cpc_b60w30
    + cpc_b60w40
    + cpc_b60w50
    + cpc_g05d1
    + cpc_b62d15
    + cpc_g08g1
  ) AS triage_score,
  CONCAT('https://patents.google.com/patent/', publication_number) AS human_review_url
FROM publication_hits
WHERE matched_term_count >= 2 OR matched_feature_count >= 2
ORDER BY triage_score DESC, publication_date DESC
LIMIT 100;
