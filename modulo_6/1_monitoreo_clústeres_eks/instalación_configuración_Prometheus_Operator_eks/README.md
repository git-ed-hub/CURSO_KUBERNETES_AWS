# Como instalar Prometheus en EKS?



## Pasos

### 0. Crear EKS Cluster (Optional)
```bash
eksctl create cluster -f eks.yaml
```

### 1. Desplegar Prometheus Stack Helm Chart
- Descargar `prometheus-values.yaml` Archivo para **Prometheus** de [aqui](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- Actualizar las siguientes variables

```yaml
etcd: false             # line 51
adminPassword: test123  # line 984 Pass para Grafana
kubeControllerManager:  # line 1469
  enabled: false
kubeEtcd:               # line 1744
  enabled: false
kubeScheduler:          # line 1849
  enabled: false
serviceMonitorSelector: # line 3637
  matchLabels: 
    prometheus: devops
commonLabels:           # line 28
  prometheus: devops
```

- Añadir el repositorio
```bash
helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts
```
- Actualizar el repositorio
```bash
helm repo update
```
- Revisar que version de prometheus esta disponible
```bash
helm search repo kube-prometheus-stack --max-col-width 23
```
- Instalar prometheus
```bash
helm install monitoring \
prometheus-community/kube-prometheus-stack \
--values prometheus-values.yaml \
--version 65.1.0  \
--namespace monitoring \
--create-namespace \
--debug
```
- Revisar que los pods se hayan desplegado
```bash
kubectl get pods -n monitoring
```
- Revisar que el service este funcionando
```bash
kubectl get svc -n monitoring 
```
- Entrar el panel de Prometheus
```bash
kubectl port-forward \
svc/monitoring-kube-prometheus-prometheus 9090 \
-n monitoring
```

- Nos vamos a la sig direccion `http://localhost:9090` y seleccionamos `targets`

```bash
kubectl get cm kube-proxy -n kube-system -o yaml
```
- Habilitamos Coredns ya que aun no esta activo
```
kubectl edit cm kube-proxy -n kube-system
```
modificar
kind: KubeProxyConfiguration
metricsBindAddress: 0.0.0.0

- Podemos modificar la parte especifica con el siguiente comando revisando con anterioridad que parte modificar.
```bash
kubectl -n kube-system get cm kube-proxy-config -o yaml |sed 's/metricsBindAddress: ""/metricsBindAddress: 0.0.0.0/' | kubectl apply -f -
```
- Revisamos si los pods se han actualizado si no lo reiniciamos.
```bash
watch -n 1 -t kubectl get pods -n kube-system
```
- Con este comando mandamos a reiniciar los pod para que carguen la nueva configuracion
```bash
kubectl -n kube-system patch ds kube-proxy -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"updateTime\":\"`date +'%s'`\"}}}}}"
```
- Regresamos a `http://localhost:9090` bajo `targets` y `alerts`

- Esperar 20-30 min para obtener mas informacion en Prometheus

```bash
kubectl port-forward \
svc/monitoring-grafana 3000:80 \
-n monitoring 
```

- Abrir los siguientes dashboards
  - Kubernetes / Compute Resources / Cluster
  - Kubernetes / Kubelet
  - USE Method / Cluster


## Para eliminar lo que implementamos despues de terminar.
```bash
helm repo remove prometheus-community bitnami
helm uninstall monitoring -n monitoring
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```
```bash
eksctl delete cluster -f eks.yaml
```
