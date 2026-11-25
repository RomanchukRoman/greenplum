DROP TABLE IF EXISTS cdm.dm_sales_performance;

CREATE TABLE cdm.dm_sales_performance (
    report_dt date,
    campaign_id integer,
    campaign_name text,
    channel_id integer,
    channel_name text,
    orders_count bigint,
    customers_count bigint,
    order_amount numeric(14,2),
    avg_order_amount numeric(14,2),
    new_customers bigint,
    campaign_budget numeric(14,2),
    spend numeric,
    revenue numeric(14,2),
    roi numeric(18,6)
)
DISTRIBUTED BY (campaign_id);

INSERT INTO cdm.dm_sales_performance (
    report_dt,
    campaign_id,
    campaign_name,
    channel_id,
    channel_name,
    orders_count,
    customers_count,
    order_amount,
    avg_order_amount,
    new_customers,
    campaign_budget,
    spend,
    revenue,
    roi
)
WITH completed AS (
    SELECT
        order_dt,
        customer_id,
        campaign_id,
        order_amount
    FROM dds.fact_orders
    WHERE order_status = 'completed'
),
first_orders AS (
    SELECT
        customer_id,
        MIN(order_dt) AS first_dt
    FROM completed
    GROUP BY customer_id
),
daily AS (
    SELECT
        o.order_dt AS report_dt,
        o.campaign_id,
        COUNT(*) AS orders_count,
        COUNT(DISTINCT o.customer_id) AS customers_count,
        SUM(o.order_amount) AS order_amount,
        COUNT(DISTINCT o.customer_id) FILTER (WHERE o.order_dt = f.first_dt) AS new_customers
    FROM completed AS o
    JOIN first_orders AS f ON f.customer_id = o.customer_id
    GROUP BY o.order_dt, o.campaign_id
),
campaign_span AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        c.channel_id,
        ch.channel_name,
        c.budget,
        LEAST(c.start_dt, COALESCE(bounds.min_order_dt, c.start_dt)) AS first_dt,
        GREATEST(c.end_dt, COALESCE(bounds.max_order_dt, c.end_dt)) AS last_dt
    FROM dds.dim_campaigns AS c
    JOIN dds.dim_channels AS ch ON ch.channel_id = c.channel_id
    LEFT JOIN (
        SELECT
            campaign_id,
            MIN(order_dt) AS min_order_dt,
            MAX(order_dt) AS max_order_dt
        FROM completed
        GROUP BY campaign_id
    ) AS bounds ON bounds.campaign_id = c.campaign_id
),
campaign_days AS (
    SELECT
        s.campaign_id,
        s.campaign_name,
        s.channel_id,
        s.channel_name,
        s.budget,
        (s.first_dt + n)::date AS report_dt,
        s.budget / (s.last_dt - s.first_dt + 1)::numeric AS spend
    FROM campaign_span AS s
    JOIN generate_series(0, 400) AS n
        ON n <= (s.last_dt - s.first_dt)
)
SELECT
    days.report_dt,
    days.campaign_id,
    days.campaign_name,
    days.channel_id,
    days.channel_name,
    COALESCE(d.orders_count, 0) AS orders_count,
    COALESCE(d.customers_count, 0) AS customers_count,
    COALESCE(d.order_amount, 0)::numeric(14,2) AS order_amount,
    CASE
        WHEN COALESCE(d.orders_count, 0) = 0 THEN 0
        ELSE (d.order_amount / d.orders_count)::numeric(14,2)
    END AS avg_order_amount,
    COALESCE(d.new_customers, 0) AS new_customers,
    days.budget AS campaign_budget,
    days.spend,
    COALESCE(d.order_amount, 0)::numeric(14,2) AS revenue,
    (
        (COALESCE(d.order_amount, 0) - days.spend)
        / NULLIF(days.spend, 0)
    )::numeric(18,6) AS roi
FROM campaign_days AS days
LEFT JOIN daily AS d
    ON d.campaign_id = days.campaign_id
   AND d.report_dt = days.report_dt;
