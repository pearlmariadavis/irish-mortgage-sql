-- 09_a4_arrears_trend.sql

DROP VIEW IF EXISTS analysis.a4_arrears_trend;

CREATE VIEW analysis.a4_arrears_trend AS
WITH pdh AS (
    SELECT
        quarter_end,
        SUM(value) FILTER (WHERE row_desc = 'Outstanding Mortgages: Total mortgage loan accounts outstanding') AS accounts_outstanding,
        SUM(value) FILTER (WHERE row_desc = 'Arrears: Total mortgage accounts in arrears')                     AS accounts_in_arrears,
        SUM(value) FILTER (WHERE row_desc = 'Arrears: Total mortgage accounts in arrears - up to 90 days')     AS arrears_up_to_90_days,
        COUNT(DISTINCT entity_group)                                                                          AS lender_groups
    FROM clean.cb_arrears
    WHERE format = 'PDH'
      AND unit = 'count'
      AND row_desc IN ('Outstanding Mortgages: Total mortgage loan accounts outstanding',
                       'Arrears: Total mortgage accounts in arrears',
                       'Arrears: Total mortgage accounts in arrears - up to 90 days')
    GROUP BY quarter_end
)
SELECT
    quarter_end,
    accounts_outstanding,
    accounts_in_arrears,
    accounts_in_arrears - arrears_up_to_90_days                                   AS arrears_over_90_days,
    ROUND(100.0 * accounts_in_arrears / accounts_outstanding, 2)                  AS arrears_rate_pct,
    ROUND(100.0 * (accounts_in_arrears - arrears_up_to_90_days)
                / accounts_outstanding, 2)                                        AS over_90_rate_pct
FROM pdh
WHERE lender_groups = 2
ORDER BY quarter_end;