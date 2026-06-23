with source as (
    select * from {{ source('silver', 'silver_calculated_values') }}
),

renamed as (
    select
        nct_id,
        actual_duration,
        number_of_facilities,
        minimum_age_num,
        maximum_age_num,
        has_age_restriction,
        were_results_reported,
        has_us_facility,
        has_single_facility,
        registered_in_calendar_year,
        number_of_primary_outcomes_to_measure,
        number_of_secondary_outcomes_to_measure,
        _transformed_at
    from source
    where nct_id is not null
)

select * from renamed