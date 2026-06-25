with fact as (
    select * from {{ ref('fact_trials') }}
),

-- Filter to trials suitable for ML training
ml_ready as (
    select
        nct_id,
        -- Target variable
        actual_duration,

        -- Trial characteristics (known at registration)
        study_type,
        coalesce(phase, 'UNKNOWN') as phase,
        enrollment,
        coalesce(enrollment_type, 'UNKNOWN') as enrollment_type,
        coalesce(number_of_arms, 0) as number_of_arms,
        coalesce(has_dmc, false) as has_dmc,
        coalesce(is_fda_regulated_drug, false) as is_fda_regulated_drug,
        coalesce(is_fda_regulated_device, false) as is_fda_regulated_device,

        -- Sponsor information
        coalesce(agency_class, 'UNKNOWN') as agency_class,

        -- Facility and site information
        number_of_facilities,
        coalesce(has_us_facility, false) as has_us_facility,
        coalesce(has_single_facility, false) as has_single_facility,

        -- Age eligibility
        minimum_age_num,
        maximum_age_num,
        has_age_restriction,

        -- Outcomes complexity
        coalesce(number_of_primary_outcomes_to_measure, 0) as number_of_primary_outcomes_to_measure,
        coalesce(number_of_secondary_outcomes_to_measure, 0) as number_of_secondary_outcomes_to_measure,

        -- Condition complexity
        condition_count,

        -- Registration year (captures temporal trends)
        registered_in_calendar_year,

        -- Leakage-flagged column (included with documented caveat)
        coalesce(were_results_reported, false) as were_results_reported

    from fact
    where
        -- Must have a target variable
        actual_duration is not null
        -- Must have started and completed
        and start_date is not null
        and completion_date is not null
        -- Exclude unrealistic durations
        and actual_duration > 0
        and actual_duration <= 99
        -- Must have core features
        and study_type is not null
        and number_of_facilities is not null
)

select * from ml_ready