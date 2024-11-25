# Codebuild

## Requisitios:

- Tener un ecr para almacenar las imagenes
- Tener un cluster eks para desplegar la imagen creada o un deployment.
- Configurar el Proyecto del build eligiendo los requerimientos necesarios como el tipo de instancia



### 1. Creamos un repositorio privado con amazon ecr

Creamos el repositorio privado:
~~~sh
aws ecr create-repository --repository-name flappy-bird
# Nos daria la siguiente confirmacion de la creacion
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:124355643940:repository/flappy-bird",
        "registryId": "124355643940",
        "repositoryName": "flappy-bird",
        "repositoryUri": "124355643940.dkr.ecr.us-east-1.amazonaws.com/flappy-bird",
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

### 2. Creamos un cluster eks con los minimos requerimientos solo para ejemplificar el desplieuge.
Podemos optar por un cluster con instance type t2.micro

### 3. Creamos el proyecto para el build con Codebuild
Rellenamos los campos que nos solicita

En el campo source elegimos la fuente donde tenemos almacenado el buildspec.yml en nuestro caso Github ahi mismo asignamos las credenciales para que se pueda conectar al repositorio.
Configuramos los roles y permisos o asignamos uno nuevo
Elegimos el tipo de environment donde se desplegara nuestro build.
En el apartado de Buidspec elegimos:
    Use a buildspec file y colocamos el nombre que le hayamos otorgado

Creamos el buildspec.yml y lo guardamos en el repositorio de github.
~~~yml          buildspec.yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - echo Setting up Kubernetes configuration...
      - aws eks update-kubeconfig --region $AWS_DEFAULT_REGION --name $EKS_CLUSTER_NAME
  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - echo Tagging the image for ECR...
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - echo Pushing the image to ECR...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Deploying to Kubernetes...
      - kubectl run flappybird-pod --image=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG


env:
  variables:
    AWS_ACCOUNT_ID: "124355643940"
    AWS_DEFAULT_REGION: "us-east-1"
    EKS_CLUSTER_NAME: "my-eks"
    IMAGE_REPO_NAME: "flappy-bird"
    IMAGE_TAG: "latest"
~~~

Con estos pasos podremos desplegar un pod en un cluster eks de amazon.
