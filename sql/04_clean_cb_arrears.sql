-- 03_clean_bpfi.sql  (Part B: build clean table)

DROP TABLE IF EXISTS clean.bpfi_approvals;

CREATE TABLE clean.bpfi_approvals AS
WITH data_rows AS (
    SELECT row_num, col_year, TRIM(col_month) AS month_name,
           ftb, mover, ril, remortgage, topup, total
    FROM raw.bpfi_volumes
    WHERE NULLIF(TRIM(col_month), '') IS NOT NULL
),
filled AS (
    SELECT *,
           MAX(NULLIF(TRIM(col_year), '')::INT) OVER (ORDER BY row_num) AS year_filled
    FROM data_rows
),
typed AS (
    SELECT row_num,
           TO_DATE(year_filled || ' ' || month_name, 'YYYY Month') AS month_date,
           NULLIF(REPLACE(TRIM(ftb),        ',', ''), '')::INT AS ftb_n,
           NULLIF(REPLACE(TRIM(mover),      ',', ''), '')::INT AS mover_n,
           NULLIF(REPLACE(TRIM(ril),        ',', ''), '')::INT AS ril_n,
           NULLIF(REPLACE(TRIM(remortgage), ',', ''), '')::INT AS remortgage_n,
           NULLIF(REPLACE(TRIM(topup),      ',', ''), '')::INT AS topup_n,
           NULLIF(REPLACE(TRIM(total),      ',', ''), '')::INT AS total_n
    FROM filled
)
SELECT
    month_date,
    EXTRACT(YEAR FROM month_date)::INT    AS year,
    EXTRACT(QUARTER FROM month_date)::INT AS quarter,
    (mover_n IS NOT NULL)                 AS split_available,
    CASE WHEN mover_n IS NOT NULL THEN ftb_n END        AS ftb,
    CASE WHEN mover_n IS NOT NULL THEN mover_n END      AS mover,
    CASE WHEN mover_n IS NOT NULL THEN ril_n END        AS ril,
    CASE WHEN mover_n IS NOT NULL THEN ftb_n + mover_n + ril_n
         ELSE ftb_n END                                 AS house_purchase,
    CASE WHEN mover_n IS NOT NULL THEN remortgage_n END AS remortgage,
    CASE WHEN mover_n IS NOT NULL THEN topup_n END      AS topup,
    CASE WHEN mover_n IS NOT NULL THEN remortgage_n + topup_n
         ELSE remortgage_n END                          AS remortgage_topup,
    total_n                                             AS total,
    row_num                                             AS source_row_num
FROM typed
ORDER BY month_date;


SELECT COUNT(*) FROM clean.bpfi_approvals;

SELECT month_date, split_available, ftb, mover, ril, house_purchase,
       remortgage, topup, remortgage_topup, total
FROM clean.bpfi_approvals
WHERE month_date IN ('2011-01-01','2014-06-01','2014-07-01','2026-09-01')
ORDER BY month_date;


SELECT COUNT(*) AS mismatches
FROM clean.bpfi_approvals
WHERE house_purchase + remortgage_topup <> total;


-- 04_clean_cb_arrears.sql  (building up piece by piece)



