#Cluster role
resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

#Cluster role policy
resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}


#EFS CSI role
resource "aws_iam_role" "efs-csi-role" {
  name = "efs-csi-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#EFS CSI policy
resource "aws_iam_role_policy_attachment" "ec-AmazonEFSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs-csi-role.name
}


#Node group role
resource "aws_iam_role" "eks-ng-role" {
  name = "eks-ng-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#Node group policies
resource "aws_iam_role_policy_attachment" "ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-ng-role.name
}

resource "aws_iam_role_policy_attachment" "ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-ng-role.name
}

resource "aws_iam_role_policy_attachment" "ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-ng-role.name
}


#Cluster auto scaler role
resource "aws_iam_role" "cluster_auto_scaler_role" {
  name = "cluster_auto_scaler_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#Cluster auto scaler policy
resource "aws_iam_role_policy" "cluster_auto_scaler" {
  name   = "cluster_auto_scaler"
  role   = aws_iam_role.cluster_auto_scaler_role.id
  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "autoscaling:DescribeAutoScalingGroups",
                  "autoscaling:DescribeAutoScalingInstances",
                  "autoscaling:DescribeLaunchConfigurations",
                  "autoscaling:DescribeTags",
                  "autoscaling:SetDesiredCapacity",
                  "autoscaling:TerminateInstanceInAutoScalingGroup",
                  "ec2:DescribeLaunchTemplateVersions",
                  "ec2:DescribeInstances"
              ],
              "Resource": "*"
          }
      ]
  }
  EOF
}

#SES Mailer role
resource "aws_iam_role" "ses_mailer_role" {
  name = "ses_mailer_role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#SES Mailer policy
resource "aws_iam_role_policy" "ses_mailer_policy" {
  name   = "ses_mailer_policy"
  role   = aws_iam_role.ses_mailer_role.id
  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                "ses:SendEmail",
		  		"ses:SendRawEmail",
		  		"ses:ListIdentities"
              ],
              "Resource": "*"
          },
		  {
			  "Effect": "Allow",
			  "Action": [
				  "secretsmanager:GetSecretValue",
				  "secretsmanager:DescribeSecret"
			  ],
			  "Resource": "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*"
		  },
		  {
			  "Effect": "Allow",
			  "Action": [
				  "kms:Decrypt"
			  ],
			  "Resource": "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
		  }
      ]
  }
  EOF
}

