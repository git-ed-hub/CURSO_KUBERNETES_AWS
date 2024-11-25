# Instalar Gitlab

Para instalar gitlab lo haremos con docker igualmente para no estar creando VM.

Entonces para instalar nos vamos a Docker hub para descargar la imagen mas reciente o la estable, en este caso usaremos la version: gitlab/gitlab-ee:latest
~~~sh
docker pull gitlab/gitlab-ce:latest
~~~
Iniciamos minikube con la configuracion que sea mas adecuada
~~~sh
minikube start --cpu=4 --memory=6000
~~~

Antes de ejecutar la imagen debemos crear esta variable de entorno para los volumenes lo que permitira que la data sea persistente
~~~sh
export GITLAB_HOME=/srv/gitlab
~~~
y por ultimo ejecutamos el contenedor
~~~sh
sudo docker run -d \
  --hostname gitlab.example.com \
  --network minikube \
  --publish 9443:443 --publish 9080:80 --publish 2222:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  gitlab/gitlab-ee:latest
~~~
La instalacion de gitlab puede tardar unos minutos ya que esta image lo que hace es ejectuar o correr una receta de chef donde provisiona todo lo necesario, para ver lo que esta sucediendo podemos ejecutar este comando:
~~~sh
docker logs -f gitlab
~~~

Para acceder a gitlab:
~~~sh
usuario: root
pass: sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
~~~

Agregar cluster de minikube a Gitlab
~~~sh
Antes que nada debemos habilitar los requests to the local network in gitlab en settings > network > outbound requests
# Colocamos
192.168.0.0
~~~

Para conocer la ip de gitlab
~~~sh
docker inspect gitlab
~~~
Tambien debemos modificar el campo 

General / Visibility and access controls / Custom Git clone URL for HTTP(S)

debemos colocar la URL pero con la ip de gitlab
~~~sh
http://192.168.49.3
~~~

Crear un agente para configurar el cluster:
Creamos un archivo en nuestro proyecto en el titulo colocamos lo siguiente, asignandole un nombre:
~~~sh
.gitlab/agents/<agent-name>/config.yaml
~~~

Cambiar la direccion ip de donde se encuentra alojado nuestro gitlab, en nuestro caso es: "192.168.49.3"
~~~sh
helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install novo gitlab/gitlab-agent \
    --namespace gitlab-agent-novo \
    --create-namespace \
    --set image.tag=v17.6.0 \
    --set config.token=glagent-2Lc6qNe2ayxpY4U7z_t9y-Nb314GoG1nBMrxrqYxtSuTM1FyWA \
    --set config.kasAddress=ws://192.168.49.3/-/kubernetes-agent/
~~~

Clonar el repo por ssh
~~~sh
git@192.168.49.3:root/deployment.git
http://192.168.49.3/root/deployment.git
~~~

Crear el archivo del pipeline, asignamos variables
~~~sh           .gitlab-ci.yml
stages:
  - build
  - push
  - deploy

build_image:
  stage: build
  image: docker:19.03.12
  services:
    - docker:dind
  before_script:
    - apk add --no-cache curl python3 py3-pip && pip install awscli
  script:
    - docker build -t testsysadmin8/flappybird:$CI_COMMIT_SHA .
  only:
    - main

push_image:
  stage: push
  image: docker:19.03.12
  services:
    - docker:dind
  script:
    - docker login -u testsysadmin8 -p "$DOCKERPASS"
    - docker push testsysadmin8/flappybird:$CI_COMMIT_SHA
  only:
    - main

deploy_minikube:
  stage: deploy
  script:
    - rm -rf $HOME/.kube
    - mkdir -p $HOME/.kube
    - echo "$CONFIG" > $HOME/.kube/config
    - export KUBECONFIG=$HOME/.kube/config
    - kubectl config get-contexts
    - kubectl config use-context minikube
    - kubectl run flappybird-pod --image=testsysadmin8/flappybird:$CI_COMMIT_SHA
    - kubectl apply -f deployment.yaml
  only:
    - main
~~~

# Instalar gitlab-runner
~~~sh
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt install gitlab-runner
# para eliminar los runners
sudo rm /etc/gitlab-runner/config.toml
sudo rm ~/.gitlab-runner/config.toml
~~~
Correr el agente como sudo
~~~sh
sudo gitlab-runner register --url http://192.168.49.3 --token glrt-t3_znzAk-jsm72nahg5zQLy
sudo gitlab-runner start
sudo gitlab-runner run
# Rellenar con la siguiente info
# El servidor
http://192.168.49.3
# Nombre 
ubuntu
# Donde esta instalado el agente
shell
~~~


Configurar el archivo config del agente
~~~sh
ci_access:
  projects:
    - id: Administrator/pipeline
~~~

En nuestro caso redireccionamos ala maquina 192.168.52.139 por que no tenemos los certificados
~~~sh
sudo nano /etc/hosts
192.168.49.3 gitlab.example.com
~~~
