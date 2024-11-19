# Captura de logs con Fluentbit - ElasticSearch

Entorno:
~~~sh
minikube start --cpus=4 --memory=8000 --kubernetes-version=v1.30.0
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
~~~

## Instalacion ElasticSearch

~~~sh
# Install custom resource definitions:
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
#Install the operator with its RBAC rules:
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
#Monitor the operator logs, revisar que todo este funcionando:
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
~~~
Desplegado de un nodo de ElasticSearch:
~~~sh
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.16.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF
~~~

El operador crea y gestiona automáticamente los recursos de Kubernetes para alcanzar el estado deseado del clúster de Elasticsearch. Pueden pasar unos minutos hasta que se creen todos los recursos y el clúster esté listo para su uso.

Supervisión del estado del clúster y el progreso de la creación
editar
Obtenga una descripción general de los clústeres de Elasticsearch actuales en el clúster de Kubernetes, incluido el estado, la versión y el número de nodos:
~~~sh
kubectl get elasticsearch

NAME          HEALTH    NODES     VERSION   PHASE         AGE
quickstart    green     1         8.15.3     Ready         1m
~~~

Obtenga las credenciales.

Un usuario predeterminado se crea de forma predeterminada con la contraseña almacenada en un secreto de Kubernetes:elastic
~~~sh
PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
~~~

Revisar que el servicio este funcionando.

Desde dentro del clúster de Kubernetes:
~~~sh
curl -u "elastic:$PASSWORD" -k "https://quickstart-es-http:9200"
Desde su estación de trabajo local, utilice el siguiente comando en un terminal separado:

kubectl port-forward --address 0.0.0.0 service/quickstart-es-http 9200
Cambiar la direccion "https://192.168.52.139"

curl -u "elastic:$PASSWORD" -k "https://192.168.52.139:9200"
~~~
Dandonos una comprobacion de su estado.
~~~json
{
  "name" : "quickstart-es-default-0",
  "cluster_name" : "quickstart",
  "cluster_uuid" : "XqWg0xIiRmmEBg4NMhnYPg",
  "version" : {...},
  "tagline" : "You Know, for Search"
}
~~~
## Desplegue de kibana

Especifica una instancia de Kibana y asóciala a tu cluster de Elasticsearch:
~~~sh
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.16.0
  count: 1
  elasticsearchRef:
    name: quickstart
EOF
~~~
Supervisa el estado y el progreso de la creación de Kibana.

De manera similar a Elasticsearch, puedes recuperar detalles sobre las instancias de Kibana:
~~~sh
kubectl get kibana
#Y los Pods asociados:
kubectl get pod --selector='kibana.k8s.elastic.co/name=quickstart'
#Accede a Kibana.
#Se crea automáticamente un servicio para Kibana:ClusterIP
kubectl get service quickstart-kb-http
#Úsalo para acceder a Kibana desde tu estación de trabajo local:kubectl port-forward
kubectl port-forward --address 0.0.0.0 service/quickstart-kb-http 5601
~~~
Ábrelo en tu navegador. Su navegador mostrará una advertencia porque el certificado autofirmado configurado de forma predeterminada no está verificado por una autoridad de certificación conocida y su navegador no confía en él. Puede confirmar temporalmente la advertencia para los fines de este inicio rápido, pero se recomienda encarecidamente que configure certificados válidos para cualquier implementación de producción.https://localhost:5601

Inicie sesión como usuario.
- Usuario: elastic
- Contraseña se puede obtener con el siguiente comando:
~~~sh
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
~~~
## Instalacion fluent bit en kubernetes
Instalcion desde Helm.
~~~sh
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update
~~~
~~~sh values.fluentbit
https://github.com/fluent/helm-charts/blob/main/charts/fluent-bit/values.yaml
~~~
Vamos a hacer la instalacion desde el archivo values.
01-values-install.yaml Este archivo permite la busqueda de logs configuramos el password y el nombre del host para que se pueda vincular con elasticsearch

- host  linea: 445 y 460 (quickstart-es-http)
- pass  linea: 448 y 463 (kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')

~~~sh
helm install -f 01-values-install.yaml fluent-bit fluent/fluent-bit
~~~
[Comparativa de Fluentd vs Fluent Bit](https://docs.aws.amazon.com/es_es/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-logs.html)

## Entorno listo para probar su funcionamiento.