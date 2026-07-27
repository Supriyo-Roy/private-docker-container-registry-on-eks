# private-docker-container-registry-on-eks
Deploy a private Docker container registry on Kubernetes (EKS) using Terraform

# kubernetes metrics server 

The Kubernetes Metrics Server is a lightweight, cluster-wide aggregator of container resource usage. It acts as the core engine behind Kubernetes' built-in autoscaling pipelines (like HPA and VPA) and commands like kubectl top.

Metrics Server operates via a pull-based model, collecting data from worker nodes and exposing it back to the Kubernetes API.

[ Container Runtimes / cAdvisor ]
               │
               ▼
       [ Node: Kubelet ]  ──(exposes /metrics/resource)
               │
               ▼ (Scraped every 15s over HTTPS)
    [ Metrics Server Pod ]
               │
               ▼ (Registered via API Aggregation)
     [ kube-apiserver ]  ──(exposes metrics.k8s.io)
               │
   ┌───────────┼───────────┐
   ▼           ▼           ▼
[ HPA ]     [ VPA ]   [ kubectl top ]

On every worker node, cAdvisor (Container Advisor) runs embedded inside the kubelet process.

1. Metric Collection at the Node Level (cAdvisor)
cAdvisor interfaces with the container runtime (cgroups on Linux) to collect raw CPU usage (cumulative core usage) and Memory usage (working set bytes).
The kubelet exposes these resource stats locally via its HTTPS endpoint (typically /metrics/resource or /stats/summary).

Key Technical Characteristics

In-Memory Only: It does not write data to disk or a database. If the Metrics Server restarts, all recent metrics are lost until the next scrape cycle.

Limited Scope: It strictly collects CPU and Memory usage. It does not collect network traffic, disk I/O, custom application metrics, or historical trends.

Resource Efficient: Built to scale efficiently up to 5,000-node clusters, requiring approximately 1 millicore of CPU and 2 MB of memory per node.

Its only job is to collect current CPU and Memory usage from every node and pod.

It does not:

❌ Store historical data
❌ Create dashboards
❌ Generate alerts
❌ Collect logs

Instead, it powers:

kubectl top nodes
kubectl top pods
Horizontal Pod Autoscaler (HPA)
Vertical Pod Autoscaler (VPA)
