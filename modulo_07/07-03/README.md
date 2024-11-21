# Creacion de un Helm chart personalizado

Vamos a crear las plantillas para trabajar nuestro helm con nombre fibonacci
~~~sh
helm create fibonacci
~~~
Modificamos el helm con nuestros requerimientos para desplegar la app quedando de la siguiente manera:
~~~sh
fibonacci/
├── charts
│   └── fibonacci-0.1.0.tgz
├── Chart.yaml
├── index.yaml
├── README.md
├── templates
│   ├── custommetrics.yaml
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── hpa.yaml
│   ├── NOTES.txt
│   ├── servicemonitor.yaml
│   ├── service.yaml
│   ├── tests
│   │   └── test-connection.yaml
│   └── vpa.yaml
└── values.yaml
~~~

Si queremos ver como quedarian los archivos configurados con las variables que colocamos, esto nos ayuda a verificar si el etiquetado es correcto:
~~~sh
# Al final es el directorio donde tienes el chart o si estas dentro del directorio colocamos "." en lugar del directorio 
helm install --dry-run debug .
# Una u otra nos muestra nuestros manifiestos.
helm install --dry-run ./fibonacci/
~~~

Para empaquetar nuestro helm ejecutamos el siguiente comando:
~~~sh
helm package fibonacci/
# Quedaria algo como lo siguiente
fibonacci-0.1.0.tgz
# movemos ese archivo dentro de nuestra carpeta charts
~~~
Para guardar nuestro helm en repositorio necesitamos el archivo index.yaml que lo generamos.
Ejecutando el siguiente comando dentro de nuestra carpeta del helm:
~~~sh
helm repo index .
~~~

## Almacenar nuestro Helm

### 1. Gitpages de Github

- Creamos un repositorio en github de nuestro chart
- Creamos una page para ese repositorio en github

### 2. Creamos un repositorio privado con amazon ecr

Creamos el repositorio privado:
~~~sh
aws ecr create-repository --repository-name fibonacci
# Nos daria la siguiente confirmacion de la creacion
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:124355643940:repository/fibonacci",
        "registryId": "124355643940",
        "repositoryName": "fibonacci",
        "repositoryUri": "124355643940.dkr.ecr.us-east-1.amazonaws.com/fibonacci",
        "createdAt": "2024-11-20T17:42:49.682000-06:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
~~~

Necesitamos Autenticarnos para poder subir el chart
~~~sh
aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin 124355643940.dkr.ecr.us-east-1.amazonaws.com
# Confirmando el login
Login Succeeded
~~~

Una vez autenticado subimos nuestro chart con el siguiente comando:
~~~sh
helm push fibonacci-0.1.0.tgz oci://124355643940.dkr.ecr.us-east-1.amazonaws.com/
# Esta es la confirmacion que ha subido el chart al repositorio
Pushed: 124355643940.dkr.ecr.us-east-1.amazonaws.com/fibonacci:0.1.0
Digest: sha256:cce6dff67487528e7dd5dedcd3d663df33504741bcb9783eb6bfa9eaf39ec268
~~~

### 3. Creacion de un repositorio publico amazon ecr

Creamos el repositorio publico:
~~~sh
aws ecr-public create-repository \
    --repository-name fibonacci \
    --region us-east-1 
# Nos da la confirmacion de que se ha creado
{
    "repository": {
        "repositoryArn": "arn:aws:ecr-public::124355643940:repository/fibonacci",
        "registryId": "124355643940",
        "repositoryName": "fibonacci",
        "repositoryUri": "public.ecr.aws/q1v8t5f1/fibonacci",
        "createdAt": "2024-11-20T18:04:11.063000-06:00"
    },
    "catalogData": {}
}
~~~

Necesitamos Autenticarnos para poder subir el chart
~~~sh
aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws/q1v8t5f1
# Confirmando el login
Login Succeeded
~~~

Una vez autenticado subimos nuestro chart con el siguiente comando:
~~~sh
helm push fibonacci-0.1.0.tgz oci://public.ecr.aws/q1v8t5f1
# Esta es la confirmacion que ha subido el chart al repositorio
Pushed: public.ecr.aws/q1v8t5f1/fibonacci:0.1.0
Digest: sha256:cce6dff67487528e7dd5dedcd3d663df33504741bcb9783eb6bfa9eaf39ec268
~~~

## Desplegar el chart-fibonacci en kubernetes

### Instalacion desde github pages
Añadimos  la direccion de nuestra page de github de la siguiente manera:
~~~sh
helm repo add chart-fibonacci https://git-ed-hub.github.io/helmchart-fibonacci/
# Comprobamos que se encuntre nuestro repositorio
helm search repo chart-fibonacci
~~~

Con esto ya podemos instalar nuestro chart

Utilizar minikube para probar (deployment, service, hpa)
Para probar (vpa, custom metrics y metricas de prometheus) instalar el script de 01_test_prometheus.md

~~~sh
minikube start
minikube addons enable metrics-server
~~~

Para instalar el helm
podemos copiar la carpeta y apuntar a su ubicacion:

~~~sh
helm install fibonacci chart-fibonacci
# Dandonos el mensaje de instalacion
NAME: fibonacci
LAST DEPLOYED: Wed Nov 20 22:18:12 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
~~~

### Instalacion desde el repositorio privado amozon ecr

Si queremos que el despliegue sea en un cluster EKS solo ejecutamos el comando de instalacion.

Si queremos desplegarlo con minikube necesitamos primero autenticarnos ya que es un repositorio privado lo haremos con el siguiente comando:
~~~sh
aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin 124355643940.dkr.ecr.us-east-1.amazonaws.com
~~~

Ahora ya podremos instalar o descargar el chart:
~~~sh
helm install fibonacci oci://124355643940.dkr.ecr.us-east-1.amazonaws.com/fibonacci --version 0.1.0
# Confirmacion de descarga y despliegue del chart
Pulled: 124355643940.dkr.ecr.us-east-1.amazonaws.com/fibonacci:0.1.0
Digest: sha256:cce6dff67487528e7dd5dedcd3d663df33504741bcb9783eb6bfa9eaf39ec268
NAME: fibonacci
LAST DEPLOYED: Wed Nov 20 23:57:26 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
~~~

### Instalacion desde el repositorio publico amozon ecr

Aqui solamente necesitamos la direccion del chart para instalar:
~~~sh
helm install fibonacci oci://public.ecr.aws/q1v8t5f1/fibonacci --version 0.1.0
# Nos da la confirmacion de descarga y despliegue del chart
Pulled: public.ecr.aws/q1v8t5f1/fibonacci:0.1.0
Digest: sha256:cce6dff67487528e7dd5dedcd3d663df33504741bcb9783eb6bfa9eaf39ec268
NAME: fibonacci
LAST DEPLOYED: Thu Nov 21 00:12:06 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
~~~

## Helm test

Helm nos permite crear test.

- Creamos un pod que revise si hay conexion con nuestro deployment

Para probarlo ejecutamos el siguiente comando:
~~~sh
helm test fibonacci --namespace default
# Dando como resultado si ha pasado la prueba
NAME: fibonacci
LAST DEPLOYED: Wed Nov 20 19:28:36 2024
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE:     fibonacci-test-connection
Last Started:   Wed Nov 20 19:38:45 2024
Last Completed: Wed Nov 20 19:38:51 2024
Phase:          Succeeded
~~~

## Clean up

~~~sh
helm uninstall fibonacci 
~~~
