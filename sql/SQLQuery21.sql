-- ============================================================
-- KIỂM TRA: Chạy từng lệnh để verify views hoạt động đúng
-- ============================================================

-- 1. Kiểm tra bảng gốc
SELECT TOP 5 * FROM dbo.Credit_Risk_Dataset;

-- 2. Kiểm tra view enriched
SELECT TOP 5 * FROM dbo.vw_loan_enriched;

-- 3. Kiểm tra default rate tổng thể (FIXED)
SELECT
    COUNT(*)                                                        AS total_loans,
    SUM(CAST(loan_status AS INT))                                   AS total_defaults,
    CAST(100.0 * SUM(CAST(loan_status AS INT))/COUNT(*) AS DECIMAL(5,2)) AS default_rate_pct
FROM dbo.vw_loan_enriched;

-- 4. Kiểm tra phân bố risk category
SELECT risk_category, COUNT(*) AS total
FROM dbo.vw_loan_enriched
GROUP BY risk_category
ORDER BY total DESC;

-- 5. Kiểm tra all views tồn tại (FIXED)
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;

-- Lựa chọn thay thế cho Query 5 (Nếu bạn thực sự muốn thấy cột TABLE_TYPE):
-- SELECT TABLE_NAME, TABLE_TYPE
-- FROM INFORMATION_SCHEMA.TABLES
-- WHERE TABLE_SCHEMA = 'dbo'
--   AND TABLE_TYPE = 'VIEW'
--   AND TABLE_NAME LIKE 'vw_%'
-- ORDER BY TABLE_NAME;