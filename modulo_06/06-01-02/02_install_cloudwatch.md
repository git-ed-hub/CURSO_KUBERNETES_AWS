# Instalacion CloudWatch en EKS aws

Ingresar al cluster
~~~sh
aws eks update-kubeconfig --name my-eks --region us-east-1
~~~

## Instalar Fluent Bit para enviar registros desde contenedores a CloudWatch Logs

1. Si aún no tiene un espacio de nombres llamado amazon-cloudwatch, cree uno con el siguiente comando:
~~~sh
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: amazon-cloudwatch
  labels:
    name: amazon-cloudwatch
EOF
~~~

2. Ejecute el siguiente comando para crear un ConfigMap denominado cluster-info con el nombre del clúster y la Región a la que se enviarán los registros. Sustituya cluster-name y cluster-region por el nombre y la Región del clúster.
~~~sh
ClusterName=my-eks
RegionName=us-east-1
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
kubectl create configmap fluent-bit-cluster-info \
--from-literal=cluster.name=${ClusterName} \
--from-literal=http.server=${FluentBitHttpServer} \
--from-literal=http.port=${FluentBitHttpPort} \
--from-literal=read.head=${FluentBitReadFromHead} \
--from-literal=read.tail=${FluentBitReadFromTail} \
--from-literal=logs.region=${RegionName} -n amazon-cloudwatch
~~~

3. Descargue e implemente el daemonSet de Fluent Bit en el clúster. Configuración optimizada de Fluent Bit para computadoras con Linux, ejecute este comando.
~~~sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit-compatible.yaml
~~~

4. Especifique el siguiente comando para validar la implementación. Cada nodo debe tener un pod denominado fluent-bit-*.
~~~SH
kubectl get pods -n amazon-cloudwatch

NAME                                                              READY   STATUS    RESTARTS   AGE
amazon-cloudwatch-observability-controller-manager-646b6dc4wl2h   1/1     Running   0          15m
cloudwatch-agent-zjb5w                                            1/1     Running   0          15m
fluent-bit-compatible-dj4gs                                       1/1     Running   0          2m20s
~~~

Con esta configuracion FluentBit estara reenviando los logs a CloudWatch.

[Referencia de instalacion Fluentbit](https://docs.aws.amazon.com/es_es/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html)