TRUNCATE dds.dim_customers, dds.dim_channels, dds.dim_campaigns, dds.fact_orders, dds.fact_order_items;

INSERT INTO dds.dim_customers (customer_id, customer_name, signup_dt, region, customer_segment, load_dt, load_src)
SELECT customer_id, customer_name, signup_dt, region, customer_segment, CURRENT_TIMESTAMP, 'stg.customers' FROM stg.customers;

INSERT INTO dds.dim_channels (channel_id, channel_name, channel_type, load_dt, load_src)
SELECT channel_id, channel_name, channel_type, CURRENT_TIMESTAMP, 'stg.channels' FROM stg.channels;

INSERT INTO dds.dim_campaigns (campaign_id, campaign_name, channel_id, start_dt, end_dt, budget, load_dt, load_src)
SELECT campaign_id, campaign_name, channel_id, start_dt, end_dt, budget, CURRENT_TIMESTAMP, 'stg.campaigns' FROM stg.campaigns;

INSERT INTO dds.fact_orders (order_id, order_dt, customer_id, campaign_id, order_amount, order_status, load_dt, load_src)
SELECT order_id, order_dt, customer_id, campaign_id, order_amount, order_status, CURRENT_TIMESTAMP, 'stg.orders' FROM stg.orders;

INSERT INTO dds.fact_order_items (order_item_id, order_id, product_id, product_name, quantity, price, load_dt, load_src)
SELECT order_item_id, order_id, product_id, product_name, quantity, price, CURRENT_TIMESTAMP, 'stg.order_items' FROM stg.order_items;