# Usa una imagen base de Python
FROM python:3.10-slim

# Establece el directorio de trabajo
WORKDIR /app

# Instala las dependencias
RUN pip install --no-cache-dir flask prometheus_client prometheus_flask_exporter

# Copia el código de la aplicación en el contenedor
COPY . /app

# Expone el puerto en el que Flask va a correr
EXPOSE 8060

# Comando para ejecutar la aplicación
CMD ["python", "app.py"]