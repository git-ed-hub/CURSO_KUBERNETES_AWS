### Sigue las instrucciones para crear el Cluster en GCLOUD

Prerequisitos:

    Instalar Terraform
    Crear un proyecto para desplegar el cluster
    Generar el usuario y el acceso para desplegar la infraestructura con terraform
    kubectl
    SDK gcloud

Pasos:
 1.  Crear el proyecto y generar los accesos a GCLOUD

 En el panel de bienvenida seleccionamos:
    
    Crear proyecto
    Elegimos el nombre para el proyecto
    Creamos el proyecto
    Guardamos el Id del proyecto generado.

 Creamos el usuario y el acceso
    
    Nos dirigimo a la pestaña IAM Administracion - CUENTAS DE SERVICIO

	Creamos la cuenta de servicio
	- Asignamos un Nombre
	- Asigmanos a que proyecto tendra acceso
	- Que rol o permiso tiene acceso (Propietario)
	- Listo

	Entramos en la cuenta que acabamos de crear
	- Nos dirigimos a Claves
	- Damos click en Agregar Clave
	- Elegimos formato json
	- Se descarga y lo llevamos a la carpeta del proyecto

 2.  Clonar el repositorio usando el siguiente comando

 ```
 git clone https://github.com/git-ed-hub/CURSO_KUBERNETES_AWS.git
 ```
 3. Despues de clonar el repo, nos cambiamos a la ruta MÓDULO 1 - Introducción a Kubernetes y Contenedores/TERRAFORM-GCLOUD Instalar un cluster de K8s con kubeadm.

    Aqui vamos a pegar el archivo formato .json que descargamos el cual seria la clave de acceso.

    Revisar los valores de las variables, si necesitas ajustar la region "us-east-1", o cualquier otro cambio que sea necesario.
 
 4. Ahora solo ejecutamos los siguientes comandos para desplegar el cluster.
 ```
 terraform init
 terraform plan
 terraform apply 

 ```
 
 5.  Para acceder al eks clutster con el siguiente comando.

 ```
gcloud auth login

 ```
 Damos autorizacion de verificacion de la cuenta.
 Despues ejecutamos en terminal.
 ```
 gcloud cloud-shell ssh

 ```

6. Ahora configuramos el proyecto en que trabajaremos.
```
gcloud config set project [PROJECT_ID]
```

7. Con eso estaremos en el proyecto que trabajaresmo y de ahi seria desplazarte al cluster con el siguiente comando.

```
gcloud compute ssh --zone "<zona>" "master" --project "<nombre-proyecto>"
```


8. Y eso es todo ya podemos usar el comando kubectl.
```
kubectl get pods
```

9. Una vez que la practica este terminada, eliminaremos el cluster con el siguiente comando.

```
terraform destroy
```