# Configuracion de Statefulset Mysql

Iniciar dos nodos minikube.
~~~sh
minikube start --nodes 2 --cpus=2 --memory=3000
~~~
Habilitar
~~~sh
minikube addons enable volumesnapshots
minikube addons enable csi-hostpath-driver
~~~
Desabilitar
~~~sh
minikube addons disable storage-provisioner
minikube addons disable default-storageclass
~~~
Aplicamos el siguiente parche
~~~sh
kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
~~~

Desplegar statefulset.yaml

Desplegar la app mysql sin passroot

testsysadmin8/mysql-noapp-payment:latest