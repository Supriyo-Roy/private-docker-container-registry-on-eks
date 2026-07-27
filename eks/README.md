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


kube-prometheus-stack is the standard way to run full Kubernetes monitoring on an EKS cluster. It is a single Helm chart (from the prometheus-community) that installs a complete, production-ready monitoring stack using the Prometheus Operator pattern.

                    kube-prometheus-stack
┌────────────────────────────────────────────────────┐
│                                                    │
│  Prometheus          ← Metrics Database            │
│  Grafana             ← Dashboards                  │
│  Alertmanager        ← Alerts                      │
│  Node Exporter       ← Node Metrics                │
│  kube-state-metrics  ← Kubernetes Object Metrics   │
│  Prometheus Operator ← Manages Prometheus          │
│                                                    │
└────────────────────────────────────────────────────┘

1. Prometheus

This is the heart of monitoring.

It continuously scrapes metrics from:

kubelet
Metrics Server
kube-state-metrics
Node Exporter
CoreDNS
kube-proxy
VPC CNI
your applications

Grafana does not collect metrics.

It simply asks Prometheus:

rate(container_cpu_usage_seconds_total[5m])

and draws beautiful dashboards.

3. Node Exporter

Node Exporter runs on every node.

It exposes Linux metrics:

CPU
Memory
Filesystem
Network
Disk
Load Average
Kernel statistics

Without Node Exporter, Prometheus knows almost nothing about your EC2 instances.

5. Alertmanager

Prometheus detects problems.

Alertmanager decides:

Send Slack message
Send Email
Send PagerDuty
Send Teams
Group alerts
Silence alerts

6. Prometheus Operator

This manages Prometheus itself.

Instead of editing huge configuration files, you create Kubernetes resources like:

ServiceMonitor

PodMonitor

PrometheusRule

The operator converts them into Prometheus configuration automatically.

kubectl port-forward -n monitoring svc/kube-prom-stack-grafana 3000:80

aws ssm start-session \
    --target <INSTANCE_ID> \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3000"],"localPortNumber":["3000"]}'
    
