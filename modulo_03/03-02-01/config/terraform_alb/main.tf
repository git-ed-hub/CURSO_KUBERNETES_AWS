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
    "kubernetes.io/role/elb" = "1"  #etiqueta necesaria para elb
  }

  # Etiquetas para las subnets privadas
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1" #etiqueta necesaria para elb
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
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


# Política de IAM para el autoscaler
resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("policy.json")
}

# Obtener detalles del clúster EKS
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks] # Esperar a que se cree el clúster
}

# Obtener el OIDC Provider asociado con el clúster EKS
data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  depends_on = [module.eks] # Esperar a que se cree el clúster
}

# Crear el rol de tipo Web Identity
resource "aws_iam_role" "amazon_eks_load_balancer_controller_role" {
  name = "AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${data.aws_iam_openid_connect_provider.oidc.url}:aud" = "sts.amazonaws.com",
            "${data.aws_iam_openid_connect_provider.oidc.url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Adjuntar la política AWSLoadBalancerControllerIAMPolicy al rol creado
resource "aws_iam_role_policy_attachment" "attach_aws_load_balancer_controller_iam_policy" {
  role       = aws_iam_role.amazon_eks_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
}

# Output del ARN del rol
output "load_balancer_role_arn" {
  description = "ARN del rol AmazonEKSLoadBalancerControllerRole"
  value       = aws_iam_role.amazon_eks_load_balancer_controller_role.arn
}