variable "vpc_name"{
    default = "eks-vpc"
} 

variable "vpc_cidr"{
    default     = "10.0.0.0/16"
    description = "Default CIDR range of the VPC"
}

variable "kubernetes_version"{
    default = "1.33"
}
variable "cluster_name"{
    default = "eks-cluster"
}

variable "aws_region"{
    default = "eu-west-1"
}

variable "instance_type"{
default = "t3.medium"
}