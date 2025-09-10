# Observability

## Grafana Cloud

### How Grafana Charges for Metrics

Grafana Cloud uses a usage-based billing model centered around **active series** - time series that actively receive new data points.

### Key Billing Concepts

#### Active Series

- **What it is**: Time series that receive new data points or samples. Series are considered active if they have received new data in the past 20 mins
- **When it stops being active**: Shortly after you stop writing new data points to it
- **Metric vs series**: A series is an instance of a metric with a set of label values. For instance a metric could be `http_requests`, and the 2 series of that metric could be
  `http_requests{method="POST"}`, `http_requests{method="GET"}`
- **Billing rate**: $8 per 1,000 active metric series
- **How to find?**: You can query the `grafanacloud_instance_active_series` metric under the `grafanacloud_usage` datasource. This will tell you the amount of active series that are present

#### 95th Percentile Billing

- Grafana charges based on the **95th percentile** of your total active series usage
- **Benefit**: Top 5% of usage spikes aren't billed (roughly 36 hours per month)
- **Purpose**: Protects against unexpected or temporary usage spikes

#### Data Points Per Minute (DPM)

- **Default**: 1 DPM per active series (Pro tier)
- **Additional charges**: Apply if you send data more frequently
- **Impact**: Higher frequency = higher costs

### Dashboards

- **Cardinality Management**: You want to reduce high cardinality metrics as much as possible. Grafana cloud includes a series of dashboards for cardinality monitoring. They are labeled "Cardinality Management - N", and there are 2 dashboards for that

### Pricing Tiers

#### Free Tier

- **Included**: 10,000 active series per month
- **Cost**: $0

#### Pro Tier

- **Included**: 10,000 active series per month
- **Additional usage**: Pay-as-you-go at $8 per 1,000 series
- **Bundle includes**: 50 GB logs, traces, and profiles

## Datadog
