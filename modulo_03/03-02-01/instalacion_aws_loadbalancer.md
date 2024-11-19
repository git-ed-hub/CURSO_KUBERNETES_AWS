# Instalación de AWS Load Balancer
## Prerequisitos:
- Crear la poliltica AWSLoadBalancerControllerIAMPolicy (creada con terraform)
- Adjuntar la politica AWSLoadBalancerControllerIAMPolicy a AmazonEKSLoadBalancerControllerRole (adjuntada con terraform).
- Asegúrate de que las subnets tengan las siguientes etiquetas: (declaradas en terraform)
~~~sh
#Subnets Públicas (si el ALB es público):
kubernetes.io/role/elb = 1
#Subnets Privadas (si el ALB es interno):
kubernetes.io/role/internal-elb = 1
~~~
## Paso 1:
Desplegar el cluster terraform, ya contiene las politicas para el Load Balancer.

- Reemplace 111122223333 por su ID de cuenta. eje: "124355643940"

Después de reemplazar el texto, ejecute el comando modificado para crear el archivo aws-load-balancer-controller-service-account.yaml.

~~~sh
cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::124355643940:role/AmazonEKSLoadBalancerControllerRole
EOF
~~~

Cree la cuenta de servicio Kubernetes en el clúster. La cuenta de servicio de Kubernetes denominada aws-load-balancer-controller está anotado con el rol de IAM que creó con el nombre AmazonEKSLoadBalancerControllerRole.
~~~sh
kubectl apply -f aws-load-balancer-controller-service-account.yaml
~~~

## Paso 2: instalar el cert-manager
Instale el cert-manager con uno de los siguientes métodos para ingresar la configuración del certificado en los webhooks.
Instalación de cert-manager usando Quay.io
~~~sh
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.5/cert-manager.yaml
~~~
## Paso 3: instalar el AWS Load Balancer Controller

Reemplace my-cluster por el nombre del clúster, en micaso es "my-eks". En el siguientes comando, aws-load-balancer-controller es la cuenta de servicio de Kubernetes que creó en un paso anterior.
~~~sh

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=my-eks \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller
~~~

Resultado en consola

    NAME: aws-load-balancer-controller
    LAST DEPLOYED: Thu Oct 31 12:30:33 2024
    NAMESPACE: kube-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    AWS Load Balancer controller installed!

Comprobar el estado del serviceaccount

~~~sh
kubectl get serviceaccount aws-load-balancer-controller -n kube-system
~~~
Comprobar que el servicio este desplegado
~~~sh
kubectl get deployment -n kube-system aws-load-balancer-controller
~~~
    NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
    aws-load-balancer-controller   2/2     2            2           84s
## Paso 4: Implementación de una aplicación de muestra
Expondremos el juego Flappy-bird, el archivo despliega el deployment, service, ingress necesarios.
~~~sh
kubectl apply -f 04_alb_aws.yaml
~~~
Al cabo de unos minutos, verifique que el recurso de entrada se haya creado con el comando siguiente.
~~~sh
kubectl get ingress/ingress-game -n nginx-game
# comprobar estado del ingress
kubectl describe ingress/ingress-game -n nginx-game
~~~

## Paso 5: Eliminar el cluster y los servicios relacionados
~~~sh
terraform destroy
~~~
Comprobar no tener alb aosociados, eliminarlos.
