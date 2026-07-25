module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "21.0"
  name    = var.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets

  enable_irsa = true

  tags = {
    cluster = var.cluster_name
  }

  vpc_id = module.vpc.vpc_id

  eks_managed_node_groups = {
    node_group = {
      #   ami_type               = "AL2_x86_64" 
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      instance_types = ["t3.medium"]
      capacity_type = "ON_DEMAND"   
      min_size     = 2   
      max_size     = 3
      desired_size = 2
      vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
    }
  }
}