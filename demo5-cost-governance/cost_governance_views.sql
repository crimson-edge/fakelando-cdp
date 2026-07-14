-- ============================================================================
-- FAKELANDO HEALTH - CROSS-PLATFORM COST GOVERNANCE
-- BigQuery Views for Unified Cost Monitoring Dashboard
-- ============================================================================

-- This creates a cost governance dashboard that monitors simulated spend across:
-- 1. BigQuery (query costs, storage)
-- 2. Looker (user licenses, platform)
-- 3. Fivetran (MAR-based pricing)
-- 4. Databricks (DBU consumption)

-- NOTE: We use simulated data since INFORMATION_SCHEMA requires specific permissions

-- ============================================================================
-- 1. SIMULATED BIGQUERY QUERY COSTS
-- ============================================================================

CREATE OR REPLACE TABLE `prefab-bruin-489518-h1.fakelando_health.bq_query_costs` (
  cost_date DATE,
  platform STRING,
  cost_category STRING,
  identity STRING,      -- user_email
  job_id STRING,
  query STRING,
  tb_billed FLOAT64,
  estimated_cost_usd FLOAT64,
  slot_hours FLOAT64,
  cost_tier STRING      -- HIGH/MEDIUM/LOW
);

-- Insert sample query cost data (simulating last 30 days)
INSERT INTO `prefab-bruin-489518-h1.fakelando_health.bq_query_costs` 
SELECT * FROM UNNEST([
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) as cost_date, 'BigQuery' as platform, 'Query' as cost_category, 'analyst@fakelandohealth.com' as identity, 'bqjob_abc123' as job_id, 'SELECT * FROM patients WHERE state=TX' as query, 0.15 as tb_billed, 0.94 as estimated_cost_usd, 2.3 as slot_hours, 'LOW' as cost_tier),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'BigQuery', 'Query', 'data-scientist@fakelandohealth.com', 'bqjob_def456', 'WITH cohort AS (SELECT * FROM visits JOIN claims...)', 2.45, 15.31, 45.2, 'HIGH'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'BigQuery', 'Query', 'marketing@fakelandohealth.com', 'bqjob_ghi789', 'SELECT acquisition_channel, COUNT(*) FROM patient_acquisition_cohorts GROUP BY 1', 0.03, 0.19, 0.8, 'LOW'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'BigQuery', 'Query', 'exec@fakelandohealth.com', 'bqjob_jkl012', 'SELECT * FROM patient_360_view WHERE patient_mrn=PAT-000164', 0.01, 0.06, 0.3, 'LOW'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY), 'BigQuery', 'Query', 'analyst@fakelandohealth.com', 'bqjob_mno345', 'SELECT * FROM inpatient_charges_2015 WHERE provider_state=CA', 1.8, 11.25, 32.1, 'MEDIUM'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY), 'BigQuery', 'Query', 'data-scientist@fakelandohealth.com', 'bqjob_pqr678', 'ML.FORECAST model training on patient features', 3.2, 20.0, 67.5, 'HIGH'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY), 'BigQuery', 'Query', 'analyst@fakelandohealth.com', 'bqjob_stu901', 'Daily cohort retention calculation', 0.45, 2.81, 8.2, 'MEDIUM'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY), 'BigQuery', 'Query', 'billing@fakelandohealth.com', 'bqjob_vwx234', 'Claims reconciliation for month-end', 0.22, 1.38, 4.1, 'LOW'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 4 DAY), 'BigQuery', 'Query', 'analyst@fakelandohealth.com', 'bqjob_yza567', 'Marketing attribution model refresh', 1.1, 6.88, 19.3, 'MEDIUM'),
  STRUCT(DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY), 'BigQuery', 'Query', 'data-scientist@fakelandohealth.com', 'bqjob_bcd890', 'Patient risk scoring ML model', 4.5, 28.13, 89.2, 'HIGH')
]);

-- ============================================================================
-- 2. SIMULATED BIGQUERY STORAGE COSTS
-- ============================================================================

CREATE OR REPLACE TABLE `prefab-bruin-489518-h1.fakelando_health.bq_storage_costs` (
  cost_date DATE,
  platform STRING,
  cost_category STRING,
  dataset STRING,
  table_name STRING,
  size_gb FLOAT64,
  estimated_monthly_cost_usd FLOAT64,
  row_count INT64,
  size_tier STRING
);

INSERT INTO `prefab-bruin-489518-h1.fakelando_health.bq_storage_costs` 
SELECT * FROM UNNEST([
  STRUCT(CURRENT_DATE() as cost_date, 'BigQuery' as platform, 'Storage' as cost_category, 'fakelando_health' as dataset, 'patients' as table_name, 1.2 as size_gb, 0.024 as estimated_monthly_cost_usd, 5000 as row_count, 'SMALL' as size_tier),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'visits', 4.8, 0.096, 24997, 'MEDIUM'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'claims', 6.2, 0.124, 25000, 'MEDIUM'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'inpatient_charges_2015', 35.9, 0.718, 201876, 'LARGE'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'outpatient_charges_2015', 22.4, 0.448, 125000, 'LARGE'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'icd10_diagnoses_2019', 3.1, 0.062, 94444, 'MEDIUM'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'hospital_general_info', 1.5, 0.03, 5336, 'SMALL'),
  STRUCT(CURRENT_DATE(), 'BigQuery', 'Storage', 'fakelando_health', 'america_health_rankings', 2.8, 0.056, 18155, 'MEDIUM')
]);

-- ============================================================================
-- 3. SIMULATED LOOKER COSTS
-- ============================================================================

CREATE OR REPLACE TABLE `prefab-bruin-489518-h1.fakelando_health.looker_costs` (
  cost_date DATE,
  platform STRING,
  cost_category STRING,
  user_count INT64,
  developer_users INT64,
  standard_users INT64,
  viewer_users INT64,
  platform_cost_usd FLOAT64,
  per_user_cost_usd FLOAT64,
  api_calls_this_month INT64,
  api_limit INT64
);

INSERT INTO `prefab-bruin-489518-h1.fakelando_health.looker_costs` VALUES
(CURRENT_DATE(), 'Looker', 'Platform', 12, 2, 8, 2, 3000.00, 250.00, 45000, 100000),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Looker', 'Platform', 11, 2, 7, 2, 2750.00, 250.00, 42000, 100000),
(DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH), 'Looker', 'Platform', 10, 2, 6, 2, 2500.00, 250.00, 38000, 100000);

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.looker_costs_view` AS
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.looker_costs`;

-- ============================================================================
-- 4. SIMULATED FIVETRAN COSTS (MAR-based)
-- ============================================================================

CREATE OR REPLACE TABLE `prefab-bruin-489518-h1.fakelando_health.fivetran_costs` (
  cost_date DATE,
  platform STRING,
  cost_category STRING,
  connector STRING,
  monthly_active_rows INT64,
  mar_limit INT64,
  cost_per_mar FLOAT64,
  estimated_cost_usd FLOAT64,
  sync_frequency_minutes INT64,
  destination STRING
);

INSERT INTO `prefab-bruin-489518-h1.fakelando_health.fivetran_costs` VALUES
(CURRENT_DATE(), 'Fivetran', 'Connector', 'salesforce', 150000, 500000, 0.50, 75.00, 15, 'BigQuery'),
(CURRENT_DATE(), 'Fivetran', 'Connector', 'hubspot', 80000, 500000, 0.50, 40.00, 30, 'BigQuery'),
(CURRENT_DATE(), 'Fivetran', 'Connector', 'stripe', 45000, 500000, 0.50, 22.50, 5, 'BigQuery'),
(CURRENT_DATE(), 'Fivetran', 'Connector', 'google_analytics_4', 220000, 500000, 0.50, 110.00, 5, 'BigQuery'),
(CURRENT_DATE(), 'Fivetran', 'Connector', 'postgresql', 180000, 500000, 0.50, 90.00, 15, 'BigQuery'),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Fivetran', 'Connector', 'salesforce', 145000, 500000, 0.50, 72.50, 15, 'BigQuery'),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Fivetran', 'Connector', 'hubspot', 78000, 500000, 0.50, 39.00, 30, 'BigQuery'),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Fivetran', 'Connector', 'stripe', 43000, 500000, 0.50, 21.50, 5, 'BigQuery'),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Fivetran', 'Connector', 'google_analytics_4', 210000, 500000, 0.50, 105.00, 5, 'BigQuery'),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), 'Fivetran', 'Connector', 'postgresql', 175000, 500000, 0.50, 87.50, 15, 'BigQuery');

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.fivetran_costs_view` AS
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.fivetran_costs`;

-- ============================================================================
-- 5. SIMULATED DATABRICKS COSTS (DBU-based)
-- ============================================================================

CREATE OR REPLACE TABLE `prefab-bruin-489518-h1.fakelando_health.databricks_costs` (
  cost_date DATE,
  platform STRING,
  cost_category STRING,
  workspace STRING,
  compute_type STRING,
  instance_name STRING,
  dbu_hours FLOAT64,
  dbu_rate_usd FLOAT64,
  estimated_cost_usd FLOAT64,
  node_type STRING,
  worker_count INT64,
  usage_hours FLOAT64
);

INSERT INTO `prefab-bruin-489518-h1.fakelando_health.databricks_costs` VALUES
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'SQL Warehouse', 'looker-cdp', 45.2, 0.22, 9.94, 'serverless', 0, 8.5),
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'SQL Warehouse', 'ml-cdp', 32.8, 0.22, 7.22, 'serverless', 0, 6.2),
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'Job Cluster', 'cdp-nightly-refresh', 128.5, 0.15, 19.28, 'n2-standard-8', 4, 4.2),
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'Job Cluster', 'ml-training', 85.3, 0.30, 25.59, 'n2-standard-16', 2, 3.1),
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'Model Serving', 'churn-predictor', 12.4, 0.40, 4.96, 'serverless', 0, 24.0),
(CURRENT_DATE(), 'Databricks', 'Compute', 'fakelando-prod', 'Model Serving', 'ltv-predictor', 8.7, 0.40, 3.48, 'serverless', 0, 24.0),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'Databricks', 'Compute', 'fakelando-prod', 'SQL Warehouse', 'looker-cdp', 48.1, 0.22, 10.58, 'serverless', 0, 9.0),
(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), 'Databricks', 'Compute', 'fakelando-prod', 'Job Cluster', 'cdp-nightly-refresh', 132.2, 0.15, 19.83, 'n2-standard-8', 4, 4.3);

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.databricks_costs_view` AS
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.databricks_costs`;

-- ============================================================================
-- 6. UNIFIED COST VIEW (All platforms combined)
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.unified_platform_costs` AS

SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.bq_query_costs`
UNION ALL
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.bq_storage_costs`
UNION ALL
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.looker_costs_view`
UNION ALL
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.fivetran_costs_view`
UNION ALL
SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.databricks_costs_view`;

-- ============================================================================
-- 7. DAILY COST SUMMARY
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.daily_cost_summary` AS

SELECT
  cost_date,
  platform,
  SUM(estimated_cost_usd) as daily_cost_usd,
  COUNT(*) as cost_entries
FROM `prefab-bruin-489518-h1.fakelando_health.unified_platform_costs`
GROUP BY cost_date, platform
ORDER BY cost_date DESC, platform;

-- ============================================================================
-- 8. MONTHLY COST TRENDS
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.monthly_cost_trends` AS

SELECT
  FORMAT_DATE('%Y-%m', cost_date) as cost_month,
  platform,
  SUM(estimated_cost_usd) as monthly_cost_usd,
  COUNT(DISTINCT cost_date) as active_days
FROM `prefab-bruin-489518-h1.fakelando_health.unified_platform_costs`
WHERE cost_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
GROUP BY cost_month, platform
ORDER BY cost_month DESC, monthly_cost_usd DESC;

-- ============================================================================
-- 9. COST ALERTING THRESHOLDS
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.cost_alerts` AS

WITH daily_totals AS (
  SELECT
    cost_date,
    platform,
    SUM(estimated_cost_usd) as daily_cost
  FROM `prefab-bruin-489518-h1.fakelando_health.unified_platform_costs`
  GROUP BY cost_date, platform
),

prev_comparison AS (
  SELECT
    dt.cost_date,
    dt.platform,
    dt.daily_cost,
    LAG(dt.daily_cost) OVER (PARTITION BY dt.platform ORDER BY dt.cost_date) as prev_day_cost,
    AVG(dt.daily_cost) OVER (PARTITION BY dt.platform ORDER BY dt.cost_date ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) as avg_7day_cost,
    AVG(dt.daily_cost) OVER (PARTITION BY dt.platform ORDER BY dt.cost_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) as avg_30day_cost
  FROM daily_totals dt
)

SELECT
  cost_date,
  platform,
  daily_cost,
  prev_day_cost,
  avg_7day_cost,
  avg_30day_cost,
  CASE
    WHEN daily_cost > avg_7day_cost * 2 THEN 'CRITICAL: 2x 7-day average'
    WHEN daily_cost > avg_7day_cost * 1.5 THEN 'WARNING: 1.5x 7-day average'
    WHEN daily_cost > avg_30day_cost * 1.5 THEN 'NOTICE: 1.5x 30-day average'
    ELSE 'NORMAL'
  END as alert_level,
  ROUND(SAFE_DIVIDE(daily_cost - avg_7day_cost, avg_7day_cost) * 100, 1) as pct_change_from_7day_avg
FROM prev_comparison
WHERE cost_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND (daily_cost > avg_7day_cost * 1.5 OR daily_cost > avg_30day_cost * 1.5)
ORDER BY cost_date DESC, daily_cost DESC;

-- ============================================================================
-- USAGE:
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.daily_cost_summary`
-- WHERE cost_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);
--
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.monthly_cost_trends`;
--
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.cost_alerts`;
-- ============================================================================