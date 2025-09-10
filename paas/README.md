# PaaS Platforms

This document is some observations of PaaS platforms and what I have noticed from them as far as usability, pricing, etc.

## Railway

**Pricing:**
- Usage based. $10/GB/Month (memory), $20/vCPU/Month (cpu), $0.15/GB/Month (storage/volumes), $0.05/GB/Month (egress)
- The above is for resources that you consume on a monthly basis

**Pros:**
- Really neat/clean UI
- Can drag and drop docker compose and deploy it with some limitation
- Ready-to-use templates for production use such as (redis, postgres, etc.)
- Super easy to use with inputting environment variables, configuring networking to different services, etc
- You can get started in a matter of minutes (as far as infrastructure for hosting services go)

**Cons:**
- Doesn’t support arbitrary container registries when deploying images
- No declarative API (really a benefit of kubernetes) so it can get unwieldy when you are trying to deploy multiple services with various environment variables, etc
- Can’t seem to zoom in on a timeline on the observability dashboards
- Limited observability options in general, might need to use a different observability vendor for more detailed metrics, etc
- As I was generating load onto my APIs, I didn’t seem as though the estimated costs were being reflected actively? There is definitely CPU/Memory usage but the costs remain 0 throughout the load test, and the estimated cost is the only thing going up
- Usage based pricing could get hard for prediction and budget forecasting purposes
- There is a 500 log lines/second limit
