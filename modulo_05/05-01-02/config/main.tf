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
  type    = string
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
    "kubernetes.io/role/elb" = "1"
  }

  # Etiquetas para las subnets privadas
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"       = "1"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "kubernetes.io/cluster/var.name_k8s"    = "owned"
    "k8s.io/cluster-autoscaler/var.name_k8s" = "owned"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Recurso para crear el Launch Template
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${var.name_k8s}-lt-"
  image_id      = "ami-03ba8d3b3ca03ad9c"
  instance_type = "t3.medium"
  #key_name      = "my-key-pair"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.vpc.default_security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size          = 20
      volume_type          = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<EOT
#!/bin/bash
echo "Node initialized!" > /var/log/user-data.log
EOT
  )

  tags = {
    Environment = "dev"
    Terraform   = "true"
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

  vpc_id                  = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.public_subnets
  subnet_ids              = module.vpc.private_subnets

  # Configuración de grupos de nodos gestionados
  eks_managed_node_groups = {
    managed_nodes = {
      capacity_type        = "SPOT"
      name                 = "managed-nodes"
      launch_template_id   = aws_launch_template.eks_nodes.id
      launch_template_version = "$Latest"
      min_size             = 1
      max_size             = 3
      desired_size         = 1
      labels = {
        role = "managed-nodes"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
