import os
from dotenv import load_dotenv
import mysql.connector

# Cargar variables de entorno desde el archivo .env
load_dotenv()

def get_connection():
    # Prints de depuración eliminados para producción
    connection = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        port=os.getenv("MYSQL_PORT"),
        database=os.getenv("MYSQL_DATABASE")
    )
    return connection