# Asignar estsos permisos (Se implemento con terraform)

Ingresar al cluster

    aws eks update-kubeconfig --name my-eks --region us-east-1

Ingresamos el siguiente comando para saber el ID-connect
aws iam list-open-id-connect-providers
~~~json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::124355643940:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/863A480174C5074CD7194C3B84BC01EE"
        }
    ]
}
~~~
Nos dirijimos a la siguiente direccion para crear la policy.

    IAM | Policies | Create policy
create policy terraform

~~~json     AmazonEKSClusterAutoscalerPolicy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeScalingActivities",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": ["*"]
        }
    ]
}
~~~
Nos dirijimos a la siguiente pestaña para configurar la webidentity

    IAM | Roles | webidentity
~~~
Identity provider
oidc.eks.us-east-1.amazonaws.com/id/863A480174C5074CD7194C3B84BC01EE

De tipo: Audience
sts.amazonaws.com

Next permisions

Attach permisions policies
AmazonEKSClusterAutoscalerPolicy

Next

Name
AmazonEKSClusterAutoscalerRole

Create role

Buscamos nuestro Role | Filter policies
AmazonEKSClusterAutoscalerRole

Entramos y le damos click en Trust relationships

Edit trust relationships

Editamos el parametro
"sts.amazonaws.com"
por
"system:serviceaccount:kube-system:cluster-autoscaler"
Actualizamos y guardamos
~~~