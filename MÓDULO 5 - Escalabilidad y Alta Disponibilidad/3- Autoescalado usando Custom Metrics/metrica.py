from prometheus_client import start_http_server, Counter
import random
import time

# Crear un contador de métricas personalizadas
REQUEST_COUNT = Counter('http_requests_total', 'Total number of HTTP requests')

def process_request():
    """Simula el procesamiento de una solicitud HTTP"""
    REQUEST_COUNT.inc()  # Incrementa el contador de solicitudes
    time.sleep(random.random())

if __name__ == '__main__':
    start_http_server(8000)  # Exponer métricas en el puerto 8000
    while True:
        process_request()