# App para ejemplificar el uso de Bases de Datos desde Kubernetes

Montamos un servidor de Mysql en cualquiera de sus versiones
En nuestro caso local

Requerimientos:

- Direccion del Servidor
- Usuario/Password de la base de Datos
- Crear una base de datos y una tabla donde almacenar los registros:

~~~sql
CREATE DATABASE payment;
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name_on_card VARCHAR(100),
    card_number VARCHAR(20),
    expiry_month INT,
    expiry_year INT,
    security_code VARCHAR(5),
    payment_method VARCHAR(10)
);
~~~

Creamos la variable del servidor en Jenkins o la modificamos manualmente

SERVER = "IP-SERVER-MYSQL"

Sustituimos el valor en el archivo y creamos la imagen con el Dockerfile

~~~sh
sed -i 's/XXXX/${SERVER}/' app.py
# al final revertimos para la sig sustitucion
sed -i 's/${SERVER}/XXXX/' app.py
~~~

Corremos el Jenkisfile y subimos la imagen al repositorio

~~~txt
Tiene pass root
testsysadmin8/mysql-app-payment:latest
No tiene pass root
testsysadmin8/mysql-noapp-payment:latest
Xtrabackup
testsysadmin8/xtrabackup:1.0.0-1
~~~

Desplegamos un Deployment en kubernetes y listo podemos acceder y actualizar mas registros

~~~txt
NAME                           READY   STATUS    RESTARTS   AGE
app-payment-796d9669c4-548c9   1/1     Running   0          4m6s
~~~

~~~sh
# Este es el acceso para guardar datos
kubectl port-forward --address 0.0.0.0 svc/mysql 3306


kubectl port-forward --address 0.0.0.0 service/app-payment-service 5000:80
~~~

Si tiene algun problema de escritura modificar la carpeta con los permisos

~~~sh
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/mysql-app-payment
sudo chmod -R 755 //var/lib/jenkins/workspace/mysql-app-payment
~~~

Creamos la imagen que servira para clonar mysql en el Statefulset

~~~Dockerfile
FROM percona/percona-xtrabackup:8.0.28
LABEL maintainer="hiroaki"

RUN microdnf update && \
    rm -rf /var/cache/yum && \
    microdnf -y install nmap-ncat shadow-utils && \
    groupadd --system -g 27 mysql && \
    useradd --system -s /usr/bin/false -g mysql -u 27 -c mysql --no-create-home --home-dir /nonexistent mysql && \
    microdnf -y remove shadow-utils && \
    microdnf clean all

USER mysql
~~~
