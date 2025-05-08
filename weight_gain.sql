WITH newest_mass_q AS (
  SELECT
    MAX(record_datetime) AS 最新の体重測定日時
    ,MAX(record_datetime) - interval '7days' AS 前回の体重測定上限日時
  FROM piyolog
  WHERE activity in ('体重') AND record_date >= '2024-11-10'
),
 q1 AS (
  SELECT
    record_datetime
    ,quantity AS 最新体重
    ,0        AS 前回体重
  FROM piyolog AS py
  INNER JOIN newest_mass_q AS nq
     ON py.record_datetime = nq.最新の体重測定日時 
  WHERE
    activity in ('体重') AND record_date >= '2024-11-10'

  UNION
  (
  SELECT
    record_datetime
    ,0        AS 最新体重
    ,quantity AS 前回体重
  FROM piyolog AS py
  INNER JOIN newest_mass_q AS nq
     ON py.record_datetime <= nq.前回の体重測定上限日時 
  WHERE
    activity in ('体重') AND record_date >= '2024-11-10'
  ORDER BY
    record_datetime DESC
  LIMIT 1
  )
)
SELECT 
  ( SUM(最新体重) - SUM(前回体重) ) / 
    (to_number(to_char(MAX(record_datetime) - MIN(record_datetime), 'dd'), '99') * 24 +
     to_number(to_char(MAX(record_datetime) - MIN(record_datetime), 'hh24'), '99')) * 24 AS "体重増加量"
  --,SUM(最新体重) - SUM(前回体重) AS 増加量 
  --,to_char(MAX(record_datetime), 'fmdd日hh24:mi') AS 当日
  --,to_char(MIN(record_datetime), 'fmdd日hh24:mi') AS 前日
  --,to_number(to_char(MAX(record_datetime) - MIN(record_datetime), 'dd'), '99') * 24 +
  --   to_number(to_char(MAX(record_datetime) - MIN(record_datetime), 'hh24'), '99') AS 間隔
FROM q1
  

