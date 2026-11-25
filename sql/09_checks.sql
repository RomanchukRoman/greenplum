-- Сверка обязательных объектов и согласованности витрины с фактом.
-- Ничего не изменяет. При расхождении прерывает выполнение.

DO $$
DECLARE
    missing_tables int;
    missing_columns int;
    stg_customers bigint;
    stg_channels bigint;
    stg_campaigns bigint;
    stg_orders bigint;
    stg_items bigint;
    dds_customers bigint;
    dds_channels bigint;
    dds_campaigns bigint;
    dds_orders bigint;
    dds_items bigint;
    mart_orders bigint;
    mart_amount numeric;
    fact_orders bigint;
    fact_amount numeric;
    bad_rows bigint;
    lost_customers bigint;
    lost_campaigns bigint;
    outside_status bigint;
BEGIN
    SELECT COUNT(*) INTO missing_tables
    FROM (
        VALUES
            ('stg', 'customers'),
            ('stg', 'channels'),
            ('stg', 'campaigns'),
            ('stg', 'orders'),
            ('stg', 'order_items'),
            ('dds', 'dim_customers'),
            ('dds', 'dim_channels'),
            ('dds', 'dim_campaigns'),
            ('dds', 'fact_orders'),
            ('dds', 'fact_order_items'),
            ('cdm', 'dm_sales_performance')
    ) AS required(schema_name, table_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.tables AS t
        WHERE t.table_schema = required.schema_name
          AND t.table_name = required.table_name
    );

    IF missing_tables > 0 THEN
        RAISE EXCEPTION 'Не хватает обязательных таблиц: %', missing_tables;
    END IF;

    SELECT COUNT(*) INTO missing_columns
    FROM (
        VALUES
            ('cdm', 'dm_sales_performance', 'report_dt'),
            ('cdm', 'dm_sales_performance', 'campaign_id'),
            ('cdm', 'dm_sales_performance', 'campaign_name'),
            ('cdm', 'dm_sales_performance', 'channel_id'),
            ('cdm', 'dm_sales_performance', 'channel_name'),
            ('cdm', 'dm_sales_performance', 'orders_count'),
            ('cdm', 'dm_sales_performance', 'customers_count'),
            ('cdm', 'dm_sales_performance', 'order_amount'),
            ('cdm', 'dm_sales_performance', 'avg_order_amount'),
            ('cdm', 'dm_sales_performance', 'new_customers'),
            ('cdm', 'dm_sales_performance', 'campaign_budget'),
            ('cdm', 'dm_sales_performance', 'spend'),
            ('cdm', 'dm_sales_performance', 'revenue'),
            ('cdm', 'dm_sales_performance', 'roi'),
            ('dds', 'dim_customers', 'load_dt'),
            ('dds', 'dim_customers', 'load_src'),
            ('dds', 'dim_channels', 'load_dt'),
            ('dds', 'dim_channels', 'load_src'),
            ('dds', 'dim_campaigns', 'load_dt'),
            ('dds', 'dim_campaigns', 'load_src'),
            ('dds', 'fact_orders', 'load_dt'),
            ('dds', 'fact_orders', 'load_src'),
            ('dds', 'fact_order_items', 'load_dt'),
            ('dds', 'fact_order_items', 'load_src')
    ) AS required(schema_name, table_name, column_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns AS c
        WHERE c.table_schema = required.schema_name
          AND c.table_name = required.table_name
          AND c.column_name = required.column_name
    );

    IF missing_columns > 0 THEN
        RAISE EXCEPTION 'Не хватает обязательных колонок: %', missing_columns;
    END IF;

    SELECT COUNT(*) INTO stg_customers FROM stg.customers;
    SELECT COUNT(*) INTO stg_channels FROM stg.channels;
    SELECT COUNT(*) INTO stg_campaigns FROM stg.campaigns;
    SELECT COUNT(*) INTO stg_orders FROM stg.orders;
    SELECT COUNT(*) INTO stg_items FROM stg.order_items;
    SELECT COUNT(*) INTO dds_customers FROM dds.dim_customers;
    SELECT COUNT(*) INTO dds_channels FROM dds.dim_channels;
    SELECT COUNT(*) INTO dds_campaigns FROM dds.dim_campaigns;
    SELECT COUNT(*) INTO dds_orders FROM dds.fact_orders;
    SELECT COUNT(*) INTO dds_items FROM dds.fact_order_items;

    IF stg_customers < 100 OR stg_channels < 4 OR stg_campaigns < 10
       OR stg_orders < 600 OR stg_items < 2000 THEN
        RAISE EXCEPTION 'В STG меньше минимального объёма';
    END IF;

    IF dds_customers <> stg_customers OR dds_channels <> stg_channels
       OR dds_campaigns <> stg_campaigns OR dds_orders <> stg_orders
       OR dds_items <> stg_items THEN
        RAISE EXCEPTION 'Число строк DDS не совпало со STG';
    END IF;

    SELECT COUNT(*) INTO outside_status
    FROM stg.orders
    WHERE order_status NOT IN ('completed', 'cancelled', 'returned');

    IF outside_status > 0 THEN
        RAISE EXCEPTION 'В заказах есть посторонний статус';
    END IF;

    SELECT COUNT(*) INTO lost_customers
    FROM dds.fact_orders AS f
    LEFT JOIN dds.dim_customers AS c ON c.customer_id = f.customer_id
    WHERE c.customer_id IS NULL;

    SELECT COUNT(*) INTO lost_campaigns
    FROM dds.fact_orders AS f
    LEFT JOIN dds.dim_campaigns AS c ON c.campaign_id = f.campaign_id
    WHERE c.campaign_id IS NULL;

    IF lost_customers > 0 OR lost_campaigns > 0 THEN
        RAISE EXCEPTION 'У факта заказов потеряны ключи измерений';
    END IF;

    SELECT SUM(orders_count), SUM(order_amount)
    INTO mart_orders, mart_amount
    FROM cdm.dm_sales_performance;

    SELECT COUNT(*), SUM(order_amount)
    INTO fact_orders, fact_amount
    FROM dds.fact_orders
    WHERE order_status = 'completed';

    IF mart_orders IS DISTINCT FROM fact_orders
       OR mart_amount IS DISTINCT FROM fact_amount THEN
        RAISE EXCEPTION
            'Витрина не сошлась с завершёнными заказами: % / % против % / %',
            mart_orders, mart_amount, fact_orders, fact_amount;
    END IF;

    SELECT COUNT(*) INTO bad_rows
    FROM cdm.dm_sales_performance
    WHERE orders_count < 0
       OR customers_count > orders_count
       OR spend <= 0
       OR roi IS NULL
       OR new_customers IS NULL
       OR revenue IS NULL;

    IF bad_rows > 0 THEN
        RAISE EXCEPTION 'В витрине % строк с неверными метриками', bad_rows;
    END IF;

    RAISE NOTICE 'Проверка пройдена: заказов %, сумма %', mart_orders, mart_amount;
END $$;
