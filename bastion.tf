################################################################################
# IAM Role for SSM Session Manager
################################################################################

resource "aws_iam_role" "bastion_ssm" {
  name = "${var.vpc_name}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy allowing the Bastion host to query EKS cluster metadata
resource "aws_iam_role_policy" "bastion_eks_describe" {
  name = "bastion-eks-describe-policy"
  role = aws_iam_role.bastion_ssm.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the managed SSM policy required for Session Manager agent
resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the instance profile to attach to the EC2 instance
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.vpc_name}-bastion-instance-profile"
  role = aws_iam_role.bastion_ssm.name
}

################################################################################
# Security Group for Bastion Host
################################################################################

resource "aws_security_group" "bastion_sg" {
  name        = "${var.vpc_name}-bastion-sg"
  description = "Security group for SSM Bastion host"
  vpc_id      = module.vpc.vpc_id

  # ZERO Inbound rules required! SSM uses outbound long-polling.

  # Outbound rule to allow downloading updates, reaching SSM endpoints, and kubectl operations
  egress {
    description = "Allow outbound Internet access via NAT Gateway"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-bastion-sg"
  }
}

################################################################################
# EC2 Bastion Instance (Amazon Linux 2023)
################################################################################

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = "${var.vpc_name}-bastion"

  # Standard cheap, burstable instance type
  instance_type = "t3.micro"

  # Amazon Linux 2023 comes pre-installed with the SSM Agent
  ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"

  # Place in private subnet (relying on NAT Gateway for outbound connectivity to SSM endpoints)
  subnet_id = module.vpc.private_subnets[0]

  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  associate_public_ip_address = false

  # Pre-install kubectl and aws-cli on boot (optional but helpful for managing EKS)
  user_data = <<-EOF
              #!/bin/bash
              sudo dnf update -y
              # Install kubectl for EKS management
              curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.0/2024-09-12/bin/linux/amd64/kubectl
              chmod +x ./kubectl
              mv ./kubectl /usr/local/bin/
              EOF

  tags = {
    Environment = "production"
    Role        = "bastion"
  }
}