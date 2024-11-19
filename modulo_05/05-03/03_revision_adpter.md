# Revicion de los servicios de prometheus adapter

Como saber la Version
~~~sh
helm list --filter prometheus-adapter
#Revisar que este en funcionamiento
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/" | jq
~~~
Comando necesario para haacer una actualizacion al helm
~~~sh
helm upgrade -f 02_adapter_values.yaml prometheus-adapter prometheus-community/prometheus-adapter -n monitoring
# Despues de hacer una actualizacion necesitamos dar un restart
kubectl rollout restart deployment prometheus-adapter -n monitoring
~~~
Revisar los logs del Prometheus Adapter
~~~sh
watch kubectl logs -l app.kubernetes.io/name=prometheus-adapter -n monitoring
kubectl describe po -l app.kubernetes.io/name=prometheus-adapter -n monitoring
# debugear el servicio buscando conectividad
kubectl run -it --rm debug --image=busybox -n monitoring --restart=Never -- sh
wget -O- http://monitoring-kube-prometheus-prometheus.monitoring.svc:9090/api/v1/status/config
~~~