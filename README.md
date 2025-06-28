# PC_Asistencias_Final

Sistema de reconocimiento facial para control de asistencias en un salón de clases, usando FastAPI, MySQL y embeddings faciales con InsightFace.

## 🚀 ¿Qué hace este sistema?
- Registro de alumnos con foto y datos únicos (código, correo, rostro).
- Creación de sesiones y pase de asistencia por reconocimiento facial.
- Generación de reportes de asistencia.
- Validaciones para evitar duplicados y asistencias repetidas.

## 🔍 ¿Cómo funciona el reconocimiento facial?
- Utiliza **InsightFace** para extraer un embedding facial robusto de cada foto.
- Al registrar un alumno, se guarda el embedding en la base de datos.
- Al pasar asistencia, se compara el embedding de la foto subida con los embeddings registrados usando **similitud coseno**.
- Si la similitud supera el umbral (0.6 para registro, 0.5 para asistencia), se reconoce al alumno.

## 🛡️ Validaciones implementadas
- No permite registrar dos alumnos con el mismo código, correo o rostro.
- No permite marcar asistencia dos veces para el mismo alumno en la misma sesión.
- Mensajes claros para cada caso de error o duplicado.

## 📦 Estructura del proyecto
```
PC_Asistencias_Final/
│
├── app/
│   ├── main.py               # API principal (FastAPI)
│   ├── face_embedding.py     # Extracción de embeddings y similitud
│   ├── database.py           # Conexión MySQL
│   ├── alumnos_img/          # Imágenes de alumnos (no subir a git)
│   └── __pycache__/          # (ignorable, puedes borrar su contenido si hay archivos de módulos eliminados)
│
├── requirements.txt          # Dependencias
├── README.md                 # Este archivo
├── .gitignore                # Ignora venv, imágenes, caché
├── .git/                     # Carpeta de git
```

## ⚙️ Instalación y uso
1. Clona el repositorio y entra a la carpeta:
   ```bash
   git clone <repo_url>
   cd PC_Asistencias_Final
   ```
2. (Opcional) Crea y activa un entorno virtual (recomendado, pero puedes usar Python 3.13.3 directamente).
3. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```
4. Configura tus variables de entorno para la base de datos MySQL (puedes usar un archivo `.env`).
5. Inicia el servidor:
   ```bash
   uvicorn app.main:app --reload
   ```
6. Accede a la documentación interactiva:
   [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

## 🛠️ Notas
- No subas la carpeta `alumnos_img/` ni el entorno virtual a GitHub.
- Puedes borrar el contenido de `__pycache__/` si hay archivos de módulos eliminados o versiones antiguas.
- El sistema está listo para producción y despliegue en cualquier servidor compatible con **Python 3.13.3**.

## 📱 Integración futura
El backend está preparado para ser consumido por una app móvil (por ejemplo, Flutter) mediante los endpoints REST.

---

**¡Listo para usar, probar y escalar!**
