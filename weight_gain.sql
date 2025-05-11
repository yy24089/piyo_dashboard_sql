WITH latest_weight AS (
  SELECT
    record_datetime
   ,quantity 
  FROM piyolog 
  WHERE activity = '体重' AND record_datetime >= '2024-11-10' 
  ORDER BY record_datetime DESC 
  LIMIT 1
), source_weight_records AS (
  SELECT
    record_datetime
    ,quantity
    ,MAX(record_datetime) OVER (PARTITION BY activity) - interval '7days' AS 一週間前の基準日時
    ,MAX(record_datetime) OVER (PARTITION BY activity) - interval '7days' - record_datetime AS 一週間前の基準日時との差
  FROM piyolog
  WHERE activity = '体重' AND record_datetime >= '2024-11-10'
  ORDER BY record_datetime DESC
), source_weight AS (
  SELECT
     record_datetime AS 比較元日時
    ,quantity AS 比較元体重
    ,ABS(to_number(to_char(一週間前の基準日時との差, 'ddd' ), '999') * 24 * 60 + 
         to_number(to_char(一週間前の基準日時との差, 'hh24'), '99' ) * 60      +
         to_number(to_char(一週間前の基準日時との差, 'mi'  ), '99' )) AS 基準日時との分差
    ,CASE WHEN record_datetime >= 一週間前の基準日時 THEN -1 ELSE 1 END AS 経過時間の符号
  FROM source_weight_records
  ORDER BY 基準日時との分差
  LIMIT 1
), union_records AS (
  SELECT
     record_datetime  AS 日時
    ,quantity         AS 最新体重
    ,0                AS 比較元体重
    ,0                AS 経過分数
  FROM latest_weight
  UNION
  SELECT
     比較元日時         AS 日時
    ,0                AS 最新体重
    ,比較元体重
    ,7 * 24 * 60 + 基準日時との分差 * 経過時間の符号 AS 経過分数
  FROM source_weight
)
SELECT
  ((SUM(最新体重) - SUM(比較元体重)) * 60 * 24 ) / SUM(経過分数) AS "体重増加量(7日)"
   --,SUM(最新体重) AS 最新体重
   ,SUM(比較元体重) AS 比較元体重
   --,SUM(経過分数) AS 経過分数
   ,to_char(MIN(日時), 'fmmm/fmdd hh24:mi') AS 日時
FROM union_records
