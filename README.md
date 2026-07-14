# Fakelando Health CDP Demos
========================================

Three dazzling demos built on your BigQuery project `prefab-bruin-489518-h1` using **FREE TIER ONLY** components.

## 🎯 What We Built

### Demo 1: Patient 360° Embedded Dashboard
**Location:** `/home/ubuntu/fakelando-demos/demo1-patient-360/`

- **SQL View:** `patient_360_view.sql` - Comprehensive patient profile combining patients, visits, claims, and chronic conditions
- **Embed Generator:** `embed_url_generator.py` - Creates signed Looker Studio URLs for:
  - Call center agents (real-time patient lookup during calls)
  - Provider portal (clinician access)
  - Billing team portal
  - Patient self-service portal
- **Looker Studio Config:** `patient_360_dashboard.json` - Ready-to-import dashboard

**Data Sources (all in your BigQuery project):**
- `fakelando_health.patients` - 5,000 synthetic patients with demographics, insurance, chronic conditions
- `fakelando_health.visits` - ~20K synthetic visits with types, diagnoses, charges
- `fakelando_health.claims` - ~25K synthetic claims with status, payments, denial reasons
- `fakelando_health.icd10_diagnoses_2019` - 94K real ICD-10 codes from CMS

---

### Demo 2: Marketing Attribution Dashboard
**Location:** `/home/ubuntu/fakelando-demos/demo2-attribution/`

- **SQL Views:** `marketing_attribution_views.sql` - Complete attribution model:
  - `patient_acquisition_cohorts` - First-touch attribution with simulated channels
  - `channel_performance` - CAC, LTV, ROAS, LTV:CAC ratio, payback period
  - `cohort_retention` - Monthly retention heatmaps by channel
  - `revenue_attribution` - Revenue share by channel/campaign

**Simulated Channels:** Paid Search, Organic Search, Paid Social, Email, Direct, Referral

---

### Demo 5: Cross-Platform Cost Governance
**Location:** `/home/ubuntu/fakelando-demos/demo5-cost-governance/`

- **SQL Views:** `cost_governance_views.sql` - Unified cost monitoring:
  - BigQuery: Query costs, storage costs, slot utilization
  - Looker: Platform + user licensing (simulated)
  - Fivetran: MAR-based connector costs
  - Databricks: DBU-hour compute costs by workload
  - `unified_platform_costs` - Single view across all 4 platforms
  - `daily_cost_summary`, `monthly_cost_trends`, `cost_alerts` - Anomaly detection

- **Looker Studio Config:** `cost_governance_dashboard.json` - Executive dashboard with alerts

---

## 📊 BigQuery Project State

Your project `prefab-bruin-489518-h1` now has dataset `fakelando_health` with:

| Table | Rows | Size | Source |
|-------|------|------|--------|
| `patients` | 5,000 | ~1 MB | Synthetic |
| `visits` | ~20,000 | ~5 MB | Synthetic |
| `claims` | ~25,000 | ~6 MB | Synthetic |
| `icd10_diagnoses_2019` | 94,444 | ~3 MB | CMS Public Data |
| `inpatient_charges_2015` | 201,876 | ~36 MB | CMS Medicare |
| `outpatient_charges_2015` | ~100K | ~20 MB | CMS Medicare |
| `hospital_general_info` | 5,336 | ~1.5 MB | CMS Hospital Compare |
| `america_health_rankings` | 18,155 | ~3 MB | America's Health Rankings |

**Total: ~75 MB storage** - Well within BigQuery free tier (10 GB free)

---

## 🆓 Free Tier Status

| Platform | Free Tier | Status |
|----------|-----------|--------|
| **BigQuery** | 1 TB query/month, 10 GB storage | ✅ Active (your project) |
| **Looker Studio** | Completely free | ✅ Ready to use |
| **Fivetran** | 500K MAR/month, 5K model runs | ✅ Sign up at fivetran.com |
| **Databricks** | Free Edition (forever) or 2-week $400 trial | ✅ Sign up at databricks.com/try |

---

## 🚀 Quick Start

### 1. Deploy Patient 360 View (Demo 1)
```bash
# Run the view creation in BigQuery
bq query --use_legacy_sql=false --project_id=prefab-bruin-489518-h1 \
  "$(cat /home/ubuntu/fakelando-demos/demo1-patient-360/patient_360_view.sql)"
```

### 2. Create Looker Studio Dashboard
1. Go to [lookerstudio.google.com](https://lookerstudio.google.com)
2. Create new report → BigQuery connector
2. Select project `prefab-bruin-489518-h1`, dataset `fakelando_health`
3. Add `patient_360_view` as data source
4. Build dashboard using the JSON config as reference

### 3. Test Embedded URL Generator
```bash
cd /home/ubuntu/fakelando-demos/demo1-patient-360
export LOOKER_HOST="https://looker.fakelandohealth.com"
export LOOKER_EMBED_SECRET="your_base64_secret_from_looker_admin"
python3 embed_url_generator.py
```

### 4. Deploy Marketing Attribution (Demo 2)
```bash
bq query --use_legacy_sql=false --project_id=prefab-bruin-489518-h1 \
  "$(cat /home/ubuntu/fakelando-demos/demo2-attribution/marketing_attribution_views.sql)"
```

### 5. Deploy Cost Governance (Demo 5)
```bash
bq query --use_legacy_sql=false --project_id=prefab-bruin-489518-h1 \
  "$(cat /home/ubuntu/fakelando-demos/demo5-cost-governance/cost_governance_views.sql)"
```

### 6. Create Cost Governance Dashboard in Looker Studio
Import `looker-studio/cost_governance_dashboard.json` as reference.

---

## 🎬 Demo Scripts for Management

### Demo 1: "Sarah from Call Center"
> "Sarah receives a call from patient PAT-000164. With one click, she sees:
> - 47-year-old male, Commercial insurance, Texas
> - **High risk** (Heart Failure), $27K charges YTD, 7 visits
> - Last visit: June 8, 2026 (Office Visit, Wellness)
> - Claims: 89% payment rate, 2 denied (CO-16 missing info)
> - Chronic: Heart Failure since 2025, Hypertension since 2024
> 
> **All in a sub-second embedded iframe. No context switching.**"

### Demo 2: "CMO Marketing Review"
> "Maria reviews Q1 acquisition:
> - **Paid Search**: CAC $245, LTV $2,100, ROAS 8.6x, Payback 1.4 months
> - **Organic**: CAC $42, LTV $1,800, ROAS 43x, Payback 0.2 months  
> - **Paid Social**: CAC $185, LTV $1,450, ROAS 7.8x, Payback 1.5 months
> - **Email**: CAC $28, LTV $950, ROAS 34x, Payback 0.3 months
> 
> **Insight**: Email is most efficient but low volume. Paid Search scales best."

### Demo 5: "Finance Cost Review"
> "Quarterly CDP cost review:
> - **BigQuery**: $47/month (queries $32, storage $15) - 23% under budget
> - **Databricks**: $234/month (ML training $89, SQL warehouse $67, Jobs $78)
> - **Fivetran**: $156/month (GA4 45%, Salesforce 32%, Stripe 18%)
> - **Looker**: $300/month (Standard edition, 12 users)
> 
> **Total: $737/month** - Alert: Databricks ML training spiked 40% last week (new feature experiment)"

---

## 🔧 Extending the Demos

### Add Real Fivetran Connectors
```bash
# Sign up at fivetran.com (Free Plan: 500K MAR)
# Connectors to add:
# - Google Analytics 4 → BigQuery (fakelando_health.raw_ga4)
# - Salesforce → BigQuery (fakelando_health.raw_salesforce)
# - HubSpot → BigQuery (fakelando_health.raw_hubspot)
# - Stripe → BigQuery (fakelando_health.raw_stripe)
```

### Add Databricks Free Edition
```bash
# Sign up at databricks.com/try (Free Edition)
# Create Unity Catalog metastore
# Run databricks-sdk-client.py to set up:
# - Catalog: fakelando_cdp
# - Schemas: raw, staging, marts, identity, ml_features
# - Identity stitching DLT pipeline
```

### Production-Grade Enhancements
- Row-level security in BigQuery (patient_mrn = @current_user)
- Looker user attributes for automatic filtering
- Fivetran dbt transformations for staging layer
- Databricks Genie for natural language queries
- Alerting via Cloud Monitoring / Looker scheduled delivers

---

## 📁 File Structure

```
/home/ubuntu/fakelando-demos/
├── demo1-patient-360/
│   ├── patient_360_view.sql          # BigQuery view
│   ├── embed_url_generator.py        # Signed URL generator
│   └── README.md
├── demo2-attribution/
│   ├── marketing_attribution_views.sql
│   └── README.md
├── demo5-cost-governance/
│   ├── cost_governance_views.sql
│   └── README.md
├── looker-studio/
│   ├── patient_360_dashboard.json    # Import template
│   ├── cost_governance_dashboard.json
│   └── marketing_attribution_dashboard.json
└── databricks-notebooks/
    └── (for future Databricks Free Edition setup)
```

---

## 💡 Next Steps for Maximum Dazzle

1. **Today**: Import Looker Studio dashboards, demo to team
2. **This Week**: Sign up Fivetran Free + Databricks Free Edition
3. **Next Week**: Replace synthetic data with real Fivetran syncs
4. **Month 1**: Deploy Databricks identity stitching + Genie
5. **Ongoing**: Cost governance dashboard as single pane of glass

---

*Built with ❤️ for Fakelando Health CDP - All free tier, zero spend*