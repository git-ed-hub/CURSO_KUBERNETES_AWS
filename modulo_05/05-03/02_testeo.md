# Pruebas de escalado
## Exponemos la app Fibonacci
Exponer la app
~~~sh
kubectl port-forward --address 0.0.0.0 \
svc/fibonacci-svc 8060
~~~
## Prueba 1: Despliegue de Hpa
Metricas por uso de CPU
Utilizar el archivo modulo_5\5_2\01_hpa_cpu.yaml
~~~yaml
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fibonacci-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fibonacci
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
~~~
~~~sh
kubectl apply -f 01_hpa_cpu.yaml
~~~

Para ver como va escalando podemos ejecutar:
~~~sh
watch kubectl get hpa
~~~
Al aplicar stress al pod aumentamos el uso de cpu para forzar un despliegue:
En la aplicacion web de Fibonacci colocar un numero: 40 que demanda consumo de cpu.
~~~txt
NAME                   REFERENCE              TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
fibonacci-autoscaler   Deployment/fibonacci   cpu: 200%/50%   1         10        4          3m9s
~~~
Eliminamos hpa
~~~sh
kubectl delete hpa fibonacci-hpa
~~~

## Prueba 2: Despliegue VPA
Despliegua el vpa con el archivo modulo_5\5_2\02_vpa.yaml
~~~yaml
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: fibonacci-vpa
  namespace: default
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: fibonacci
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: fibonacci
      minAllowed:
        cpu: "20m"
        memory: "50Mi"
      maxAllowed:
        cpu: "500m"
        memory: "1Gi"
      controlledResources: ["cpu", "memory"]
EOF
~~~
~~~sh
kubectl apply -f 02_vpa.yaml
~~~
~~~
NAME            MODE   CPU   MEM       PROVIDED   AGE
fibonacci-vpa   Auto   25m   262144k   True       16m
~~~

Al cabo de poco tiempo se vera reflejado como escalan los recursos del Pod
~~~sh
kubectl top po

Antes
NAME                         CPU(cores)   MEMORY(bytes)
fibonacci-6b687c795d-4r9s2   2m           22Mi

Despues
NAME                         CPU(cores)   MEMORY(bytes)
fibonacci-6b687c795d-mcqk5   20m          22Mi
~~~
Eliminamos vpa
~~~sh
kubectl delete vpa fibonacci-vpa
~~~

## Despliegue de Metrica-Personalizada
Despliegua el custom-metrics del archivo modulo_5\5_2\03_custom_metrics.yaml
~~~yaml
cat <<EOF | kubectl apply -f -
kind: HorizontalPodAutoscaler
apiVersion: autoscaling/v2
metadata:
  name: fibonacci-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fibonacci
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests
      target:
        # target 100 milli-requests per second,
        # which is 1 request every two seconds
        type: AverageValue
        averageValue: 500m
  # Tambien podemos añadir el autoescalado HPA por cpu para que se cumpla una u otra
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
EOF
~~~
La metrica personalizada se basa en peticiones POST en un rango de 2m o que superen las 500 peticiones

Eso lo logramos con el codigo siguiente que hace 510 solicitudes a la pagina
~~~sh
for i in {1..510}; do
    curl 192.168.52.139:8060/ \
        -H "Content-Type: application/json" \
        -d '{"number": 3}'
done
~~~
Resultado:
~~~sh
# Antes:
NAME        	REFERENCE          	TARGETS           	MINPODS   MAXPODS   REPLICAS
fibonacci-hpa   Deployment/fibonacci   0/500m, cpu: 5%/80%   1     	10    	1     
# Después:
NAME        	REFERENCE          	TARGETS             	MINPODS   MAXPODS   REPLICAS
fibonacci-hpa   Deployment/fibonacci  211m/500m, cpu: 12%/80%   1     10    	2   
~~~
Eliminamos hpa
~~~sh
kubectl delete hpa fibonacci-hpa
~~~