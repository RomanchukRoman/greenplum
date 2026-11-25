-- Топ кампаний по ROI
SELECT
    campaign_id,
    campaign_name,
    SUM(revenue) AS revenue,
    SUM(spend) AS spend,
    (SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0) AS roi
FROM cdm.dm_sales_performance
GROUP BY campaign_id, campaign_name
ORDER BY roi DESC;

-- Затраты против бюджета
SELECT
    campaign_id,
    campaign_name,
    SUM(spend) AS spend,
    MAX(campaign_budget) AS campaign_budget,
    SUM(spend) - MAX(campaign_budget) AS budget_diff
FROM cdm.dm_sales_performance
GROUP BY campaign_id, campaign_name
ORDER BY campaign_id;

-- Новые клиенты по кампании
SELECT
    campaign_id,
    campaign_name,
    SUM(new_customers) AS new_customers
FROM cdm.dm_sales_performance
GROUP BY campaign_id, campaign_name
ORDER BY new_customers DESC;

-- Отчёт по рекламным каналам
SELECT
    channel_id,
    channel_name,
    SUM(orders_count) AS orders_count,
    SUM(revenue) AS revenue,
    SUM(spend) AS spend,
    (SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0) AS roi
FROM cdm.dm_sales_performance
GROUP BY channel_id, channel_name
ORDER BY channel_id;
