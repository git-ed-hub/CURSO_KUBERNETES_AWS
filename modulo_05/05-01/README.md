# Implementacion de Cluster AutoScaler
## Pasos
1. Desplegar el cluster EKS con terraform
~~~sh
terraform apply
~~~

2. En el campo de output de terraform sustituirlo por el parametro que esta en el archivo 01_cluster_autodiscover.yaml
~~~yaml
eks.amazonaws.com/role-arn: arn:aws:iam::124355643940:role/AmazonEKSClusterAutoscalerRole 
~~~
3. Cambiar la parte de la version del cluster por la version que usemos
~~~yaml
containers:
        - image: registry.k8s.io/autoscaling/cluster-autoscaler:v1.31.0
~~~
4. Entramos al cluster y desplegamos el archivo
~~~sh
kubectl apply -f 01_cluster_autodiscover.yaml
~~~
5. Checar los logs
~~~sh
watch kubectl logs -l app=cluster-autoscaler -n kube-system -f
watch kubectl get po -n kube-system
~~~

~~~
kubectl get po
NAME                           READY   STATUS    RESTARTS   AGE
nginx-managed-d45bfb65-d6vlj   0/1     Pending   0          20s
nginx-managed-d45bfb65-qj4v7   1/1     Running   0          20s

kubectl get nodes
NAME                          STATUS   ROLES    AGE     VERSION
ip-10-10-2-104.ec2.internal   Ready    <none>   7m45s   v1.31.0-eks-a737599
~~~

result:
~~~
kubectl get po
NAME                           READY   STATUS    RESTARTS   AGE
nginx-managed-d45bfb65-d6vlj   1/1     Running   0          14m
nginx-managed-d45bfb65-qj4v7   1/1     Running   0          14m

kubectl get nodes
NAME                          STATUS     ROLES    AGE   VERSION
ip-10-10-1-154.ec2.internal   NotReady   <none>   17s   v1.31.0-eks-a737599
ip-10-10-2-104.ec2.internal   Ready      <none>   20m   v1.31.0-eks-a737599

ip-10-10-1-154.ec2.internal   Ready    <none>   29s   v1.31.0-eks-a737599
ip-10-10-2-104.ec2.internal   Ready    <none>   20m   v1.31.0-eks-a737599
~~~

Con esto ya queda listo el servicio para poder autoescalar segun lo definamos.
