# Verificar funcionamiento

Exponemos el pod para poder mostrar su contenido
~~~sh
kubectl port-forward --address 0.0.0.0 pod/<nombre_del_pod> 8080:80
~~~
