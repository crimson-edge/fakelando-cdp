-- ============================================================================
-- FAKELANDO HEALTH - PATIENT 360° VIEW
-- BigQuery View for Looker Studio Embedded Dashboard
-- ============================================================================

-- This view provides a comprehensive patient profile for the embedded Looker Studio
-- dashboard. It's designed to be filtered by patient_mrn for single-patient views.

CREATE OR REPLACE VIEW `prefab-bruin-489518-h1.fakelando_health.patient_360_view` AS

WITH patient_base AS (
  SELECT
    patient_id,
    patient_mrn,
    gender,
    date_of_birth,
    DATE_DIFF(CURRENT_DATE(), date_of_birth, YEAR) as age,
    insurance_type,
    state,
    patient_status,
    primary_care_provider_id,
    last_visit_date,
    total_charges_ytd,
    visit_count_ytd,
    primary_chronic_condition,
    -- Risk score based on chronic conditions
    CASE
      WHEN primary_chronic_condition IN ('Heart Failure', 'COPD') THEN 'High'
      WHEN primary_chronic_condition IN ('Diabetes', 'Hypertension') THEN 'Medium'
      ELSE 'Low'
    END as clinical_risk_level
  FROM `prefab-bruin-489518-h1.fakelando_health.patients`
),

-- Latest visit summary
latest_visit AS (
  SELECT
    v.patient_mrn,
    MAX(v.visit_date) as latest_visit_date,
    COUNT(DISTINCT v.visit_id) as total_visits,
    SUM(CASE WHEN v.visit_status = 'Completed' THEN v.visit_charges ELSE 0 END) as total_billed,
    COUNT(DISTINCT v.primary_diagnosis_code) as distinct_diagnoses
  FROM `prefab-bruin-489518-h1.fakelando_health.visits` v
  GROUP BY v.patient_mrn
),

-- Claims summary
claims_summary AS (
  SELECT
    c.patient_mrn,
    COUNT(DISTINCT c.claim_id) as total_claims,
    SUM(c.billed_amount) as total_billed,
    SUM(c.paid_amount) as total_paid,
    COUNTIF(c.claim_status = 'Denied') as denied_claims,
    COUNTIF(c.claim_status = 'Pending') as pending_claims,
    SUM(CASE WHEN c.claim_status = 'Paid' THEN c.paid_amount ELSE 0 END) as paid_amount,
    ROUND(SAFE_DIVIDE(SUM(CASE WHEN c.claim_status = 'Paid' THEN c.paid_amount ELSE 0 END), 
                    NULLIF(SUM(c.billed_amount), 0)) * 100, 1) as payment_rate_pct
  FROM `prefab-bruin-489518-h1.fakelando_health.claims` c
  GROUP BY c.patient_mrn
),

-- Chronic condition timeline
condition_timeline AS (
  SELECT
    v.patient_mrn,
    v.primary_diagnosis_code,
    d.short_description as diagnosis_description,
    COUNT(*) as occurrence_count,
    MIN(v.visit_date) as first_occurrence,
    MAX(v.visit_date) as last_occurrence
  FROM `prefab-bruin-489518-h1.fakelando_health.visits` v
  JOIN `prefab-bruin-489518-h1.fakelando_health.icd10_diagnoses_2019` d
    ON v.primary_diagnosis_code = d.cm_code
  WHERE v.visit_status = 'Completed'
  GROUP BY v.patient_mrn, v.primary_diagnosis_code, d.short_description
),

-- Provider summary
provider_summary AS (
  SELECT
    v.patient_mrn,
    COUNT(DISTINCT v.rendering_provider_id) as unique_providers,
    STRING_AGG(DISTINCT 
      CASE WHEN v.rendering_provider_id = v.provider_id THEN 'PCP' ELSE 'Specialist' END,
      ', ') as provider_types
  FROM `prefab-bruin-489518-h1.fakelando_health.visits` v
  GROUP BY v.patient_mrn
)

SELECT
  p.patient_id,
  p.patient_mrn,
  p.gender,
  p.age,
  p.insurance_type,
  p.state,
  p.patient_status,
  p.clinical_risk_level,
  p.primary_chronic_condition,
  p.last_visit_date,
  p.total_charges_ytd,
  p.visit_count_ytd,
  
  -- Visit metrics
  lv.total_visits,
  lv.total_billed,
  lv.latest_visit_date,
  lv.distinct_diagnoses,
  
  -- Claims metrics
  cs.total_claims,
  cs.total_billed as claims_billed,
  cs.total_paid,
  cs.denied_claims,
  cs.pending_claims,
  cs.payment_rate_pct,
  
  -- Provider metrics
  ps.unique_providers,
  ps.provider_types
  
FROM patient_base p
LEFT JOIN latest_visit lv ON p.patient_mrn = lv.patient_mrn
LEFT JOIN claims_summary cs ON p.patient_mrn = cs.patient_mrn
LEFT JOIN provider_summary ps ON p.patient_mrn = ps.patient_mrn;

-- ============================================================================
-- USAGE: 
-- SELECT * FROM `prefab-bruin-489518-h1.fakelando_health.patient_360_view`
-- WHERE patient_mrn = 'PAT-000164';
-- ============================================================================