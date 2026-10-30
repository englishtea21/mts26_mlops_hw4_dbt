SELECT * FROM {{ ref('stg_transactions') }} WHERE 
lat not between -90 and 90 AND lon not between -180 and 180 AND merchant_lat not between -90 and 90 AND merchant_lon between -180 and 180