






-- 05_clean_ppr.sql

DROP TABLE IF EXISTS clean.ppr;

CREATE TABLE clean.ppr AS
WITH typed AS (
    SELECT
        TO_DATE(TRIM(sale_date), 'DD/MM/YYYY')                     AS sale_date,
        TRIM(address)                                              AS address,
        TRIM(county)                                               AS county,
        NULLIF(TRIM(eircode), '')                                  AS eircode,
        REGEXP_REPLACE(price, '[^0-9.]', '', 'g')::NUMERIC(14,2)   AS price,
        (TRIM(not_full_market_price) = 'Yes')                      AS not_full_market_price,
        (TRIM(vat_exclusive) = 'Yes')                              AS vat_exclusive,
        TRIM(description)                                          AS description_raw,
        NULLIF(TRIM(property_size), '')                            AS property_size,
        ROW_NUMBER() OVER (
            PARTITION BY sale_date, address, county, eircode, price,
                         not_full_market_price, vat_exclusive, description, property_size
            ORDER BY sale_date
        )                                                          AS copy_number
    FROM raw.ppr
)
SELECT
    sale_date,
    EXTRACT(YEAR FROM sale_date)::INT                              AS year,
    (DATE_TRUNC('quarter', sale_date)
        + INTERVAL '3 months' - INTERVAL '1 day')::DATE            AS quarter_end,
    DATE_TRUNC('month', sale_date)::DATE                           AS month_date,
    county,
    address,
    eircode,
    price,
    CASE
        WHEN description_raw ILIKE 'New%'         THEN 'New'
        WHEN description_raw ILIKE 'Second-Hand%' THEN 'Second-Hand'
        WHEN description_raw ILIKE '%Nua'         THEN 'New'
        WHEN description_raw ILIKE '%imhe'        THEN 'Second-Hand'
        ELSE 'Unknown'
    END                                                            AS property_type,
    (description_raw LIKE 'Teach%')                                AS irish_label,
    description_raw,
    property_size,
    not_full_market_price,
    vat_exclusive,
    (price > 10000000)                                             AS is_bulk_sale,
    (price < 10000)                                                AS is_low_price,
    (copy_number > 1)                                              AS is_duplicate,
    (NOT not_full_market_price
        AND price BETWEEN 10000 AND 10000000
        AND copy_number = 1)                                       AS use_for_price_analysis
FROM typed;

SELECT COUNT(*)                                         AS total_rows,
       COUNT(*) FILTER (WHERE is_bulk_sale)             AS bulk,
       COUNT(*) FILTER (WHERE is_low_price)             AS low,
       COUNT(*) FILTER (WHERE is_duplicate)             AS duplicates,
       COUNT(*) FILTER (WHERE not_full_market_price)    AS non_market,
       COUNT(*) FILTER (WHERE use_for_price_analysis)   AS usable_for_prices,
       COUNT(*) FILTER (WHERE price IS NULL)            AS missing_price
FROM clean.ppr;


SELECT property_type, irish_label, COUNT(*)
FROM clean.ppr
GROUP BY property_type, irish_label
ORDER BY property_type, irish_label;


SELECT year,
       COUNT(*) AS sales,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
           FILTER (WHERE use_for_price_analysis) AS median_price
FROM clean.ppr
WHERE year = 2024
GROUP BY year;