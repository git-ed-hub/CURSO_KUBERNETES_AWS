# Usa una imagen base con Python
FROM python:3.10-slim

# Establece el directorio de trabajo
WORKDIR /app

# Creamos un directorio para montar un volumen
RUN mkdir -p /app/volume

# Instala las dependencias
RUN pip install --no-cache-dir flask

# Copia los archivos de la aplicación a la imagen
COPY . /app

# Expone el puerto en el que Flask se ejecutará (opcional, según configuración de Flask)
EXPOSE 5000

# Define el comando para ejecutar la aplicación
CMD ["python", "app.py"]