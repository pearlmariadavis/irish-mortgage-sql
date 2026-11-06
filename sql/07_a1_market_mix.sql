-- 07_a1_market_mix.sql

DROP VIEW IF EXISTS analysis.a1_market_mix_annual;

CREATE VIEW analysis.a1_market_mix_annual AS
SELECT
    year,
    COUNT(*)                                                  AS months,
    SUM(total)                                                AS total_approvals,
    ROUND(100.0 * SUM(ftb)        / SUM(total), 1)            AS ftb_pct,
    ROUND(100.0 * SUM(mover)      / SUM(total), 1)            AS mover_pct,
    ROUND(100.0 * SUM(ril)        / SUM(total), 1)            AS ril_pct,
    ROUND(100.0 * SUM(remortgage) / SUM(total), 1)            AS switcher_pct,
    ROUND(100.0 * SUM(topup)      / SUM(total), 1)            AS topup_pct,
    ROUND(100.0 * SUM(ftb) / SUM(ftb + mover + ril), 1)       AS ftb_share_of_purchases
FROM clean.bpfi_approvals
WHERE split_available
GROUP BY year
ORDER BY year;

SELECT * FROM analysis.a1_market_mix_annual;



