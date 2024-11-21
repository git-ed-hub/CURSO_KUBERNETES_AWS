# Script de instalacion para pruebas de helm
~~~sh
cat <<'EOF' > script.sh
#!/bin/bash
# Implementacion Cluster
minikube start --cpus=4 --memory=6000 --kubernetes-version=v1.31.0
minikube addons enable metrics-server
# Instalacion Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
# Archivo values 
cat <<EFL > 01_prom_values.yaml
defaultRules:
  rules:
    etcd: false
kubeControllerManager:
  enabled: false
kubeEtcd:
  enabled: false
kubeScheduler:
  enabled: false
grafana:
  image:
    tag: 11.2.1
  adminPassword: test123
EFL
# Instalamos prometheus
helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring \
prometheus-community/kube-prometheus-stack \
--values 01_prom_values.yaml \
--version 65.1.0  \
--namespace monitoring \
--create-namespace
# Esperamos a que se levante el servicio
sleep 20
PARTPOD="prometheus-prometheus"
NAMESPACE="monitoring"
POD_NAME=$(kubectl get po -n $NAMESPACE |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    # Verifica si el pod está en estado "Running"
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
# Creamos archivo values
cat <<EFL > 02_adapter_values.yaml
rules:
  rules:
    - seriesQuery: 'flask_http_request_total{namespace!="",pod!=""}'
      resources:
        overrides:
          namespace:
            resource: namespace
          pod:
            resource: pod
      name:
        matches: "^(.*)_total"
        as: "http_request_total"
      metricsQuery: 'sum(rate(flask_http_request_total{<<.LabelMatchers>>}[2m])) by (namespace, pod)'
EFL
# Instalamos prometheus adapter
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-adapter \
prometheus-community/prometheus-adapter \
--set prometheus.url="http://monitoring-kube-prometheus-prometheus.monitoring.svc" \
--set prometheus.port="9090" \
--set rbac.create="true" \
--namespace monitoring  \
--set image.tag="v0.12.0" \
--values 02_adapter_values.yaml
# Esperamos a que se levante el servicio
sleep 10
PARTPOD="prometheus-adapter"
NAMESPACE="monitoring"
POD_NAME=$(kubectl get po -n $NAMESPACE |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    # Verifica si el pod está en estado "Running"
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
# Instalamos Vpa
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/hack
./vpa-up.sh
EOF
chmod +x script.sh
./script.sh
~~~

## Pruebas para testeo

Testear request de las metricas personalizadas
~~~sh
for i in {1..510}; do
    curl 192.168.52.139:8060/ \
        -H "Content-Type: application/json" \
        -d '{"number": 3}'
done
~~~

Para probar el uso de cpu colocar un valor de 40 en la aplicacion de fibonacci.
~~~sh
kubectl port-forward --address 0.0.0.0 svc/fibonacci 8060
~~~
