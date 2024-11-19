# Dynamic provisioning using StorageClass:

~~~sh
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm repo update

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--create-namespace \
--namespace nfs-provisioner \
--set nfs.server=192.168.52.136 \
--set nfs.path=/home/ubuntu/data \
--set storageClass.onDelete=false
~~~

Facilita la creación de volúmenes a demanda: Al usar esta StorageClass, no necesitas crear manualmente un PersistentVolume (PV) cada vez que quieras un nuevo volumen NFS. En su lugar, puedes crear un PVC que solicita almacenamiento, y el provisionador creará automáticamente el subdirectorio correspondiente en el servidor NFS

Para configurar el PVC con el debemos tipear para saber el nombre del StorageClass

~~~sh
kubectl get storageclass -n nfs-provisioner
~~~

~~~txt
NAME                 PROVISIONER                                     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-client           cluster.local/nfs-subdir-external-provisioner   Delete          Immediate           true                   7s
~~~

Si necesitamos crear otro StorageClass diferente necesitamos llevarnos los mismos valores con los que se creo el StorageClass

~~~yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-sc
provisioner: cluster.local/nfs-subdir-external-provisioner  # Este nombre debe coincidir con el del provisionador que instalaste
parameters:
  archiveOnDelete: "false"  # Opción para mantener o eliminar datos al eliminar el PVC
~~~

Asignamos el nombre del StorageClass al PVC

~~~yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-dynamic
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client # Debe coincidir el nombre que nos dio con el recurso que vamos a utilizar
  resources:
    requests:
      storage: 1Gi
~~~

Despues desplegamos un Deployment para interactuar con el volumen NFS

~~~yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-gallery
spec:
  selector:
    matchLabels:
      app: app-gallery
  replicas: 1
  template:
    metadata:
      labels:
        app: app-gallery
    spec:
      containers:
        - name: app-gallery
          image: testsysadmin8/flask-img:latest
          ports:
            - name: http
              containerPort: 5000
          volumeMounts:
            - name: nfs-volume
              mountPath: /app/volume
      volumes:
        - name: nfs-volume
          persistentVolumeClaim:
            claimName: nfs-dynamic
~~~

Cada Volumen dinamico genera un directorio en el volumen, que es el que ocupara para administrar esos recursos.

Confirma la Configuración del Cliente y Servidor NFS
Asegúrate de que los Pods en Kubernetes están montando la ruta correcta. Ejecuta en el Pod el siguiente comando para validar el montaje NFS:

~~~sh
kubectl exec -it <nombre-del-pod> -- mount | grep nfs
~~~
