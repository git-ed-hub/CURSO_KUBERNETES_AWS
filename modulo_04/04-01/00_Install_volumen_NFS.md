# Instalacion volume NFS

Desplegar el volumen en un Servidor en un equipo Ubuntu

~~~sh
#update e instalar
apt update && apt -y upgrade

apt install -y nfs-server

# Creamos el directorio que almacenara el Volumen NFS
mkdir /home/ubuntu/data

# Agregamos la siguiente instruccion al final el archivo
# la primera parte es la direccion para alamacenar NFS
# la ip es la direccion del cliente
# La parte final son los permisos del directorio
sudo nano /etc/exports
/home/ubuntu/data 192.168.52.136(rw,no_subtree_check,no_root_squash)

# Habilitamos el servicio
systemctl enable --now nfs-server

exportfs -ar
~~~

Cliente es donde tendremos kubernetes

~~~sh
# instalamos el cliente de NFS instalarlo en todos los worker nodes que se tengan
apt install -y nfs-common


~~~

Probar que el volumen se accesible

sudo mount -t nfs 192.168.52.136:/home/ubuntu/data /home/ubuntu/volume
Desmontar el volume
sudo umount /home/ubuntu/volume