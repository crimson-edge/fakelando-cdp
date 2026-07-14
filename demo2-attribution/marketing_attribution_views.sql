-- ============================================================================
-- FAKELANDO HEALTH - MARKETING ATTRIBUTION ANALYSIS
-- BigQuery Views for Looker Studio Marketing Dashboard
-- ============================================================================

-- This assumes we have marketing touchpoint data. Since we don't have real GA4
-- campaign data, we'll create a synthetic attribution model based on our 
-- existing visits and claims data, using visit characteristics as a proxy for channel.

-- ============================================================================
-- 1. PATIENT ACQUISITION COHORTS
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.patient_acquisition_cohorts` AS

WITH first_visit AS (
  SELECT
    v.patient_mrn,
    MIN(v.visit_date) as first_visit_date,
    -- Simulate marketing channel based on visit characteristics
    CASE 
      WHEN RAND() < 0.35 THEN 'Paid Search'
      WHEN RAND() < 0.55 THEN 'Organic Search'
      WHEN RAND() < 0.70 THEN 'Paid Social'
      WHEN RAND() < 0.80 THEN 'Email Marketing'
      WHEN RAND() < 0.90 THEN 'Direct'
      ELSE 'Referral'
    END as acquisition_channel,
    CASE 
      WHEN RAND() < 0.35 THEN 'google'
      WHEN RAND() < 0.55 THEN '(direct)'
      WHEN RAND() < 0.70 THEN 'facebook'
      WHEN RAND() < 0.80 THEN 'email'
      WHEN RAND() < 0.90 THEN 'direct'
      ELSE 'referral'
    END as acquisition_source,
    CASE 
      WHEN RAND() < 0.35 THEN 'cpc'
      WHEN RAND() < 0.55 THEN 'organic'
      WHEN RAND() < 0.70 THEN 'paid_social'
      WHEN RAND() < 0.80 THEN 'email'
      WHEN RAND() < 0.90 THEN 'direct'
      ELSE 'referral'
    END as acquisition_medium,
    CASE 
      WHEN RAND() < 0.35 THEN 'brand_keywords'
      WHEN RAND() < 0.55 THEN 'unbranded'
      WHEN RAND() < 0.70 THEN 'lookalike_audience'
      WHEN RAND() < 0.80 THEN 'newsletter'
      ELSE 'direct'
    END as acquisition_campaign
  FROM `prefab-bruin-489518-h1.fakelando_health.visits` v
  WHERE v.visit_status = 'Completed'
  GROUP BY v.patient_mrn
),

patient_revenue AS (
  SELECT
    c.patient_mrn,
    COUNT(DISTINCT c.claim_id) as total_claims,
    SUM(c.billed_amount) as lifetime_billed,
    SUM(c.paid_amount) as lifetime_paid,
    MAX(c.service_date) as last_service_date,
    MIN(c.service_date) as first_service_date
  FROM `prefab-bruin-489518-h1.fakelando_health.claims` c
  WHERE c.claim_status = 'Paid'
  GROUP BY c.patient_mrn
)

SELECT
  fv.*,
  COALESCE(pr.total_claims, 0) as total_claims,
  COALESCE(pr.lifetime_billed, 0) as lifetime_billed,
  COALESCE(pr.lifetime_paid, 0) as lifetime_paid,
  pr.last_service_date,
  pr.first_service_date,
  -- Calculate LTV (using paid amount as proxy)
  COALESCE(pr.lifetime_paid, 0) as estimated_ltv,
  -- Time to first revenue
  DATE_DIFF(COALESCE(pr.first_service_date, CURRENT_DATE()), fv.first_visit_date, DAY) as days_to_first_revenue,
  -- Cohort month
  FORMAT_DATE('%Y-%m', fv.first_visit_date) as cohort_month
FROM first_visit fv
LEFT JOIN patient_revenue pr ON fv.patient_mrn = pr.patient_mrn;

-- ============================================================================
-- 2. CHANNEL PERFORMANCE - CAC & LTV
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.channel_performance` AS

WITH channel_stats AS (
  SELECT
    acquisition_channel,
    acquisition_source,
    acquisition_medium,
    acquisition_campaign,
    cohort_month,
    COUNT(DISTINCT patient_mrn) as new_patients,
    SUM(estimated_ltv) as total_ltv,
    AVG(estimated_ltv) as avg_ltv,
    SUM(CASE WHEN estimated_ltv > 0 THEN 1 ELSE 0 END) as revenue_patients,
    SAFE_DIVIDE(SUM(CASE WHEN estimated_ltv > 0 THEN 1 ELSE 0 END), COUNT(DISTINCT patient_mrn)) as conversion_rate
  FROM `prefab-bruin-489518-h1.fakelando_health.patient_acquisition_cohorts`
  GROUP BY acquisition_channel, acquisition_source, acquisition_medium, acquisition_campaign, cohort_month
),

-- Simulate marketing spend (in real scenario, this comes from ad platform APIs)
marketing_spend AS (
  SELECT
    cs.acquisition_channel as channel,
    cs.acquisition_source as source,
    cs.acquisition_medium as medium,
    cs.acquisition_campaign as campaign,
    cs.cohort_month as month,
    cs.new_patients,
    -- Simulated spend based on channel typical costs
    CASE 
      WHEN cs.acquisition_channel = 'Paid Search' THEN CAST(cs.new_patients * (200 + RAND() * 100) AS INT64)
      WHEN cs.acquisition_channel = 'Paid Social' THEN CAST(cs.new_patients * (150 + RAND() * 80) AS INT64)
      WHEN cs.acquisition_channel = 'Email Marketing' THEN CAST(cs.new_patients * (20 + RAND() * 30) AS INT64)
      ELSE CAST(cs.new_patients * (50 + RAND() * 50) AS INT64)
    END as marketing_spend,
    -- Simulated impressions/clicks
    CASE 
      WHEN cs.acquisition_channel = 'Paid Search' THEN CAST(cs.new_patients * (80 + RAND() * 40) AS INT64)
      WHEN cs.acquisition_channel = 'Paid Social' THEN CAST(cs.new_patients * (120 + RAND() * 60) AS INT64)
      WHEN cs.acquisition_channel = 'Organic Search' THEN CAST(cs.new_patients * (200 + RAND() * 100) AS INT64)
      ELSE CAST(cs.new_patients * (100 + RAND() * 50) AS INT64)
    END as clicks,
    CASE 
      WHEN cs.acquisition_channel = 'Paid Search' THEN CAST(cs.new_patients * (80 + RAND() * 40) * (15 + RAND() * 10) AS INT64)
      WHEN cs.acquisition_channel = 'Paid Social' THEN CAST(cs.new_patients * (120 + RAND() * 60) * (8 + RAND() * 5) AS INT64)
      WHEN cs.acquisition_channel = 'Organic Search' THEN CAST(cs.new_patients * (200 + RAND() * 100) * (25 + RAND() * 15) AS INT64)
      ELSE CAST(cs.new_patients * (100 + RAND() * 50) * (10 + RAND() * 5) AS INT64)
    END as impressions
  FROM channel_stats cs
)

SELECT
  cs.*,
  ms.marketing_spend,
  ms.clicks,
  ms.impressions,
  -- CAC = Spend / New Patients
  SAFE_DIVIDE(ms.marketing_spend, cs.new_patients) as cac,
  -- ROAS = Revenue / Spend
  SAFE_DIVIDE(cs.total_ltv, ms.marketing_spend) as roas,
  -- LTV:CAC Ratio
  SAFE_DIVIDE(cs.avg_ltv, SAFE_DIVIDE(ms.marketing_spend, cs.new_patients)) as ltv_cac_ratio,
  -- CTR
  SAFE_DIVIDE(ms.clicks, ms.impressions) * 100 as ctr_pct,
  -- CPL = Spend / Leads (using new_patients as leads)
  SAFE_DIVIDE(ms.marketing_spend, cs.new_patients) as cpl,
  -- Payback period (months) - simplified
  SAFE_DIVIDE(SAFE_DIVIDE(ms.marketing_spend, cs.new_patients), cs.avg_ltv / 12) as payback_months
FROM channel_stats cs
LEFT JOIN marketing_spend ms 
  ON cs.acquisition_channel = ms.channel
  AND cs.acquisition_source = ms.source
  AND cs.acquisition_medium = ms.medium
  AND cs.acquisition_campaign = ms.campaign
  AND cs.cohort_month = ms.month;

-- ============================================================================
-- 3. COHORT RETENTION ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.cohort_retention` AS

WITH patient_monthly AS (
  SELECT
    pac.patient_mrn,
    pac.cohort_month,
    pac.acquisition_channel,
    DATE_TRUNC(v.visit_date, MONTH) as activity_month,
    DATE_DIFF(DATE_TRUNC(v.visit_date, MONTH), DATE(pac.cohort_month), MONTH) as months_since_cohort,
    1 as active
  FROM `prefab-bruin-489518-h1.fakelando_health.patient_acquisition_cohorts` pac
  JOIN `prefab-bruin-489518-h1.fakelando_health.visits` v 
    ON pac.patient_mrn = v.patient_mrn
  WHERE v.visit_status = 'Completed'
),

cohort_base AS (
  SELECT
    cohort_month,
    acquisition_channel,
    COUNT(DISTINCT patient_mrn) as cohort_size
  FROM `prefab-bruin-489518-h1.fakelando_health.patient_acquisition_cohorts`
  GROUP BY cohort_month, acquisition_channel
),

retention_matrix AS (
  SELECT
    pm.cohort_month,
    pm.acquisition_channel,
    pm.months_since_cohort,
    COUNT(DISTINCT pm.patient_mrn) as active_patients,
    cb.cohort_size,
    SAFE_DIVIDE(COUNT(DISTINCT pm.patient_mrn), cb.cohort_size) * 100 as retention_rate_pct
  FROM patient_monthly pm
  JOIN cohort_base cb 
    ON pm.cohort_month = cb.cohort_month 
    AND pm.acquisition_channel = cb.acquisition_channel
  WHERE pm.months_since_cohort <= 12
  GROUP BY pm.cohort_month, pm.acquisition_channel, pm.months_since_cohort, cb.cohort_size
)

SELECT * FROM retention_matrix
ORDER BY cohort_month, acquisition_channel, months_since_cohort;

-- ============================================================================
-- 4. REVENUE ATTRIBUTION BY CHANNEL
-- ============================================================================

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.revenue_attribution` AS

WITH attribution AS (
  SELECT
    pac.acquisition_channel,
    pac.acquisition_source,
    pac.acquisition_medium,
    pac.acquisition_campaign,
    pac.cohort_month,
    SUM(pac.estimated_ltv) as attributed_revenue,
    COUNT(DISTINCT pac.patient_mrn) as attributed_patients,
    AVG(pac.estimated_ltv) as avg_revenue_per_patient
  FROM `prefab-bruin-489518-h1.fakelando_health.patient_acquisition_cohorts` pac
  WHERE pac.estimated_ltv > 0
  GROUP BY pac.acquisition_channel, pac.acquisition_source, pac.acquisition_medium, pac.acquisition_campaign, pac.cohort_month
),

total_revenue AS (
  SELECT SUM(attributed_revenue) as total_rev FROM attribution
)

SELECT
  a.*,
  -- Percentage of total revenue
  SAFE_DIVIDE(a.attributed_revenue, tr.total_rev) * 100 as revenue_share_pct,
  -- Cumulative revenue share (calculated in Looker Studio via running sum)
  a.attributed_revenue as cumulative_revenue_for_sorting
FROM attribution a
CROSS JOIN total_revenue tr
ORDER BY a.attributed_revenue DESC;

-- ============================================================================
-- USAGE EXAMPLES:
-- ============================================================================

-- Channel performance dashboard:
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.channel_performance`
-- WHERE cohort_month >= '2025-01'
-- ORDER BY roas DESC;

-- Cohort retention heatmap:
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.cohort_retention`
-- WHERE cohort_month >= '2025-01'
-- ORDER BY cohort_month, acquisition_channel, months_since_cohort;

-- Revenue attribution:
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.revenue_attribution`
-- ORDER BY attributed_revenue DESC;