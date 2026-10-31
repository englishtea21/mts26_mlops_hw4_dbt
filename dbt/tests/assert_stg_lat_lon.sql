select *
from {{ ref('stg_transactions') }}
where
    lat not between -90 and 90
    or lon not between -180 and 180
    or merchant_lat not between -90 and 90
    or merchant_lon not between -180 and 180
