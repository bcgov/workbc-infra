#EKS cluster
resource "aws_eks_cluster" "workbc-cluster2" {
  name = "workbc-cluster2"
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  role_arn = aws_iam_role.eks-cluster-role.arn
  vpc_config {
    subnet_ids = data.aws_subnets.app.ids
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-policy,
    aws_iam_role.eks-cluster-role,
  ]
}

#EKS cluster addons
resource "aws_eks_addon" "vpc-cni-addon2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube-proxy-addon2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "pod-identity-addon2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "coredns-addon2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "coredns"
}



resource "aws_eks_addon" "aws-efs-csi-driver2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "aws-efs-csi-driver"

  pod_identity_association {
    role_arn = aws_iam_role.efs-csi-role.arn
    service_account = "efs-csi-controller-sa"
  }
}

resource "aws_eks_addon" "secrets-manager-addon2" {
  cluster_name = aws_eks_cluster.workbc-cluster2.name
  addon_name   = "aws-secrets-store-csi-driver-provider"
}

#Node group
resource "aws_eks_node_group" "eks-ng2" {
  cluster_name    = aws_eks_cluster.workbc-cluster2.name
  node_group_name = "eks-ng2"
  node_role_arn   = aws_iam_role.eks-ng-role.arn
  subnet_ids      = data.aws_subnets.app.ids

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }

  instance_types = ["t3.large"]

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ng-AmazonEC2ContainerRegistryReadOnly,
  ]
}


data "aws_security_group" "eks_node_sg2" {
  id = aws_eks_cluster.workbc-cluster2.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "allow_alb2" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.eks_node_sg2.id
  source_security_group_id = aws_security_group.alb_sg.id
}
