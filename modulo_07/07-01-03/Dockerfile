# Usamos la imagen oficial de Nginx como base
FROM nginx:latest

# Copiamos los archivos HTML personalizados al directorio predeterminado de Nginx
COPY html/ /usr/share/nginx/html/

# Exponemos el puerto 80 para el tráfico HTTP
EXPOSE 8090

# Comando para ejecutar Nginx en el contenedor
CMD ["nginx", "-g", "daemon off;"]