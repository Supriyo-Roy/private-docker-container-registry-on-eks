resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  depends_on = [ module.eks ]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prom-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.4.0"                 # pin version!
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.module}/values-prod.yaml")   # same file as above
  ]
depends_on = [
    kubernetes_namespace.monitoring
    # + ebs csi driver / storage class if managed by TF
  ]

  # Useful production settings
  timeout         = 600
  cleanup_on_fail = true
  wait            = true
  atomic          = true                  # rollback on failure
}

# Make sure the EBS CSI driver is already installed
# (either via eksctl, AWS provider, or EKS Blueprints)

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    fsType    = "ext4"
    encrypted = "true"
  }

  # Optional: force destroy even if volumes exist
  # force_destroy = true
}