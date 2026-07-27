  ####################################################################################
  # IAM Role for EBS CSI Driver (Pod Identity)
  ####################################################################################

  resource "aws_iam_role" "ebs_csi_driver_role" {
    name = "${var.cluster_name}-ebs-csi-driver-role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "pods.eks.amazonaws.com"
          }
          Action = [
            "sts:AssumeRole",
            "sts:TagSession"
          ]
        }
      ]
    })

    tags = {
      Name        = "${var.cluster_name}-ebs-csi-driver-role"
      Environment = var.environment
      Terraform   = "true"
    }
  }

  ####################################################################################
  # Attach EBS CSI Driver Policy
  ####################################################################################

  resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
    role       = aws_iam_role.ebs_csi_driver_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
  ####################################################################################
  # Pod Identity Association for EBS CSI Driver
  ####################################################################################

  resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
    cluster_name    = var.cluster_name
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi_driver_role.arn

    tags = {
      Name        = "${var.cluster_name}-ebs-csi-pod-identity"
      Environment = var.environment
      Terraform   = "true"
    }
  }

  ####################################################################################
  ###  EBS CSI Driver Addon 
  ####################################################################################

  resource "aws_eks_addon" "ebs_csi_driver" {
    cluster_name = module.eks.cluster_name
    addon_name   = "aws-ebs-csi-driver"
    depends_on = [
      module.eks,
      aws_iam_role_policy_attachment.ebs_csi_driver,
      aws_eks_pod_identity_association.ebs_csi_driver
  ] 

    tags = {
      Name        = "${var.cluster_name}-ebs-csi-driver"
      Environment = var.environment
      Terraform   = "true"
    }
  }



  # Fetch the official AWS Load Balancer Controller IAM policy document
  data "http" "lbc_iam_policy" {
    url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
  }

  resource "aws_iam_policy" "lbc" {
    name        = "AWSLoadBalancerControllerIAMPolicy"
    path        = "/"
    description = "IAM policy for AWS Load Balancer Controller on EKS"
    policy      = data.http.lbc_iam_policy.response_body
  }

  # Trust policy for EKS Pod Identity
  data "aws_iam_policy_document" "lbc_trust" {
    statement {
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["pods.eks.amazonaws.com"]
      }

      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  }

  resource "aws_iam_role" "lbc" {
    name               = "${var.cluster_name}-aws-lbc-pod-identity"
    assume_role_policy = data.aws_iam_policy_document.lbc_trust.json
  }

  resource "aws_iam_role_policy_attachment" "lbc" {
    policy_arn = aws_iam_policy.lbc.arn
    role       = aws_iam_role.lbc.name
  }


  resource "aws_eks_pod_identity_association" "lbc" {
    cluster_name    = var.cluster_name
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
    role_arn        = aws_iam_role.lbc.arn
  }


  resource "helm_release" "aws_lbc" {
    name       = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    namespace  = "kube-system"
    version    = "1.14.0" # Use the target chart version aligned with your environment

    set {
      name  = "clusterName"
      value = var.cluster_name
    }

    set {
      name  = "serviceAccount.create"
      value = "true"
    }

    set {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }

    set {
      name  = "region"
      value = var.aws_region
    }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
    }
    
    # Ensure Pod Identity mapping infrastructure is live before installing helm chart
    depends_on = [aws_eks_pod_identity_association.lbc]
  }
