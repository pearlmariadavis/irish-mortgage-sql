-- 10_dq_scorecard.sql

DROP TABLE IF EXISTS dq.scorecard;

CREATE TABLE dq.scorecard AS
WITH checks AS (
    -- ===================== BPFI approvals =====================
    SELECT 'B01' AS rule_id, 'BPFI' AS source, 'Completeness' AS dimension,
           'All 189 months Jan 2011 - Sep 2026 present, no gaps' AS rule,
           189 AS records_checked,
           189 - (SELECT COUNT(DISTINCT month_date) FROM clean.bpfi_approvals) AS records_failed,
           'FAIL' AS status_if_failed, 'Investigate missing months' AS action
    UNION ALL
    SELECT 'B02', 'BPFI', 'Consistency',
           'House purchase + re-mortgage/top-up = total',
           (SELECT COUNT(*) FROM clean.bpfi_approvals),
           (SELECT COUNT(*) FROM clean.bpfi_approvals
             WHERE house_purchase + remortgage_topup <> total),
           'FAIL', 'Investigate rows that do not add up'
    UNION ALL
    SELECT 'B03', 'BPFI', 'Consistency',
           'Buyer split (FTB/Mover/RIL) only missing before Jul 2014',
           (SELECT COUNT(*) FROM clean.bpfi_approvals),
           (SELECT COUNT(*) FROM clean.bpfi_approvals
             WHERE (month_date <  DATE '2014-07-01' AND split_available)
                OR (month_date >= DATE '2014-07-01' AND NOT split_available)),
           'FAIL', 'Check where the split starts'
    UNION ALL
    SELECT 'B04', 'BPFI', 'Validity',
           'Pre-Jul 2014 house purchase total sat in FTB column (merged cells)',
           (SELECT COUNT(*) FROM clean.bpfi_approvals),
           (SELECT COUNT(*) FROM clean.bpfi_approvals WHERE NOT split_available),
           'HANDLED', 'Moved to house_purchase; FTB/Mover/RIL left empty'
    UNION ALL
    SELECT 'B05', 'BPFI', 'Validity',
           'Month names have stray spaces (e.g. "April ")',
           189,
           (SELECT COUNT(*) FROM raw.bpfi_volumes
             WHERE NULLIF(TRIM(col_month), '') IS NOT NULL
               AND col_month <> TRIM(col_month)),
           'HANDLED', 'Trimmed before converting to a date'
    UNION ALL
    SELECT 'B06', 'BPFI', 'Validity',
           'No negative approval counts',
           (SELECT COUNT(*) FROM clean.bpfi_approvals),
           (SELECT COUNT(*) FROM clean.bpfi_approvals
             WHERE LEAST(house_purchase, remortgage_topup, total,
                         COALESCE(ftb,0), COALESCE(mover,0), COALESCE(ril,0),
                         COALESCE(remortgage,0), COALESCE(topup,0)) < 0),
           'FAIL', 'Investigate negative values'
    -- ===================== Central Bank arrears =====================
    UNION ALL
    SELECT 'C01', 'Arrears', 'Completeness',
           'Row count matches source file (19,199)',
           19199,
           ABS(19199 - (SELECT COUNT(*) FROM clean.cb_arrears)),
           'FAIL', 'Reload the file'
    UNION ALL
    SELECT 'C02', 'Arrears', 'Completeness',
           'All 67 quarters Sep 2009 - Mar 2026 present',
           67,
           67 - (SELECT COUNT(DISTINCT quarter_end) FROM clean.cb_arrears),
           'FAIL', 'Investigate missing quarters'
    UNION ALL
    SELECT 'C03', 'Arrears', 'Completeness',
           'Every row has a value',
           (SELECT COUNT(*) FROM clean.cb_arrears),
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE value IS NULL),
           'FAIL', 'Investigate empty values'
    UNION ALL
    SELECT 'C04', 'Arrears', 'Validity',
           'Reporting date is dated the 1st of the month (Q3 and Q4 2025)',
           (SELECT COUNT(*) FROM clean.cb_arrears),
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE date_type = 'first_of_month_error'),
           'HANDLED', 'Moved to quarter end (assumption, evidence logged)'
    UNION ALL
    SELECT 'C05', 'Arrears', 'Validity',
           'Reporting date is last working day, not calendar quarter end',
           (SELECT COUNT(*) FROM clean.cb_arrears),
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE date_type = 'last_business_day'),
           'HANDLED', 'Aligned to calendar quarter end'
    UNION ALL
    SELECT 'C06', 'Arrears', 'Consistency',
           'One reporting date per quarter',
           67,
           (SELECT COUNT(*) FROM (SELECT quarter_end FROM clean.cb_arrears
                                   GROUP BY quarter_end
                                   HAVING COUNT(DISTINCT original_date) > 1) q),
           'HANDLED', 'Q3 2025 split across 01/09 and 30/09; merged into 30/09'
    UNION ALL
    SELECT 'C07', 'Arrears', 'Accuracy',
           'Count rows with a copied number in the Observation column (Mar 2026)',
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE unit = 'count'),
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE junk_value_ignored),
           'HANDLED', 'Used Number of Accounts; Observation ignored'
    UNION ALL
    SELECT 'C08', 'Arrears', 'Validity',
           'No negative values',
           (SELECT COUNT(*) FROM clean.cb_arrears),
           (SELECT COUNT(*) FROM clean.cb_arrears WHERE value < 0),
           'FAIL', 'Investigate negative values'
    -- ===================== Property Price Register =====================
    UNION ALL
    SELECT 'P01', 'PPR', 'Completeness',
           'Row count matches source file (814,413)',
           814413,
           ABS(814413 - (SELECT COUNT(*) FROM clean.ppr)),
           'FAIL', 'Reload the file'
    UNION ALL
    SELECT 'P02', 'PPR', 'Validity',
           'Every price converts to a number',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE price IS NULL),
           'FAIL', 'Investigate unreadable prices'
    UNION ALL
    SELECT 'P03', 'PPR', 'Validity',
           'Every county is one of the 26',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr
             WHERE county NOT IN ('Carlow','Cavan','Clare','Cork','Donegal','Dublin','Galway',
                                  'Kerry','Kildare','Kilkenny','Laois','Leitrim','Limerick',
                                  'Longford','Louth','Mayo','Meath','Monaghan','Offaly',
                                  'Roscommon','Sligo','Tipperary','Waterford','Westmeath',
                                  'Wexford','Wicklow')),
           'FAIL', 'Investigate unknown counties'
    UNION ALL
    SELECT 'P04', 'PPR', 'Validity',
           'No sale dates in the future',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE sale_date > CURRENT_DATE),
           'FAIL', 'Investigate future dates'
    UNION ALL
    SELECT 'P05', 'PPR', 'Uniqueness',
           'Exact duplicate rows (every column identical)',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE is_duplicate),
           'HANDLED', 'Flagged; excluded from price analysis'
    UNION ALL
    SELECT 'P06', 'PPR', 'Accuracy',
           'Bulk or implausible sales over EUR 10m',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE is_bulk_sale),
           'HANDLED', 'Flagged; excluded from price analysis'
    UNION ALL
    SELECT 'P07', 'PPR', 'Accuracy',
           'Prices under EUR 10,000',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE is_low_price),
           'HANDLED', 'Flagged; excluded from price analysis'
    UNION ALL
    SELECT 'P08', 'PPR', 'Accuracy',
           'Declared not full market price',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE not_full_market_price),
           'HANDLED', 'Kept in sales counts; excluded from price analysis'
    UNION ALL
    SELECT 'P09', 'PPR', 'Consistency',
           'Property description in Irish instead of English',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE irish_label),
           'HANDLED', 'Mapped to New / Second-Hand'
    UNION ALL
    SELECT 'P10', 'PPR', 'Completeness',
           'Eircode missing (only collected from 2021)',
           (SELECT COUNT(*) FROM clean.ppr),
           (SELECT COUNT(*) FROM clean.ppr WHERE eircode IS NULL),
           'WARN', 'Eircode not used in the analysis'
    UNION ALL
    SELECT 'B07', 'BPFI', 'Accuracy',
           '2021 total approvals match BPFI press release of 26 Jan 2022 (53,335)',
           1,
           CASE WHEN (SELECT SUM(total) FROM clean.bpfi_approvals WHERE year = 2021) = 53335
                THEN 0 ELSE 1 END,
           'FAIL', 'Recheck the BPFI load and cleaning'
    UNION ALL
    SELECT 'C09', 'Arrears', 'Completeness',
           'Every quarter has total-in-arrears rows for Banks and Non-Banks (PDH)',
           (SELECT COUNT(DISTINCT quarter_end) * 2 FROM clean.cb_arrears),
           (SELECT COUNT(DISTINCT quarter_end) * 2 FROM clean.cb_arrears)
             - (SELECT COUNT(*) FROM (SELECT DISTINCT quarter_end, entity_group
                                      FROM clean.cb_arrears
                                      WHERE format = 'PDH' AND unit = 'count'
                                        AND row_desc = 'Arrears: Total mortgage accounts in arrears') x),
           'HANDLED', 'Banks/PDH missing in Mar 2026; A4 ends at Dec 2025'
    UNION ALL
    SELECT 'C10', 'Arrears', 'Accuracy',
           'PDH figures for Mar 2020 and Dec 2020 match Central Bank statistical releases',
           6,
           (SELECT COUNT(*)
              FROM (VALUES (DATE '2020-03-31', 739592, 63437, 41079),
                           (DATE '2020-12-31', 731988, 54986, 38785)) AS cb(q, outstanding, in_arrears, over_90)
              JOIN analysis.a4_arrears_trend a ON a.quarter_end = cb.q
              CROSS JOIN LATERAL (VALUES (a.accounts_outstanding = cb.outstanding),
                                         (a.accounts_in_arrears  = cb.in_arrears),
                                         (a.arrears_over_90_days = cb.over_90)) AS t(ok)
             WHERE NOT t.ok),
           'FAIL', 'Recheck the arrears cleaning and A4 logic'
)
SELECT rule_id, source, dimension, rule, records_checked, records_failed,
       ROUND(100.0 * records_failed / NULLIF(records_checked, 0), 2) AS pct_failed,
       CASE WHEN records_failed = 0 THEN 'PASS' ELSE status_if_failed END AS status,
       CASE WHEN records_failed = 0 THEN '-' ELSE action END AS action,
       CURRENT_DATE AS run_date
FROM checks
ORDER BY rule_id;