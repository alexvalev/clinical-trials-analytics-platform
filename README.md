# Clinical Trials Analytics Platform
 
An end-to-end data engineering and machine learning platform for analyzing global clinical trial trends and predicting trial duration using the AACT database from ClinicalTrials.gov.
 
---
 
## Central Question
 
**Predicting clinical trial duration based on information available at the time of trial registration.**
 
Understanding how long a clinical trial will take is valuable for sponsors, regulators, and researchers — it informs resource planning, budgeting, and portfolio prioritization. By using only information known at registration (phase, sponsor type, enrollment size, number of facilities, disease area), we avoid data leakage and build a model that could realistically be used in practice.
 
---
 
## Architecture
 
```
AACT Raw Files (pipe-delimited .txt)
            ↓
    Databricks Volumes (raw storage)
            ↓
    Bronze Delta Tables (raw ingestion)
            ↓
    Silver Delta Tables (cleaned & typed)
            ↓
    dbt Gold Models (analytics-ready)
            ↓
    Spark ML + MLflow (duration prediction)
            ↓
    Predictions Delta Table
```
 
*Architecture diagram coming soon.*
 
---
 
## Tool Stack
 
| Layer | Tool |
|---|---|
| Raw storage | Databricks Volumes |
| Cloud platform | Microsoft Azure |
| Orchestration | Apache Airflow |
| Processing | Databricks (PySpark) |
| Storage format | Delta Lake |
| Transformation | dbt |
| ML training | Spark ML |
| Experiment tracking | MLflow |
| Version control | GitHub |
 
---
 
## Dataset
 
**Source:** [AACT — Aggregate Analysis of ClinicalTrials.gov](https://aact.ctti-clinicaltrials.org)
 
AACT is a publicly available relational database containing all studies registered on ClinicalTrials.gov. It is updated daily and available as a free static download in pipe-delimited format. The database contains 587,788 trial records in total.
 
---
 
## Data Pipeline
 
### Bronze Layer
Raw files are ingested from Databricks Volumes into Delta tables with no transformations applied. All columns are retained as strings, preserving the source data exactly as received.
 
**Bronze tables:**
- `bronze_studies`
- `bronze_calculated_values`
- `bronze_conditions`
- `bronze_sponsors`
- `bronze_interventions`
- `bronze_facilities`
### Silver Layer
Bronze tables are cleaned, typed, and filtered. Key transformations include:
 
- Date columns cast from string to date type
- Numeric columns cast from string to integer or float
- Rows with null `nct_id` removed
- `minimum_age_num` null values filled with 0 (no lower age bound)
- `maximum_age_num` null values filled with 999 (no upper age bound)
- `has_age_restriction` flag derived: True when minimum > 0 or maximum < 999
- Lead sponsors filtered from the sponsors table (collaborators excluded)
**Silver tables:**
- `silver_studies`
- `silver_calculated_values`
- `silver_conditions`
- `silver_sponsors`
### Gold Layer (dbt)
Silver tables are transformed into analytics-ready models using dbt.
 
**Staging models:**
- `stg_studies`
- `stg_calculated_values`
**Mart models:**
- `dim_conditions`
- `dim_sponsors`
- `fact_trials`
**Feature models:**
- `gold_trial_features` — joined, enriched feature table used as ML input
---
 
## Feature Engineering & Modeling Decisions
 
### Target Variable
`actual_duration` (months) — the number of months from trial start date to completion date, as calculated by AACT.
 
Only trials with a non-null `actual_duration` are used for model training (~360,000 records).
 
### Features Used
 
| Feature | Source | Rationale |
|---|---|---|
| `phase` | studies | Strong structural predictor — Phase 3 trials are designed to be longer |
| `study_type` | studies | Interventional vs observational trials have different timelines |
| `agency_class` | sponsors | NIH-funded trials are significantly longer than industry-funded trials |
| `enrollment` | studies | Larger enrollment requires more time to recruit patients |
| `enrollment_type` | studies | Indicates whether enrollment is estimated or actual |
| `number_of_facilities` | calculated_values | More sites correlates with longer, more complex trials |
| `minimum_age_num` | calculated_values | Proxy for how targeted the patient population is |
| `maximum_age_num` | calculated_values | Combined with minimum age captures age restriction scope |
| `has_age_restriction` | derived | Whether the trial has any age eligibility criteria |
| `is_fda_regulated_drug` | studies | FDA-regulated trials face additional compliance requirements |
| `has_dmc` | studies | Data monitoring committees indicate higher-complexity trials |
 
### Leakage Considerations
 
**`were_results_reported` — excluded.** Whether results were reported is only known after trial completion and cannot be used to predict duration at registration time.
 
**`enrollment` when `enrollment_type = ACTUAL` — included with caveat.** Final enrollment numbers are only confirmed at trial completion, meaning they may carry mild leakage. However, since enrollment targets are set at registration and actual values rarely deviate dramatically, we include them and document this limitation. This decision prioritizes model coverage over strict purity.
 
**`number_of_facilities` — included with caveat.** The final number of participating facilities may change over the course of a trial. However, planned facility counts are typically submitted at registration, making this a reasonable proxy for planned trial scale.
 
---
 
## Machine Learning Results
 
*To be updated after model training.*
 
---
 
## How to Run
 
### Prerequisites
- Databricks Free Edition account
- dbt Core installed locally
- Apache Airflow installed locally
- Azure account with ADLS Gen2 storage
### Setup
 
1. Clone the repository:
   ```bash
   git clone https://github.com/alexvalev/clinical-trials-analytics-platform.git
   cd clinical-trials-analytics-platform
   ```
 
2. Download the AACT pipe-delimited static copy from [aact.ctti-clinicaltrials.org/download](https://aact.ctti-clinicaltrials.org/download)
3. Upload the following files to your Databricks Volume at `/Volumes/clinical_trials/raw/clinical_trials_raw/`:
   - `studies.txt`
   - `calculated_values.txt`
   - `conditions.txt`
   - `sponsors.txt`
   - `interventions.txt`
   - `facilities.txt`
4. Run the Databricks notebooks in order:
   - `00_data_exploration`
   - `01_bronze_ingestion`
   - `02_silver_transformation`
   - `03_ml_training`
5. Run dbt:
   ```bash
   cd dbt/clinical_trials
   dbt run
   dbt test
   dbt docs generate
   ```
 
6. Trigger the Airflow DAG:
   ```bash
   cd airflow
   airflow dags trigger clinical_trials_pipeline
   ```
 
---
 
## Future Improvements
 
- Connect raw file ingestion directly from Azure Data Lake Storage once cluster-level authentication is supported
- Add Great Expectations data quality checks in the Silver layer
- Extend the model to predict trial success/failure as a classification task
- Build a Databricks dashboard for trial trend visualization
---
 
## Repository Structure
 
```
clinical-trials-analytics-platform/
├── notebooks/
│   ├── 00_exploration/
│   ├── 01_bronze/
│   ├── 02_silver/
│   ├── 03_gold/
│   └── 04_ml/
├── dbt/
│   └── clinical_trials/
│       └── models/
│           ├── staging/
│           ├── marts/
│           └── features/
├── airflow/
│   └── dags/
├── images/
├── docs/
└── README.md
```