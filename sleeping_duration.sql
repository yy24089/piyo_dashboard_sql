WITH sleep_piyolog AS (
  SELECT record_date
        ,activity
        ,record_datetime
        ,lag(activity, 1)         over (partition by record_date order by record_datetime, activity desc) as pre_activity
        ,lead(activity, 1)        over (partition by record_date order by record_datetime, activity desc) as next_activity
        ,lead(record_datetime, 1) over (partition by record_date order by record_datetime, activity desc) as wakeup_datetime
  FROM piyolog 
  WHERE record_date >= '2024-11-10' --AND record_date BETWEEN '2025-02-09' AND '2025-02-10'
    AND activity IN ('寝る', '起きる')
  ORDER BY record_datetime ASC
), sleep_datetime AS (  
  SELECT
    record_date
    ,activity
    ,CASE
      WHEN activity = '起きる' THEN record_date 
      ELSE record_datetime 
    END AS record_datetime
    ,pre_activity --一つ前の行動
    ,next_activity --一つ先の行動
    ,CASE
      --1日の初回の起床の場合は、起きた時間にrecord_datetimeを設定する
      WHEN activity = '起きる' THEN record_datetime 
      --1日の最終の場合は、現在時間か最終時間のうち早い方を設定する
      WHEN next_activity  is null AND record_date =  current_date THEN now()
      WHEN next_activity is null AND record_date <> current_date THEN record_date + interval'1days'
      ELSE wakeup_datetime 
    END AS wakeup_datetime2
  FROM sleep_piyolog 
  WHERE activity = '寝る'
     OR (activity = '起きる' AND pre_activity is null)
     OR (activity = '寝る' AND next_activity is null)
)
SELECT
  record_date - interval'9hours' AS 日付
  ,to_number(to_char(SUM(wakeup_datetime2 - record_datetime), 'fmhh24'), '000') + to_number(to_char(SUM(wakeup_datetime2 - record_datetime), 'fmmi'), '00') / 60 AS 睡眠時間
FROM sleep_datetime
GROUP BY 日付
ORDER BY 日付