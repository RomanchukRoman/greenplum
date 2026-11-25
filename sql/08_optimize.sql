ANALYZE stg.orders;
ANALYZE stg.order_items;
ANALYZE dds.fact_orders;
ANALYZE dds.fact_order_items;
ANALYZE dds.dim_customers;
ANALYZE dds.dim_campaigns;
ANALYZE dds.dim_channels;
ANALYZE cdm.dm_sales_performance;

EXPLAIN ANALYZE
SELECT *
FROM cdm.dm_sales_performance
WHERE report_dt >= DATE '2024-03-01'
  AND report_dt < DATE '2024-04-01';

EXPLAIN ANALYZE
SELECT o.order_id, c.customer_segment
FROM dds.fact_orders o
JOIN dds.dim_customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'completed';