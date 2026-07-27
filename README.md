# Production-Grade Amazon EKS Platform on AWS using Terraform

![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-v3-0F1689?logo=helm)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Dashboard-Grafana-F46800?logo=grafana)

---

# Overview

This project provisions a **fully automated, production-grade Amazon Elastic Kubernetes Service (EKS) platform** using **Terraform**.

The infrastructure follows AWS best practices and is designed around modern cloud-native principles:

* Infrastructure as Code (Terraform)
* Private worker nodes
* Multi-AZ deployment
* Managed Kubernetes control plane
* Amazon EKS Pod Identity
* AWS Load Balancer Controller
* Amazon EBS CSI Driver
* Production monitoring stack
* Persistent Prometheus & Grafana storage
* Secure networking
* Highly extensible architecture

The entire platform can be recreated using a single Terraform deployment, making it reproducible, version-controlled, and suitable for production workloads.

---

# Architecture Overview

The platform consists of the following layers:

```
                        Internet
                            │
                            ▼
                AWS Application Load Balancer
                            │
                    AWS Load Balancer Controller
                            │
───────────────────────────────────────────────────────
                    Amazon EKS Cluster
───────────────────────────────────────────────────────
             Worker Nodes (Private Subnets)
                            │
        ┌──────────────────────────────────────┐
        │              Kubernetes              │
        │                                      │
        │ Applications                         │
        │ Services                             │
        │ Ingress                              │
        │ Deployments                          │
        │ StatefulSets                         │
        │ DaemonSets                           │
        └──────────────────────────────────────┘
                            │
             Amazon EBS CSI Driver
                            │
                     Amazon EBS Volumes
```

---

# Technology Stack

| Component          | Technology                   |
| ------------------ | ---------------------------- |
| Infrastructure     | Terraform                    |
| Cloud              | AWS                          |
| Kubernetes         | Amazon EKS                   |
| Networking         | Amazon VPC                   |
| Load Balancing     | AWS Load Balancer Controller |
| Persistent Storage | Amazon EBS CSI Driver        |
| Authentication     | Amazon EKS Pod Identity      |
| Monitoring         | Prometheus                   |
| Visualization      | Grafana                      |
| Alerting           | Alertmanager                 |
| Metrics            | Metrics Server               |
| Kubernetes Metrics | kube-state-metrics           |
| Node Metrics       | Node Exporter                |
| Package Manager    | Helm                         |

---

# Infrastructure Components

The Terraform configuration provisions:

* Amazon VPC
* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables
* Security Groups
* Amazon EKS Cluster
* Managed Node Group
* IAM Roles
* EKS Pod Identity
* EBS CSI Driver
* AWS Load Balancer Controller
* Metrics Server
* kube-prometheus-stack
* Persistent Storage Classes
* Monitoring Namespace

Each component is provisioned automatically and managed through Terraform state.

---

# Networking Architecture

The cluster is deployed inside a custom Amazon VPC.

## Public Subnets

Public subnets contain infrastructure that must be reachable from the internet.

Examples include:

* Internet Gateway
* Public Load Balancers
* Bastion Host

These subnets have a default route pointing to the Internet Gateway.

---

## Private Subnets

All Kubernetes worker nodes are deployed into private subnets.

Benefits:

* No public IP addresses
* Reduced attack surface
* Secure outbound internet through NAT Gateway
* Isolation from external traffic

Pods communicate externally through the NAT Gateway when downloading container images or contacting AWS APIs.

---

## Availability Zones

The infrastructure spans multiple Availability Zones to improve resiliency.

Benefits include:

* High Availability
* Fault Isolation
* Better Scheduling
* Reduced downtime during AZ failures

---

# Amazon EKS Cluster

Amazon EKS provides the managed Kubernetes control plane.

AWS manages:

* API Server
* etcd
* Scheduler
* Controller Manager
* Control Plane High Availability
* Automatic replacement of failed control plane nodes

This significantly reduces operational overhead compared to self-managed Kubernetes.

The worker nodes remain under customer control.

---

# Managed Node Group

The cluster uses Amazon EKS Managed Node Groups.

Advantages include:

* Automated provisioning
* Rolling updates
* Health monitoring
* Integration with Auto Scaling Groups
* Simplified lifecycle management

Worker nodes use the Amazon Linux 2023 optimized AMI.

---

# Cluster Add-ons

The platform installs AWS-managed Kubernetes add-ons.

## CoreDNS

Provides internal DNS resolution.

Responsible for converting Kubernetes Service names into ClusterIP addresses.

Example:

```
grafana.monitoring.svc.cluster.local
```

---

## kube-proxy

Implements Kubernetes Service networking using iptables or IPVS.

Responsible for:

* ClusterIP Services
* NodePort Services
* Load balancing
* Service discovery

---

## Amazon VPC CNI

The VPC CNI plugin provides pod networking.

Unlike many Kubernetes distributions, EKS assigns each pod a real VPC IP address.

Benefits:

* Native VPC networking
* No overlay network
* Better performance
* Native security groups
* Lower latency

---

## EKS Pod Identity Agent

Provides secure IAM authentication for Kubernetes workloads without distributing long-lived AWS credentials.

Pods receive temporary AWS credentials through Pod Identity Associations.

---

# Storage

Persistent storage is provided through the Amazon EBS CSI Driver.

A default GP3 StorageClass is created with:

* WaitForFirstConsumer
* Volume Expansion
* Encryption Enabled
* Delete reclaim policy

Applications requesting PersistentVolumeClaims automatically receive encrypted GP3 volumes.

---

# Security

The platform follows security best practices.

Highlights include:

* Private worker nodes
* IAM Roles
* EKS Pod Identity
* Security Groups
* No static AWS credentials
* Encrypted storage
* Least-privilege IAM policies
* Kubernetes RBAC
* Managed control plane

---

# Monitoring Stack

The platform deploys a complete observability stack using the **kube-prometheus-stack Helm chart**.

It includes:

* Prometheus
* Grafana
* Alertmanager
* Prometheus Operator
* Node Exporter
* kube-state-metrics

This stack provides metrics collection, visualization, alerting, and Kubernetes object monitoring.

The next section explains each component in detail.
# Monitoring and Observability

Monitoring is one of the most critical aspects of operating Kubernetes in production. A cluster may be running successfully, but without visibility into its health, performance, and resource consumption, identifying issues becomes difficult.

This platform deploys a complete monitoring stack using the **kube-prometheus-stack** Helm chart, which installs and configures industry-standard monitoring components.

The stack consists of:

* Metrics Server
* Prometheus
* Prometheus Operator
* Grafana
* Alertmanager
* Node Exporter
* kube-state-metrics

Together, these components provide cluster-wide observability, metrics collection, dashboards, and alerting.

---

# Monitoring Architecture

```
                              Applications
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
   Node Exporter             kube-state-metrics          Application Metrics
        │                           │                           │
        └───────────────┬───────────┴───────────────┬───────────┘
                        ▼
                  Prometheus Server
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
     Alertmanager                Grafana
          │                           │
          ▼                           ▼
   Email / Slack / PagerDuty     Dashboards
```

---

# Metrics Server

## Purpose

Metrics Server is a lightweight cluster-wide metrics aggregator.

Its primary responsibility is collecting **current CPU and Memory usage** from every Kubernetes node and pod.

Unlike Prometheus, Metrics Server is **not designed for long-term monitoring**.

Instead, it powers Kubernetes' built-in autoscaling features.

Examples:

* Horizontal Pod Autoscaler (HPA)
* Vertical Pod Autoscaler (VPA)
* `kubectl top nodes`
* `kubectl top pods`

---

## How Metrics Server Works

Every worker node runs a **kubelet**.

Embedded inside kubelet is **cAdvisor (Container Advisor)**.

cAdvisor continuously reads Linux cgroups and gathers resource usage for every running container.

Examples include:

* CPU usage
* Memory usage

Metrics Server scrapes kubelet every **15 seconds**.

The flow looks like:

```
Container Runtime
        │
        ▼
    cAdvisor
        │
        ▼
     Kubelet
        │
        ▼
 Metrics Server
        │
        ▼
 Kubernetes API
        │
 ┌──────┴────────┐
 ▼               ▼
HPA        kubectl top
```

---

## What Metrics Server Collects

Metrics Server only collects:

* CPU
* Memory

It intentionally does **not** collect:

* Network traffic
* Disk I/O
* Filesystem metrics
* Historical metrics
* Custom application metrics
* Kubernetes object state

---

## Why It Doesn't Store Data

Metrics Server stores everything in memory.

It has:

* No database
* No persistent storage
* No historical queries

If the pod restarts, previously collected metrics are lost. New metrics are gathered during the next scrape cycle.

This lightweight design allows it to scale efficiently to thousands of Kubernetes nodes.

---

# Prometheus

## Purpose

Prometheus is the core monitoring engine of the platform.

It continuously scrapes metrics from the cluster, stores them as time-series data, and provides a powerful query language (PromQL).

Unlike Metrics Server, Prometheus maintains historical data, enabling trend analysis, capacity planning, and alerting.

---

## Metrics Sources

Prometheus scrapes metrics from many components, including:

* kubelet
* Node Exporter
* kube-state-metrics
* CoreDNS
* kube-proxy
* VPC CNI
* Metrics Server
* AWS Load Balancer Controller
* Application endpoints
* Custom exporters

Every target exposes an HTTP endpoint (commonly `/metrics`) that Prometheus polls at regular intervals.

---

# Pull-Based Monitoring

Prometheus uses a pull model.

Instead of applications pushing metrics to Prometheus, Prometheus periodically requests metrics from each target.

Advantages include:

* Centralized discovery
* Health detection
* Easier debugging
* Better scalability
* Automatic target removal when workloads disappear

---

# Time-Series Database (TSDB)

Prometheus stores every metric in its embedded Time-Series Database.

Each metric consists of:

* Metric name
* Labels
* Timestamp
* Value

Example:

```
container_cpu_usage_seconds_total{
    pod="api-6dd54d",
    namespace="production"
}
```

Over time, these samples build a historical record that can be queried for trends and analysis.

---

# Data Retention

This platform configures Prometheus with:

* 15-day retention period
* 50 GiB persistent volume
* GP3 StorageClass

This ensures metrics survive pod restarts and node replacements while preventing uncontrolled disk growth.

---

# Prometheus Operator

Managing Prometheus through static configuration files becomes difficult as clusters grow.

The Prometheus Operator introduces Kubernetes-native resources that simplify configuration.

Instead of editing large YAML files, administrators create custom resources such as:

* ServiceMonitor
* PodMonitor
* PrometheusRule

The operator watches these resources and automatically generates the required Prometheus configuration.

This approach makes monitoring declarative, version-controlled, and easier to maintain.

---

# ServiceMonitor

A ServiceMonitor instructs Prometheus to scrape metrics from a Kubernetes Service.

Example use cases include:

* kube-state-metrics
* CoreDNS
* Metrics Server
* Application Services

When a ServiceMonitor is created, the Prometheus Operator automatically updates Prometheus with the appropriate scrape configuration.

---

# PodMonitor

Some workloads expose metrics directly from pods without a Service.

A PodMonitor allows Prometheus to discover and scrape those pods.

This is commonly used for:

* DaemonSets
* Sidecars
* Jobs
* Batch workloads

---

# PrometheusRule

PrometheusRule resources define alerting and recording rules.

Examples:

* Node CPU exceeds 90%
* Pod restart count is increasing
* Persistent Volume usage exceeds 80%
* Kubernetes API latency is high

The operator loads these rules into Prometheus automatically.

---

# Node Exporter

Node Exporter is deployed as a DaemonSet.

A DaemonSet ensures one Node Exporter pod runs on every Kubernetes worker node.

Node Exporter exposes operating system metrics, including:

* CPU utilization
* Memory usage
* Filesystem capacity
* Disk I/O
* Network traffic
* Load averages
* Kernel statistics
* File descriptor usage

Without Node Exporter, Prometheus would have little visibility into the underlying EC2 instances.

---

# kube-state-metrics

kube-state-metrics does not collect resource usage.

Instead, it exposes the current state of Kubernetes objects by reading the Kubernetes API.

Examples include:

* Deployments
* ReplicaSets
* StatefulSets
* DaemonSets
* Pods
* Nodes
* PersistentVolumeClaims
* Services
* Jobs
* CronJobs

This enables dashboards and alerts based on cluster state rather than system resource usage.

---

# Grafana

Grafana is the visualization layer of the monitoring stack.

It does **not** collect metrics itself.

Instead, Grafana queries Prometheus whenever a dashboard is opened or refreshed.

For example, a panel displaying CPU usage executes a PromQL query against Prometheus, receives the results, and renders them as graphs or gauges.

Grafana provides:

* Interactive dashboards
* Variables
* Drill-down capabilities
* Role-based access
* Dashboard provisioning
* Alert visualization

Persistent storage is enabled using a 10 GiB encrypted GP3 volume, ensuring dashboards and configuration survive pod restarts.

---

# Alertmanager

Alertmanager receives alerts generated by Prometheus.

Its responsibilities include:

* Grouping similar alerts
* Suppressing duplicate notifications
* Applying silences during maintenance
* Routing alerts to different destinations

Common integrations include:

* Email
* Slack
* Microsoft Teams
* PagerDuty
* Opsgenie
* Webhooks

Alertmanager separates alert generation (Prometheus) from alert delivery, making notification management more flexible.

---

# End-to-End Metrics Flow

The following illustrates how metrics move through the monitoring system:

```
Linux Kernel / cgroups
          │
          ▼
      cAdvisor
          │
          ▼
       Kubelet
          │
          ▼
  Metrics Server ───────────────┐
                                │
Node Exporter                   │
kube-state-metrics              │
Application Metrics             │
CoreDNS                         │
kube-proxy                      │
VPC CNI                         │
                                ▼
                         Prometheus
                                │
             ┌──────────────────┴──────────────────┐
             ▼                                     ▼
       Alertmanager                          Grafana
             │                                     │
             ▼                                     ▼
     Notifications                        Dashboards
```

---

# Why Both Metrics Server and Prometheus?

Although both expose metrics, they solve different problems.

| Feature            | Metrics Server | Prometheus        |
| ------------------ | -------------- | ----------------- |
| CPU & Memory       | Yes            | Yes               |
| Historical Data    | No             | Yes               |
| Alerting           | No             | Yes               |
| Dashboards         | No             | Yes (via Grafana) |
| Autoscaling        | Yes            | No                |
| Network Metrics    | No             | Yes               |
| Disk Metrics       | No             | Yes               |
| Custom Metrics     | No             | Yes               |
| Persistent Storage | No             | Yes               |

In a production cluster, Metrics Server and Prometheus complement each other rather than replace one another. Metrics Server powers Kubernetes autoscaling and `kubectl top`, while Prometheus provides comprehensive monitoring, long-term storage, alerting, and visualization.
