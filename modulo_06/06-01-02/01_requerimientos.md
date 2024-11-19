# REQUERIMIENTOS:

1. Permisos IAM en los nodos de trabajo.

- Desplegar Cluster EKS.
- Adjunta la política de CloudWatch Agent al nodo de EKS
- Instalacion complemento CloudWatch.
~~~json
resource "aws_eks_addon" "my-eks_cloudwatch" {
  addon_name   = "my_eks-amazon-cloudwatch-observability"
  cluster_name = var.name_k8s
}
~~~

Con el despliegue de terraform ya quedaria instalado amazon CloudWatch.
