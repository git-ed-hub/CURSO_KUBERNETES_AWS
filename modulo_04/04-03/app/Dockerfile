# Usa una imagen base de Python
FROM python:3.10-slim

# Establece el directorio de trabajo
WORKDIR /app

# Copia el archivo de requerimientos
COPY requirements.txt .

# Instala las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copia el código de la aplicación en el contenedor
COPY . /app

# Expone el puerto en el que Flask va a correr
EXPOSE 5000

# Comando para ejecutar la aplicación
CMD ["python", "app.py"]