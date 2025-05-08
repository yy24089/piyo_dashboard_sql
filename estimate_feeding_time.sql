SELECT 
  --to_char(MAX(record_datetime), 'hh24:mi') AS 前回
  --,to_timestamp(to_char(current_date, 'yyyy-mm-dd 19:00:00'), 'yyyy-mm-dd hh24:mi:ss')
  CASE
    WHEN MAX(record_datetime) >= to_timestamp(to_char(current_date, 'yyyy-mm-dd 21:00:00'), 'yyyy-mm-dd hh24:mi:ss') THEN '06:00~08:00'
    WHEN MAX(record_datetime) <= to_timestamp(to_char(current_date, 'yyyy-mm-dd 06:00:00'), 'yyyy-mm-dd hh24:mi:ss') THEN '06:00~08:00'
    ELSE to_char(MAX(record_datetime) + interval '3hours' ,'hh24:mi') || '~' || to_char(MAX(record_datetime) + interval '4hours' ,'hh24:mi')
  END AS 次回予測
FROM piyolog 
WHERE activity IN ('ミルク', '母乳', '搾母乳') LIMIT 1
