# Extension Proposal: Automated Canary Deployments with Flagger

## 1. Shortcoming: Manual Canary Management & High Operational Toil

### Description
The project currently implements a **Canary Release Strategy** using Istio, but the process is fundamentally **manual and static**. As seen in `load_test.sh` and `virtual-service-app.yaml`, traffic splitting is controlled by hardcoded weights in the Helm values (`.Values.trafficManagement.weights.stable` vs `canary`).

To perform a canary release, an operator must:
1.  Manually edit `values.yaml` to set the canary weight (e.g., from 0% to 10%).
2.  Execute `helm upgrade` to apply the traffic split.
3.  Manually monitor Grafana dashboards or logs to verify the health of the canary.
4.  Manually edit `values.yaml` again to increase traffic or rollback.
5.  Execute `helm upgrade` again.

### Impact & Argumentation
This manual workflow represents a critical shortcoming in the "Release Pipelines" and "Experimentation" practices of the project. It introduces **Operational Toil**—repetitive, manual work devoid of enduring value, which scales linearly with the service growth.

1.  **High Risk of Human Error**: Manual config edits and CLI commands are prone to typos (e.g., routing 100% traffic to a broken canary instead of 10%).
2.  **Slow Feedback Loop**: Verification relies on human vigilance. A bad deployment might persist for minutes or hours before an operator notices a spike in error rates on the dashboard.
3.  **Lack of Safety**: There is no automated rollback mechanism. If the canary fails (e.g., 500 Internal Server Errors), the system stays broken until a human intervenes.
4.  **Scalability Bottleneck**: As the number of microservices grows (App, Model Service, etc.), managing individual canary rollouts manually becomes unmanageable.

The Google SRE Book identifies "Toil" as a major enemy of reliability and recommends automating release processes to ensure consistency and speed [1]. By relying on manual "steps" for traffic shifting, we violate the principle of "Safety in Automation."

## 2. Proposed Extension: Automated Progressive Delivery with Flagger

We propose integrating **Flagger**, an Automated Canary Deployment operator for Kubernetes that works with Istio. Flagger automates the promotion of canary deployments using metrics (Prometheus) and runs acceptance tests to validate the app health.

### Visualization of Change
**Current State:**
`Dev -> Helm Upgrade (Split 10%) -> Human stares at Grafana -> Helm Upgrade (Split 50%) -> ...`

**Proposed State:**
`Dev -> Git Push -> Flagger Controller -> (Automated Traffic Shift 5%..10%..50%) -> (Prometheus Check) -> (Success: Promote / Fail: Rollback)`

### Concrete Implementation Tasks (1-5 Days)
This extension is non-trivial but implementable within the timeframe.

1.  **Install Flagger (Day 1)**:
    - Deploy Flagger to the cluster using its Helm chart.
    - Configure it to communicate with the existing Istio and Prometheus instances.
2.  **Refactor Helm Charts (Day 2)**:
    - Remove the manual `VirtualService` and `DestinationRule` definitions from `sms-checker` chart.
    - Introduce a `Canary` Custom Resource Definition (CRD) object.
    - Configure the `Canary` resource to target the `Deployment` and define the Service reference.
3.  **Define Metric Templates (Day 3)**:
    - Define `MetricTemplate` resources for custom metrics if needed, or use built-in request success rate and latency checks provided by Flagger (querying existing Prometheus).
4.  **Implement Webhooks (Day 3-4)**:
    - Create a "load-tester" deployment (using Flagger's load tester image).
    - Configure pre-rollout implementation hooks to run integration tests (e.g., `curl` specific endpoints) before routing traffic.
5.  **Testing & Verification (Day 5)**:
    - Verify the setup by triggering a release and observing the automated rollout.

### Expected Outcome
- **Zero-Touch Deployments**: Developers commit code, and the system safely rolls it out.
- **Automated Rollback**: If the new version introduces errors (>1%) or latency (>500ms), Flagger halts the rollout and reverts traffic to the stable version immediately.
- **Increased Velocity**: Deployments can happen more frequently without fear of breaking the system.

## 3. Verification Plan (Experiment)

To verify that the extension improves the situation, we will design an **experiment to measure "Mean Time to Recovery" (MTTR) and "Success Rate of Bad Releases"**:

**Experiment Design:**
1.  **Baseline (Manual)**:
    - Deploy a "faulty" version of the app (configured to return 500 errors) using the current manual process.
    - Measure the time it takes for an operator to notice the error in Grafana and issue a `helm rollback`.
2.  **Treatment (Automated)**:
    - Deploy the same "faulty" version with Flagger enabled.
    - Flagger will start routing 5% traffic.
    - Flagger's analysis loop (running every 30s) will detect the drop in success rate.
    - **Expected Result**: Flagger halts the rollout and reverts traffic within ~1 minute, *without human intervention*.

**Success Criteria:**
- The automated system consistently rolls back faulty releases in < 2 minutes.
- No manual `values.yaml` editing is required for the release process.

## 4. Reflection: Assumptions & Downsides

- **Assumption**: We assume the existing Prometheus setup is reliable and scraping intervals are frequent enough (e.g., 15s) to detect issues quickly.
- **Downside (Complexity)**: Introducing Flagger adds another controller and CRDs to the cluster. This increases the learning curve for the team; developers must understand how `Canary` resources work.
- **Downside (Resource Usage)**: Flagger creates primary and canary deployments, potentially doubling the pod count during rollout (though the `sms-checker` is lightweight so this is acceptable).

## 5. References

1.  **Google Site Reliability Engineering**, "Chapter 5: Eliminating Toil" and "Chapter 8: Release Engineering". [Link](https://sre.google/sre-book/eliminating-toil/). _Discusses the negative impact of manual operational work and the necessity of automated, safe release processes._
2.  **Flagger Documentation**, "Istio Canary Deployments". [Link](https://docs.flagger.app/tutorials/istio-progressive-delivery). _Official documentation for implementing the proposed solution._
3.  **Stefan Prodan (Flagger Creator)**, "GitOps progressive deliveries with Flagger, Helm and Flux". [Link](https://medium.com/google-cloud/gitops-progressive-deliveries-with-flagger-helm-and-flux-78170c2a2100). _A technical blog detailing the architecture and benefits of automated progressive delivery._
