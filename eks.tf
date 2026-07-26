module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"

  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }
    #Why before_compute = true? Ensures the VPC CNI plugin is installed and ready before worker nodes register with the control plane. Without this, worker nodes spin up but fail to reach a Ready state because no networking driver is available to assign IPs to pods.
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = [var.instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size = 2
      max_size = 3
      desired_size = 2
    }
  }

  tags = {
    cluster = var.cluster_name
  }
}