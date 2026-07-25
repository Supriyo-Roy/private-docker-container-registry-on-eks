variable "vpc_name"{
    default = "eks-vpc"
} 

variable "vpc_cidr"{
    default     = "10.0.0.0/16"
    description = "Default CIDR range of the VPC"
}

# variable "vpc_module_version"{
#     default = 6.6.1
#     description = "Default Terraform VPC module version"
# }

variable "kubernetes_version"{
    default = "1.33"
}
variable "cluster_name"{
    default = "eks-cluster"
}