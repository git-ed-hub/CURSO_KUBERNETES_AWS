from flask import Flask, request, render_template, redirect, url_for, flash
import mysql.connector

app = Flask(__name__)
app.secret_key = 'aprobado'

# Configuración de la conexión a la base de datos
db_config = {
    'host': "XXXX",
    'user': "root",
    'password': ""
}

# Configuración de la base de datos a usar
database_name = "payment"

def setup_database_and_table():
    # Conectar al servidor MySQL sin especificar la base de datos
    db = mysql.connector.connect(**db_config)
    cursor = db.cursor()

    # Crear la base de datos si no existe
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS {database_name}")

    # Conectarse a la base de datos recién creada o existente
    db.database = database_name

    # Crear la tabla 'payments' si no existe
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS payments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name_on_card VARCHAR(100),
            card_number VARCHAR(16),
            expiry_month INT,
            expiry_year INT,
            security_code VARCHAR(4),
            payment_method VARCHAR(20)
        )
    """)

    cursor.close()
    db.close()

# Ejecutar la configuración de la base de datos y la tabla al iniciar la aplicación
setup_database_and_table()

# Conectar a la base de datos 'payment' después de crearla
db = mysql.connector.connect(**db_config, database=database_name)


@app.route('/')
def index():
    cursor = db.cursor()
    cursor.execute("SELECT COUNT(*) FROM payments")  # Ajusta "payments" al nombre de tu tabla
    count = cursor.fetchone()[0]  # Obtiene el número total de registros
    cursor.close()
    return render_template('index.html', count=count)

@app.route('/process_payment', methods=['POST'])
def process_payment():
    # Captura los datos del formulario
    name_on_card = request.form.get('name_on_card')
    card_number = request.form.get('card_number')
    expiry_month = request.form.get('expiry_month')
    expiry_year = request.form.get('expiry_year')
    security_code = request.form.get('security_code')
    payment_method = request.form.get('payment_method')

    # Inserta los datos en la base de datos
    cursor = db.cursor()
    sql = """
        INSERT INTO payments (name_on_card, card_number, expiry_month, expiry_year, security_code, payment_method)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    values = (name_on_card, card_number, expiry_month, expiry_year, security_code, payment_method)
    cursor.execute(sql, values)
    db.commit()
    cursor.close()

    flash("Pago aprobado")
    # Muestra el mensaje de pago aprobado
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)