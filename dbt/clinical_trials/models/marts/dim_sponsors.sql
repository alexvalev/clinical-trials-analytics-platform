with source as (
    select * from {{ source('silver', 'silver_sponsors') }}
)

select
    nct_id,
    agency_class,
    name as sponsor_name
from source
where nct_id is not null