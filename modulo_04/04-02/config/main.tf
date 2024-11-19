terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "user-terraform"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "my-eks-vpc"
  cidr = "10.10.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  # Etiquetas para las subnets públicas
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # Etiquetas para las subnets privadas
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-eks"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.public_subnets
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    spot_group = {
      capacity_type = "SPOT"
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium", "t2.medium"]
    }
  }

  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_ebs_volume" "my_ebs_volume" {
  availability_zone = "us-east-1a"  # Asegúrate de poner la zona correcta
  size              = 10
  type              = "gp3"
}

resource "aws_eks_addon" "csi_driver" {
  addon_name    = "aws-ebs-csi-driver"
  cluster_name  = module.eks.cluster_name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Definición de la política de permisos
resource "aws_iam_policy" "eks_ebs_policy" {
  name        = "eks-ebs-permissions"
  description = "Permisos para gestionar volúmenes EBS en EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:AttachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeInstances",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Adjuntar la política al rol de IAM del grupo de nodos de EKS
resource "aws_iam_role_policy_attachment" "eks_ebs_policy_attachment" {
  role       = module.eks.eks_managed_node_groups["spot_group"].iam_role_name
  policy_arn = aws_iam_policy.eks_ebs_policy.arn
}