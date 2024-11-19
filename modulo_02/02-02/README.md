# Sigue las instrucciones para Desplegar un EKS de Aws con Terraform

### Prerequisitos:

    Instalar Terraform
    Crear un Usuario aws
    Aws claves y configuracion
    kubectl
    Aws cli

## Pasos 1: Descargar los repositorios.
Clonar el repositorio usando el siguiente comando
~~~sh
git clone https://github.com/git-ed-hub/CURSO_KUBERNETES_AWS.git
~~~
- Despues de clonar el repo, nos cambiamos a la modulo_2\2-02\config\main.tf

Revisar los valores de las variables, algunos valores a revisar son:
- la region "us-east-1"
- user profile "user-terraform"

 
## Paso 2: Configuración.
Dentro de la carpeta config:

Ejecutamos los siguientes comandos para desplegar el cluster.
 ~~~sh
 # Se prepara el entorno para iniciar terraform
 terraform init
 # Ejecutamos una comprobacion de la infraestructura a desplegar
 terraform plan
 # Desplegamos la infraestructura deseada, confirmamos con "yes"
 terraform apply 
 ~~~
 
## Paso 3: Acceso al Cluster EKS
Para acceder al eks clutster, generamos el kubeconfig con el siguiente comando.
- Sustituyendo el --name y --region
 
En el siguiente comando remplazamos el nombre del cluster y la region quedando asi.
~~~sh
aws eks update-kubeconfig --name my-eks --region us-east-1
~~~
Ya podemos usar el cluster.
Interactuando con los comandos de kubectl.
~~~sh
kubectl get nodes
~~~

## Paso 4: Eliminar el Cluster EKS
Una vez que la practica este terminada, eliminaremos el cluster con el siguiente comando.
~~~sh
terraform destroy
~~~
- Confirmando con yes
