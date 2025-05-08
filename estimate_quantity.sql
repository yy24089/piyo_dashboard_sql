WITH date_setting AS (
  SELECT 
    --/*
     current_date  as col_current_date
    ,current_date - interval'1day' as col_yesterday_date
    ,current_date - interval'2day' as col_2days_ago_date
    --*/
    /*
     to_date('2025-02-21', 'yyyy-mm-dd') as col_current_date
    ,to_date('2025-02-20', 'yyyy-mm-dd') as col_yesterday_date
    ,to_date('2025-02-19', 'yyyy-mm-dd') as col_2days_ago_date
    */
), record_data AS (
  SELECT
    --今日の量と回数
     SUM(           CASE record_date WHEN col_current_date   THEN quantity        ELSE 0 END) as today_quantity
    ,--4 as today_count --テスト用
     COUNT(DISTINCT CASE record_date WHEN col_current_date   THEN record_datetime        END) as today_count
    --昨日の量と回数
    ,SUM(           CASE record_date WHEN col_yesterday_date THEN quantity        ELSE 0 END) AS yesterday_quantity
    ,COUNT(DISTINCT CASE record_date WHEN col_yesterday_date THEN record_datetime        END) AS yesterday_count
    --一昨日の量と回数
    ,SUM(           CASE record_date WHEN col_2days_ago_date THEN quantity        ELSE 0 END) AS "2days_ago_quantity"
    --設定値
    ,800 AS target_quantity
    ,5   AS target_count
    ,1   AS target_night_count
    ,0  AS diff_day_night_quantity
    ,200 AS max_time_quantity
  FROM piyolog, date_setting
  WHERE record_date >= '2024-11-10'
    AND record_date BETWEEN col_2days_ago_date AND col_current_date
    AND activity IN ('母乳','搾母乳','ミルク')
    AND quantity > 0
), calc_target AS (
  SELECT
     --今日の目標量を計算する
     CASE
       --目標回数以上になった場合は、次の日として計算する
       WHEN today_count >= target_count AND today_quantity > target_quantity AND yesterday_quantity < target_quantity 
         THEN target_quantity
       WHEN today_count >= target_count AND today_quantity < target_quantity AND yesterday_quantity > target_quantity
         THEN target_quantity
       WHEN today_count >= target_count
         THEN target_quantity + (target_quantity - today_quantity)

       --昨日の量が基準を上回っている場合でも2日前の量が基準を下回っていた場合は、
       --昨日の量にかかわらず目標量をそのまま設定する
       WHEN yesterday_quantity > target_quantity AND "2days_ago_quantity" < target_quantity 
         THEN target_quantity
       --昨日の量が基準を下回っている場合でも2日前の量が基準を上回っていた場合は、
       --昨日の量に関わらず目標量をそのまま設定する
       WHEN yesterday_quantity < target_quantity AND "2days_ago_quantity" > target_quantity
         THEN target_quantity
       ELSE target_quantity + (target_quantity - yesterday_quantity) 
     END AS today_target_quantity
    --今日の目標量までの残量
    ,CASE
       WHEN today_count >= target_count AND today_quantity > target_quantity AND yesterday_quantity < target_quantity 
         THEN target_quantity
       WHEN today_count >= target_count
         THEN target_quantity + (target_quantity - today_quantity)
       WHEN yesterday_quantity > target_quantity AND "2days_ago_quantity" < target_quantity
         THEN target_quantity - today_quantity
       ELSE target_quantity + (target_quantity - yesterday_quantity) - today_quantity 
     END AS today_remain_quantity
    ,CASE WHEN today_count >= target_count THEN 0 ELSE today_count END today_count
    ,target_count
    ,target_night_count
    ,diff_day_night_quantity
    ,target_quantity
    ,yesterday_quantity
    ,"2days_ago_quantity"
    ,max_time_quantity
  FROM record_data
), calc_target3 AS (
  SELECT 
    --日中の1回あたりの目標量
    (today_remain_quantity  - (diff_day_night_quantity * target_night_count)) / (target_count - today_count) AS remain_onetime_day_target_quantity
    ,diff_day_night_quantity
    ,today_target_quantity
    ,today_remain_quantity
    ,today_count
    ,max_time_quantity
  FROM calc_target
), calc_target2 AS (
  SELECT
    --日中の1回の目標量
     ROUND(remain_onetime_day_target_quantity                          , -1) AS remain_onetime_day_target_quantity
    ,ROUND(remain_onetime_day_target_quantity + diff_day_night_quantity, -1) AS remain_onetime_night_target_quantity
    ,today_target_quantity
    ,today_remain_quantity
    ,today_count
    ,max_time_quantity
  FROM calc_target3
)
--/*
SELECT
  today_count AS 授乳回数
  ,CASE WHEN today_count IN (5) 
    THEN CASE WHEN remain_onetime_night_target_quantity > max_time_quantity THEN max_time_quantity ELSE remain_onetime_night_target_quantity END
    ELSE CASE WHEN remain_onetime_day_target_quantity > max_time_quantity THEN max_time_quantity ELSE remain_onetime_day_target_quantity END
  END AS 次の目標量
FROM calc_target2
--*/
--SELECT * FROM calc_target2