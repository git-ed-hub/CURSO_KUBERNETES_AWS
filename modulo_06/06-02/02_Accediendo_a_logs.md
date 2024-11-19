# Acceder a los Logs
Accedemos al panel por https://ip:5601 utiliza un certificado autofirmado aceptamos.
![](./img/01.png)
Nos autenticamos
- usuario: elastic
- Pass: kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
![](./img/02.png)
Dentro del panel nos dirigimos al apartado Analytics / Discover 
Damos click sobre Create data view
![](./img/06.png)
Nos aparecera el logstash_devops-2024 este lo genero Fluentbit y es donde entregara los logs.
Rellenamos ese mismo nombre sobre el campo index pattern
![](./img/011.png)
En timestamp colocamos como la imagen y damos click en Save data view to kibana
![](./img/012.png)
Listo ya podremos hacer la busqueda de logs de pods, o recursos de kubernetes que hemos especificado.
![](./img/013.png)
En este caso son logs del juego flappybird, que aparecen por el nombre del pod.
![](./img/014.png)
Aqui se muestra como esta recibe y envia logs de fluentbit hacia elasticsearch
![](./img/015.png)
