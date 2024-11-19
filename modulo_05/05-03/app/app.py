from flask import Flask, request, jsonify, render_template
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter

app = Flask(__name__)

# Inicializamos PrometheusMetrics para métricas automáticas
metrics = PrometheusMetrics(app)

# Contador personalizado
http_requests_total = Counter('http_requests_total', 'Total number of HTTP requests', ['method'])

def fibonacci(num):
    if num <= 1:
        return 1
    return fibonacci(num - 1) + fibonacci(num - 2)

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@app.route('/', methods=['POST'])
def fibonacci_endpoint():
    data = request.get_json()
    if not data or 'number' not in data:
        return jsonify({'error': 'Por favor proporciona un número.'}), 400

    try:
        number = int(data['number'])
        fibonacci_number = fibonacci(number)
        http_requests_total.labels(method='POST').inc()  # Incrementa la métrica personalizada
        return jsonify({'result': f'El Fibonacci en la posición {number} es: {fibonacci_number}'})
    except ValueError:
        return jsonify({'error': 'El valor proporcionado no es un número válido.'}), 400

# El endpoint /metrics ahora es manejado automáticamente por PrometheusMetrics

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8060)