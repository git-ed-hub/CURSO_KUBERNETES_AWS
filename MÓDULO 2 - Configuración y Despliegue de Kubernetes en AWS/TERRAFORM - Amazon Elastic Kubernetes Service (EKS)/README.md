### Sigue las instrucciones para crear el AWS EKS infra con Terraform 

Prerequisitos:

    Instalar Terraform
    Aws claves y configuracion
    kubectl
    Aws cli

Pasos:
 1.  Clonar el repositorio usando el siguiente comando

 ```
 git clone https://github.com/git-ed-hub/CURSO_KUBERNETES_AWS.git
 ```
 2. Despues de clonar el repo, nos cambiamos a la ruta MÓDULO 2 - Configuración y Despliegue de Kubernetes en AWS/TERRAFORM - Amazon Elastic Kubernetes Service (EKS)
.
Revisar los valores de las variables, si necesitas ajustar la region "us-east-1", o cualquier otro cambio que sea necesario.
 
 3. Ahora solo ejecutamos los siguientes comandos para desplegar el cluster.
 ```
 terraform init
 terraform plan
 terraform apply 

 ```
 
 4.  Para acceder al eks clutster, generamos el kubeconfig con el siguiente comando.
 ```
 aws eks update-kubeconfig --name <cluster-name> --region <region>

 ```
 En el siguiente comando remplazamos el nombre del cluster y la region quedando asi.
 Eg:
 ```
 aws eks update-kubeconfig --name my-cluster --region us-east-1

 ```

5. Y eso es todo ya podemos usar el comando kubectl.
```
kubectl get pods
```

6. Una vez que la practica este terminada, eliminaremos el cluster con el siguiente comando.

```
terraform destroy
```
