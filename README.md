# Продажи и маркетинговые кампании

Учебное хранилище в Greenplum. Сырые данные генерируются в базе, складываются в звезду и собираются в одну витрину для отчётов по ROI, новым клиентам, бюджету и каналам.

```mermaid
flowchart LR
  subgraph stgLayer [stg]
    stgCustomers[customers]
    stgChannels[channels]
    stgCampaigns[campaigns]
    stgOrders[orders]
    stgItems[order_items]
  end
  subgraph ddsLayer [dds]
    dimCustomers[dim_customers]
    dimChannels[dim_channels]
    dimCampaigns[dim_campaigns]
    factOrders[fact_orders]
    factItems[fact_order_items]
  end
  subgraph cdmLayer [cdm]
    mart[dm_sales_performance]
  end
  stgLayer --> ddsLayer --> cdmLayer
```

`stg` хранит сгенерированные строки как есть. `dds` раскладывает их на справочники и факты. `cdm` считает показатели по дню и кампании, только по завершённым заказам.

Скрипты лежат в `sql/` и запускаются по номерам, с `01_schemas.sql` по `08_optimize.sql`. Как устроены слои и метрики, написано в [report/architecture.md](report/architecture.md).
