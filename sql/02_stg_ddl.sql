CREATE TABLE IF NOT EXISTS stg.customers (
    customer_id integer,
    customer_name text,
    signup_dt date,
    region text,
    customer_segment text
)
DISTRIBUTED REPLICATED;

CREATE TABLE IF NOT EXISTS stg.channels (
    channel_id integer,
    channel_name text,
    channel_type text
)
DISTRIBUTED REPLICATED;

CREATE TABLE IF NOT EXISTS stg.campaigns (
    campaign_id integer,
    campaign_name text,
    channel_id integer,
    start_dt date,
    end_dt date,
    budget numeric(14,2)
)
DISTRIBUTED REPLICATED;

CREATE TABLE IF NOT EXISTS stg.orders (
    order_id integer,
    order_dt date,
    customer_id integer,
    campaign_id integer,
    order_amount numeric(14,2),
    order_status text
)
DISTRIBUTED BY (order_id)
PARTITION BY RANGE (order_dt)
(
    START (DATE '2024-01-01') INCLUSIVE
    END (DATE '2024-07-01') EXCLUSIVE
    EVERY (INTERVAL '1 month'),
    DEFAULT PARTITION other
);

CREATE TABLE IF NOT EXISTS stg.order_items (
    order_item_id integer,
    order_id integer,
    product_id integer,
    product_name text,
    quantity integer,
    price numeric(14,2)
)
DISTRIBUTED BY (order_id);