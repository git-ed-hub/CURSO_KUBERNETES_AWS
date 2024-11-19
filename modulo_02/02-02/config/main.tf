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
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "kubernetes.io/cluster/my-eks" = "owned"
    "k8s.io/cluster-autoscaler/my-eks" = "owned"
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
      desired_size = 1

      instance_types = ["t2.medium", "t3.medium"]
    }
  }

  # Habilitamos permisos administrador
  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}