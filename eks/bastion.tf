
resource "aws_security_group" "bastion" {
  name_prefix = "${var.cluster_name}-bastion-"
  description = "Security group for EKS bastion (Session Manager only)"
  vpc_id      = module.vpc.vpc_id

  # Only outbound traffic is required
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-bastion-sg"
  }
}

# Allow bastion → worker nodes
resource "aws_security_group_rule" "bastion_to_workers" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.all_worker_mgmt.id
  source_security_group_id = aws_security_group.bastion.id
  description              = "Allow traffic from bastion to workers"
}

# -------------------------------------------------
# IAM Role for Bastion (Session Manager + EKS)
# -------------------------------------------------
resource "aws_iam_role" "bastion" {
  name = "${var.cluster_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Required policy for Session Manager
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Policy so bastion can talk to EKS
resource "aws_iam_role_policy" "bastion_eks" {
  name = "${var.cluster_name}-bastion-eks-policy"
  role = aws_iam_role.bastion.id

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

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.cluster_name}-bastion-profile"
  role = aws_iam_role.bastion.name
}

# -------------------------------------------------
# Bastion EC2 Instance
# -------------------------------------------------
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]   # Can even be private subnet!
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # No public IP needed when using Session Manager
  associate_public_ip_address = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              dnf update -y

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              dnf install -y jq git
              EOF

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

# Output the instance ID (you need this to connect)
output "bastion_instance_id" {
  value = aws_instance.bastion.id
}