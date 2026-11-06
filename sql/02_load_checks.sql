-- 02_load_checks.sql


-- 1. Row counts: should match the number of data lines in each source file
SELECT 'raw.cb_arrears'   AS table_name, COUNT(*) AS rows_loaded FROM raw.cb_arrears
UNION ALL
SELECT 'raw.ppr',                       COUNT(*)               FROM raw.ppr
UNION ALL
SELECT 'raw.bpfi_volumes',              COUNT(*)               FROM raw.bpfi_volumes;

-- 2. BPFI: all 189 monthly rows present (Jan 2011 to Sep 2026)
SELECT COUNT(*) AS month_rows
FROM raw.bpfi_volumes
WHERE NULLIF(TRIM(col_month), '') IS NOT NULL;
-- Expected: 189

-- 3. Arrears: commas and spaces kept exactly as in the source file
SELECT observation, number_of_accounts
FROM raw.cb_arrears
WHERE observation LIKE '%,%' OR number_of_accounts LIKE '% %'
LIMIT 5;
-- 