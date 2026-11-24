TRUNCATE stg.order_items, stg.orders, stg.campaigns, stg.customers, stg.channels;

INSERT INTO stg.channels (channel_id, channel_name, channel_type)
SELECT
    g,
    CASE g
        WHEN 1 THEN 'email'
        WHEN 2 THEN 'social'
        WHEN 3 THEN 'search'
        ELSE 'display'
    END,
    CASE WHEN g = 4 THEN 'offline' ELSE 'online' END
FROM generate_series(1, 4) AS g;

INSERT INTO stg.customers (customer_id, customer_name, signup_dt, region, customer_segment)
SELECT
    g,
    'customer_' || g,
    DATE '2023-06-01' + (random() * 400)::int,
    CASE g % 4
        WHEN 0 THEN 'Москва'
        WHEN 1 THEN 'Санкт-Петербург'
        WHEN 2 THEN 'Казань'
        ELSE 'Новосибирск'
    END,
    CASE g % 3
        WHEN 0 THEN 'new'
        WHEN 1 THEN 'regular'
        ELSE 'vip'
    END
FROM generate_series(1, 100) AS g;

INSERT INTO stg.campaigns (campaign_id, campaign_name, channel_id, start_dt, end_dt, budget)
SELECT
    g,
    'campaign_' || g,
    1 + (g % 4),
    DATE '2024-01-01' + ((g - 1) * 15),
    DATE '2024-01-01' + ((g - 1) * 15) + 40,
    round((10000 + random() * 90000)::numeric, 2)
FROM generate_series(1, 10) AS g;

INSERT INTO stg.orders (order_id, order_dt, customer_id, campaign_id, order_amount, order_status)
SELECT
    g,
    c.start_dt + (random() * (c.end_dt - c.start_dt + 1))::int,
    1 + (random() * 99)::int,
    c.campaign_id,
    round((100 + random() * 9900)::numeric, 2),
    CASE
        WHEN random() < 0.75 THEN 'completed'
        WHEN random() < 0.90 THEN 'cancelled'
        ELSE 'returned'
    END
FROM generate_series(1, 600) AS g
JOIN stg.campaigns AS c ON c.campaign_id = 1 + (g % 10);

INSERT INTO stg.order_items (order_item_id, order_id, product_id, product_name, quantity, price)
SELECT
    g,
    1 + (random() * 599)::int,
    1 + (g % 20),
    CASE g % 5
        WHEN 0 THEN 'Чай'
        WHEN 1 THEN 'Кофе'
        WHEN 2 THEN 'Сахар'
        WHEN 3 THEN 'Молоко'
        ELSE 'Печенье'
    END,
    1 + (random() * 4)::int,
    round((50 + random() * 950)::numeric, 2)
FROM generate_series(1, 2000) AS g;