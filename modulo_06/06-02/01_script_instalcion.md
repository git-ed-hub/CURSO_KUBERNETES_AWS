# Script para el despliegue EKF
~~~sh
cat <<'EOS' > script.sh
#!/bin/bash
# cluster
minikube start --cpus=4 --memory=8000 --kubernetes-version=v1.30.0
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
minikube addons enable metrics-server
# Install apps
cat <<EOF > apps.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-game
  name: nginx-game
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-game
  template:
    metadata:
      labels:
        app: nginx-game
    spec:
      containers:
      - image: testsysadmin8/nginx-game:latest
        name: nginx-game
        ports:
        - name: web
          protocol: TCP
          containerPort: 80
---
kind: Service
apiVersion: v1
metadata:
  name: nginx-svc
  labels:
    app: nginx-game
spec:
  selector:
    app: nginx-game
  ports:
  - name: web
    protocol: TCP
    port: 8050
    targetPort: 80
EOF
kubectl apply -f apps.yaml
# Instal elasticsearch
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
sleep 15
# validacion stado del pod
PARTPOD="operator"
NAMESPACEK8S="elastic-system"
POD_NAME=$(kubectl get po -n $NAMESPACEK8S |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACEK8S" -o jsonpath='{.status.phase}')
    # Verifica si el pod está en estado "Running"
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done

# Instalacion elastic pod
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
sleep 10
# validacion stado del pod
PARTPOD="quickstart-es"
NAMESPACEK8S="default"
POD_NAME=$(kubectl get po -n $NAMESPACEK8S |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACEK8S" -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
#
#Despliegue kibana
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
sleep 10
# validacion stado del pod
PARTPOD="quickstart-kb"
NAMESPACEK8S="default"  # Reemplaza con el NAMESPACEK8S de tu pod
POD_NAME=$(kubectl get po -n $NAMESPACEK8S |grep $PARTPOD | awk '{print $1}') # Reemplaza con el nombre del pod que quieres monitorear
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACEK8S" -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
# fin validacion 

# instalacion Fluentbit
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
cat <<EOF > 01-values-install.yaml
config:
  service: |
    [SERVICE]
        Daemon Off
        Flush {{ .Values.flush }}
        Log_Level {{ .Values.logLevel }}
        Parsers_File /fluent-bit/etc/parsers.conf
        Parsers_File /fluent-bit/etc/conf/custom_parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port {{ .Values.metricsPort }}
        tls Off
        Health_Check Off

  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        multiline.parser docker, cri
        Tag kube.*
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On

    [INPUT]
        Name systemd
        Tag host.*
        Systemd_Filter _SYSTEMD_UNIT=kubelet.service
        Read_From_Tail On

  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Merge_Log On
        Merge_Log_Trim On
        Labels Off
        Annotations Off
        K8S-Logging.Parser On
        K8S-Logging.Exclude On

    [FILTER]
        Name nest
        Match kube.*
        Operation lift
        Nested_under kubernetes
        Add_prefix kubernetes_

    [FILTER]
        Name grep
        Match kube.*
        Exclude kubernetes_container_name fluent-bit

  outputs: |
    [OUTPUT]
        Name es
        Match kube.*
        Type  _doc
        Host quickstart-es-http
        Port 9200
        HTTP_User elastic
        HTTP_Passwd $PASSWORD
        Replace_Dots On
        tls On
        tls.verify Off
        tls.verify_hostname Off
        Logstash_Format On
        Logstash_Prefix logstash_devops
        Retry_Limit False
        Suppress_Type_Name On
        #network
        net.dns.mode                TCP
        net.keepalive               on
        net.keepalive_idle_timeout  10
EOF
sleep 2
helm install -f 01-values-install.yaml fluent-bit fluent/fluent-bit
sleep 10
# validacion stado del pod
PARTPOD="fluent"
NAMESPACEK8S="default"
POD_NAME=$(kubectl get po -n $NAMESPACEK8S |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACEK8S" -o jsonpath='{.status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
# Pass para Autenticarnos 

kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
EOS
chmod +x script.sh
./script.sh
~~~
