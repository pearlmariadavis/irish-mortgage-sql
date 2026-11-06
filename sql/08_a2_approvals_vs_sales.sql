-- 08_a2_approvals_vs_sales.sql

DROP VIEW IF EXISTS analysis.a2_approvals_vs_sales;

CREATE VIEW analysis.a2_approvals_vs_sales AS
WITH approvals AS (
    SELECT year,
           SUM(house_purchase) AS purchase_approvals,
           COUNT(*)            AS months
    FROM clean.bpfi_approvals
    GROUP BY year
),
sales AS (
    SELECT year,
           COUNT(*) FILTER (WHERE NOT is_duplicate)                              AS sales_all,
           COUNT(*) FILTER (WHERE NOT is_duplicate AND NOT not_full_market_price) AS sales_market
    FROM clean.ppr
    GROUP BY year
)
SELECT
    a.year,
    a.purchase_approvals,
    s.sales_all,
    s.sales_market,
    ROUND(1.0 * a.purchase_approvals / s.sales_market, 2) AS approvals_per_market_sale
FROM approvals a
JOIN sales s ON s.year = a.year
WHERE a.months = 12
ORDER BY a.year;