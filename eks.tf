module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"
  endpoint_public_access  = true
  # The IAM role that Terraform Cloud assumes (OIDC / dynamic credentials / workspace credentials) is not automatically given access to the cluster.
  enable_cluster_creator_admin_permissions = true

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
    # aws-efs-csi-driver = {
    #   before_compute = true
    # }
  }
    #Why before_compute = true? Ensures the VPC CNI plugin is installed and ready before worker nodes register with the control plane. Without this, worker nodes spin up but fail to reach a Ready state because no networking driver is available to assign IPs to pods.
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  security_group_additional_rules = {
    ingress_bastion_allow = {
      description               = "Allow Bastion host to reach EKS API"
      protocol                  = "tcp"
      from_port                 = 443
      to_port                   = 443
      type                      = "ingress"
      source_security_group_id  = aws_security_group.bastion_sg.id
    }
    }

    access_entries = {
    bastion = {
      principal_arn = aws_iam_role.bastion_ssm.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }}}

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

# Creating access entry for bastion 

# resource "aws_eks_access_entry" "bastion" {
#   cluster_name  = module.eks.cluster_name
#   principal_arn = aws_iam_role.bastion_ssm.arn
#   type          = "STANDARD"
# }

# resource "aws_eks_access_policy_association" "bastion_admin" {
#   cluster_name  = module.eks.cluster_name
#   principal_arn = aws_iam_role.bastion_ssm.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#   access_scope {
#     type = "cluster"
#   }
# }

# resource "aws_iam_role" "efs_csi" {
#   name = "AmazonEKS_EFS_CSI_DriverRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "pods.eks.amazonaws.com"
#       }
#       Action = [
#         "sts:AssumeRole",
#         "sts:TagSession"
#       ]
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "efs_csi" {
#   role       = aws_iam_role.efs_csi.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
# }

