#AMI filter
data "aws_ami" "eks_worker_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.33-v*"] # match your EKS version
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#Launch template
resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix   = "eks-nodes-"
  image_id      = data.aws_ami.eks_worker_ami.id
  instance_type = "t3.medium"

  network_interfaces {
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }
}

#Node SG
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

