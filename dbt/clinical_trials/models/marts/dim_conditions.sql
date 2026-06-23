with source as (
    select * from {{ source('silver', 'silver_conditions') }}
)

select
    nct_id,
    conditions,
    size(conditions) as condition_count
from source
where nct_id is not null