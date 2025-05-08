
--授乳間隔を出力する
WITH q2 AS(
  SELECT DISTINCT record_date, record_datetime
  FROM piyolog
   WHERE record_date >= '2024-11-10' 
    AND ( (activity = '母乳' AND sub_activity = '母乳量') OR (activity IN ('搾母乳','ミルク')) )
    AND record_datetime BETWEEN now() - interval '30days 3hours' AND now()

), q1 AS (
  SELECT
    record_date
    ,record_datetime
    ,record_datetime - lead(record_datetime, 1) over (order by record_datetime DESC) AS interval_time
  FROM q2
  ORDER BY
    record_datetime DESC
  )
SELECT 
  record_datetime
  --record_date
  ,to_number(to_char(interval_time, 'fmhh24'), '99') * 60 + to_number(to_char(interval_time, 'fmmi'), '99') as 授乳間隔
  --,AVG(to_number(to_char(interval_time, 'fmhh24'), '99') * 60 + to_number(to_char(interval_time, 'fmmi'), '99')) as 授乳間隔
  --,to_char(AVG(interval_time), 'fmhh24:fmmi') as avg_interval_time 
FROM q1
--GROUP BY record_date
--ORDER BY record_Date ASC