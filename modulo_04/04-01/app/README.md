# App para ejemplificar el uso de Volumenes en Kubernetes

Creamos una App diseñada en Flask que nos permita mostrar el contenido en imagenes de una carpeta.
Esta carpeta le vamos a crear un volumen en sus diferentes variantes para ver como se comporta en cada una de sus etapas

## Implementacion:

Creamos el archivo app.py que contiene el codigo que nos permite subir y mostrarnos el contenido en la carpeta /app/volume

~~~py
from flask import Flask, request, redirect, url_for, render_template, send_from_directory
import os

app = Flask(__name__)
UPLOAD_FOLDER = '/app/volume'  # Directorio para almacenar imágenes
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/')
def index():
    images = os.listdir(app.config['UPLOAD_FOLDER'])
    return render_template('index.html', images=images)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return redirect(url_for('index'))
    file = request.files['file']
    if file.filename == '':
        return redirect(url_for('index'))
    if file:
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], file.filename))
        return redirect(url_for('index'))

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
~~~

Creamos un archivo Dockerfile para montar nuestra imagen

~~~Dockerfile
# Usa una imagen base con Python
FROM python:3.10-slim

# Establece el directorio de trabajo
WORKDIR /app

# Creamos un directorio para montar un volumen
RUN mkdir -p /app/volume

# Copia los archivos de la aplicación a la imagen
COPY . /app

# Instala las dependencias
RUN pip install --no-cache-dir flask

# Expone el puerto en el que Flask se ejecutará (opcional, según configuración de Flask)
EXPOSE 5000

# Define el comando para ejecutar la aplicación
CMD ["python", "app.py"]
~~~

Lo siguiente es colocar el contenido para que sea consumido por Flask en el siguiete orden

~~~arduino
/app
├── app.py
├── static
│   ├── fonts
│   ├── css
│   │   └── bootstrap.min.css
│   └── js
│       └── bootstrap.bundle.min.js
├── templates
│   └── index.html
~~~

Ejecutamos la instruccion para construir la imagen

~~~sh
docker build -t flask-image-app .
# montamos la imagen y la provamos
docker run --rm -p 0.0.0.0:5000:5000 -v /home/ubuntu/volume:/app/volume flask-image-app
~~~

## Repositorio dockerhub

~~~sh
docker push testsysadmin8/flask-img:latest
~~~