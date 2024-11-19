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

variable "name_k8s" {
  type = string
  default = "my-eks"
}
variable "region" {
  type = string
  default = "us-east-1"
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

  public_subnet_tags = {
    # Etiqueta para utilizar balanceador-alb
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    # Etiqueta para utilizar balanceador-alb
    "kubernetes.io/role/internal-elb" = "1"
    # Etiqueta para utilizar autoscaler
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "kubernetes.io/cluster/var.name_k8s" = "owned"
    "k8s.io/cluster-autoscaler/var.name_k8s" = "owned"

  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name_k8s
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

  # Configuración de grupos de nodos gestionados
  eks_managed_node_groups = {
    managed_nodes = {
      capacity_type = "SPOT"
      name          = "managed-nodes"
      instance_type = ["t2.medium", "t3.medium"]
      min_size      = 1
      max_size      = 3
      desired_size  = 1
      labels = {
        role = "managed-nodes"
      }
      volume_size = 20
    }
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Adjuntar la política de CloudWatch al rol IAM de los nodos gestionados
resource "aws_iam_role_policy_attachment" "managed_nodes_cloudwatch_policy" {
  role       = module.eks.eks_managed_node_groups["managed_nodes"].iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Obtener el OIDC Provider asociado con el clúster EKS
data "aws_eks_cluster" "cluster" {
  name = var.name_k8s
  depends_on = [module.eks] # Esperar a que se cree el clúster
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  depends_on = [module.eks] # Esperar a que se cree el clúster
}

# Crear el rol de IAM para el addon de CloudWatch con el proveedor OIDC
resource "aws_iam_role" "cloudwatch_addon_role" {
  name = "eks-cloudwatch-addon-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          "StringEquals" = {
            "${data.aws_iam_openid_connect_provider.oidc.url}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          }
        }
      }
    ]
  })
}

# Adjuntar los permisos de rol para CloudWatch  IAM
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_attachment" {
  role       = aws_iam_role.cloudwatch_addon_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Crear el addon de CloudWatch en el clúster EKS con el rol de IAM
resource "aws_eks_addon" "my_eks_cloudwatch" {
  addon_name             = "amazon-cloudwatch-observability"
  cluster_name           = var.name_k8s
  service_account_role_arn = aws_iam_role.cloudwatch_addon_role.arn
}
