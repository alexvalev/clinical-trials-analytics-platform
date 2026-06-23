with source as (
    select * from {{ source('silver', 'silver_studies') }}
),

renamed as (
    select
        nct_id,
        overall_status,
        study_type,
        phase,
        start_date,
        completion_date,
        primary_completion_date,
        study_first_submitted_date,
        enrollment,
        enrollment_type,
        number_of_arms,
        source_class,
        has_dmc,
        is_fda_regulated_drug,
        is_fda_regulated_device,
        brief_title,
        source,
        _transformed_at
    from source
    where nct_id is not null
)

select * from renamed