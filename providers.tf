terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

# provider "helm" {
#   kubernetes {
#     host = module.eks.cluster_endpoint

#     cluster_ca_certificate = base64decode(
#       module.eks.cluster_certificate_authority_data
#     )

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"

#       command = "aws"

#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.eks.cluster_name
#       ]
#     }
#   }
# }
