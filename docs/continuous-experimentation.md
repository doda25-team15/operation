# Continuous Experimentation: New Model Feature

## 1. Description of Change
We are introducing a new version of the Model Service (v2) which contains an experimental spam detection algorithm.
- **Base Design (Control)**: App v1 communicates with Model v1.
- **Experimental Design (Treatment)**: App v2 (Canary) communicates with Model v2.
- **Simulated Difference**: Since both versions share the same image, we use **Istio Fault Injection** to add a fixed 2s delay to Model v2 requests. This simulates a "slower" model to validate our monitoring pipeline.
- **Routing**: Istio DestinationRules and VirtualServices ensure consistent routing, so requests originating from App v1 always go to Model v1, and requests from App v2 always go to Model v2.

## 2. Hypothesis
**Hypothesis**: The new model version (v2) will reduce the average request latency for spam checks without increasing the error rate.
- **Null Hypothesis**: There is no significant difference in latency between Model v1 and Model v2.

## 3. Metrics
We will use the following Prometheus metrics exposed by the Application Service:
- `sms_request_latency_seconds`: Histogram of request latencies. We will compare the p99 and average latency.
- `sms_requests_total`: Counter of total requests, used to measure throughput and error rates (by status code).

## 4. Decision Process
We will monitor the experiment using a Grafana dashboard.
- **Data Availability**: The dashboard visualizes `sms_request_latency_seconds_bucket` to show latency distribution per app version.
- **Criteria**:
  - If Model v2 latency (p99) is < Model v1 latency AND Error Rate v2 <= Error Rate v1 -> **Promote v2**.
  - If Model v2 latency > Model v1 latency OR Error Rate v2 > Error Rate v1 -> **Rollback v2**.

## 5. Visualization
![Grafana Dashboard](grafana_dashboard.jpeg)

## 6. Results & Conclusion
**Date:** 2026-01-09
**Outcome:** FAIL (Rollback Recommended)

**Observations:**
- **App v1 (Stable):** Handled ~75% of traffic with low latency (<50ms) and 0 errors.
- **App v2 (Canary):** Handled ~25% of traffic but experienced high latency (~2s) and timeouts (500 errors).

**Conclusion:**
The experimental Model v2 failed to meet performance requirements. According to the decision process, we must **ROLLBACK** the canary release and investigate the latency source.
