with studies as (
    select * from {{ ref('stg_studies') }}
),

calc as (
    select * from {{ ref('stg_calculated_values') }}
),

sponsors as (
    select * from {{ ref('dim_sponsors') }}
),

conditions as (
    select * from {{ ref('dim_conditions') }}

),

joined as (
    select
        s.nct_id,
        s.brief_title,
        s.overall_status,
        s.study_type,
        s.phase,
        s.start_date,
        s.completion_date,
        s.primary_completion_date,
        s.enrollment,
        s.enrollment_type,
        s.number_of_arms,
        s.source_class,
        s.has_dmc,
        s.is_fda_regulated_drug,
        s.is_fda_regulated_device,
        c.actual_duration,
        c.number_of_facilities,
        c.minimum_age_num,
        c.maximum_age_num,
        c.has_age_restriction,
        c.were_results_reported,
        c.has_us_facility,
        c.has_single_facility,
        c.registered_in_calendar_year,
        c.number_of_primary_outcomes_to_measure,
        c.number_of_secondary_outcomes_to_measure,
        sp.agency_class,
        sp.sponsor_name,
        cond.conditions,
        cond.condition_count
    from studies s
    left join calc c on s.nct_id = c.nct_id
    left join sponsors sp on s.nct_id = sp.nct_id
    left join conditions cond on s.nct_id = cond.nct_id
)

select * from joined