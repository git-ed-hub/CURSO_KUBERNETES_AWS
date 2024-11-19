# Estructura.
Separamos la instalacion en secciones.

- 00_Instalacion.md: Nos muestra el proceso de instalacion.
- 01_script_instalacion.md: Creamos un script para instalar en minikube, se puede ajustar la seccion Minikube y sustituirla por Custom-Metrics para EKS.
- 02_testeo.md: Hacemos las pruebas para hpa, vpa, custom metrics.
- 03_revision_adpter.md: revisar comportamiento prometheus adapter.

La carpeta App cuenta con la aplicacion para exponer /metrics
La carpeta Config cuenta con los archivos para la instalacion y configurar el entorno.