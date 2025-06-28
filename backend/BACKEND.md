# PC_Asistencias_Final - Backend

Sistema de reconocimiento facial para control de asistencias en un salón de clases, desarrollado con **FastAPI**, **MySQL** y **InsightFace** para el procesamiento de embeddings faciales.

## 🎯 Funcionalidades Principales

### Gestión de Alumnos
- **Registro de alumnos** con foto, datos personales y embedding facial único
- **Validación de duplicados** por código, correo y rostro
- **Edición y eliminación** de registros de alumnos
- **Consulta de asistencias** por alumno

### Gestión de Sesiones
- **Creación de sesiones** con nombre personalizado
- **Inicialización automática** de asistencias para todos los alumnos
- **Edición y eliminación** de sesiones
- **Finalización de sesiones** para bloquear modificaciones

### Control de Asistencias
- **Reconocimiento facial** para marcar asistencia automáticamente
- **Prevención de asistencias duplicadas** en la misma sesión
- **Generación de reportes PDF** con estadísticas detalladas
- **Consulta de asistencias** por sesión y alumno

## 🔧 Tecnologías Utilizadas

### Backend Framework
- **FastAPI**: Framework web moderno y rápido para Python
- **Uvicorn**: Servidor ASGI para producción

### Base de Datos
- **MySQL**: Base de datos relacional para almacenamiento persistente
- **mysql-connector-python**: Driver oficial para conexión

### Procesamiento de Imágenes
- **InsightFace**: Biblioteca de reconocimiento facial con modelos preentrenados
- **OpenCV**: Procesamiento de imágenes y detección de rostros
- **Pillow**: Manipulación de imágenes
- **NumPy**: Operaciones matemáticas y arrays

### Almacenamiento en la Nube
- **Cloudinary**: Servicio de almacenamiento y gestión de imágenes

### Generación de Reportes
- **ReportLab**: Generación de reportes PDF profesionales

### Utilidades
- **python-multipart**: Manejo de formularios multipart
- **python-dotenv**: Gestión de variables de entorno
- **ONNX Runtime**: Optimización de inferencia de modelos

## 🏗️ Arquitectura del Sistema

### Estructura de Archivos
```
backend/
├── app/
│   ├── main.py                 # API principal con todos los endpoints
│   ├── face_embedding.py       # Lógica de embeddings faciales
│   ├── database.py             # Configuración de conexión MySQL
│   ├── cloudinary_config.py    # Configuración de Cloudinary
│   └── alumnos_img/            # Imágenes temporales (no versionadas)
├── requirements.txt            # Dependencias del proyecto
├── Procfile                    # Configuración para despliegue
└── .gitignore                  # Archivos a ignorar
```

### Endpoints de la API

#### Alumnos
- `POST /alumnos/registrar` - Registrar nuevo alumno con foto
- `GET /alumnos` - Listar todos los alumnos
- `PUT /alumnos/{id}` - Editar alumno existente
- `DELETE /alumnos/{id}` - Eliminar alumno
- `GET /alumnos/{id}/asistencias` - Obtener asistencias de un alumno

#### Sesiones
- `POST /sesiones/crear` - Crear nueva sesión
- `GET /sesiones` - Listar todas las sesiones
- `GET /sesiones/{id}` - Obtener detalles de sesión
- `PUT /sesiones/{id}` - Editar sesión
- `DELETE /sesiones/{id}` - Eliminar sesión
- `POST /sesiones/{id}/finalizar` - Finalizar sesión

#### Asistencias
- `POST /sesiones/{id}/asistencia` - Marcar asistencia por reconocimiento facial
- `GET /sesiones/{id}/reporte-pdf` - Generar reporte PDF de asistencias

#### Utilidades
- `GET /` - Health check de la API
- `GET /test-db` - Test de conexión a base de datos
- `POST /reiniciar-tablas` - Reiniciar todas las tablas (desarrollo)

## 🧠 Algoritmo de Reconocimiento Facial

### Proceso de Registro
1. **Extracción de embedding**: Se utiliza InsightFace para extraer un vector de 512 dimensiones del rostro
2. **Validación de duplicados**: Se compara con embeddings existentes usando similitud coseno
3. **Umbral de registro**: 0.6 (60% de similitud) para evitar duplicados
4. **Almacenamiento**: Embedding se guarda como BLOB en MySQL, imagen en Cloudinary

### Proceso de Reconocimiento
1. **Captura de imagen**: Foto del alumno durante la asistencia
2. **Extracción de embedding**: Mismo proceso que en registro
3. **Comparación**: Similitud coseno con todos los embeddings registrados
4. **Umbral de reconocimiento**: 0.5 (50% de similitud) para marcar asistencia
5. **Validación**: Verificación de que no se haya marcado asistencia previamente

## 🔒 Validaciones y Seguridad

### Validaciones de Negocio
- **Código único**: No permite códigos duplicados
- **Correo único**: No permite correos duplicados
- **Rostro único**: No permite rostros duplicados (similitud > 0.6)
- **Asistencia única**: No permite marcar asistencia dos veces en la misma sesión
- **Sesión activa**: No permite modificar sesiones finalizadas

### Manejo de Errores
- **Mensajes descriptivos**: Errores claros y específicos
- **Códigos HTTP apropiados**: 400 para errores de cliente, 500 para errores de servidor
- **Validación de entrada**: Verificación de tipos y formatos
- **Manejo de excepciones**: Captura y manejo de errores de base de datos y servicios externos

## 🚀 Configuración y Despliegue

### Variables de Entorno Requeridas
```env
# Base de Datos MySQL
MYSQL_HOST=localhost
MYSQL_USER=usuario
MYSQL_PASSWORD=contraseña
MYSQL_PORT=3306
MYSQL_DATABASE=pc_asistencias

# Cloudinary
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
```

### Instalación Local
```bash
# Clonar repositorio
git clone <repo_url>
cd PC_Asistencias_Final/backend

# Crear entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# Ejecutar servidor
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Despliegue en Producción
- **Railway**: Configurado con Procfile para despliegue automático
- **Variables de entorno**: Configuradas en el panel de Railway
- **Base de datos**: MySQL externo (Railway, PlanetScale, etc.)
- **Documentación**: Disponible en `/docs` (Swagger UI)

## 📊 Base de Datos

### Esquema de Tablas
- **alumnos**: Información personal, foto URL, embedding facial
- **sesiones**: Nombre, fecha, estado de finalización
- **asistencias**: Relación entre sesiones y alumnos con estado

### Índices y Optimizaciones
- Índices en campos de búsqueda frecuente
- BLOB para embeddings faciales
- URLs de Cloudinary para imágenes

## 🔗 Integración con Frontend

### CORS Configurado
- Permite todas las origenes en desarrollo
- Configurable para producción
- Headers y métodos permitidos configurados

### Formato de Respuestas
- **Éxito**: `{"success": true, "data": ...}`
- **Error**: `{"success": false, "detail": "mensaje de error"}`
- **Listas**: `{"success": true, "items": [...]}`

## 📈 Métricas y Monitoreo

### Endpoints de Monitoreo
- `/` - Health check básico
- `/test-db` - Verificación de conexión a base de datos
- `/docs` - Documentación interactiva de la API

### Logs y Debugging
- Logs de errores detallados
- Información de depuración en desarrollo
- Manejo de excepciones con contexto

## 🔮 Características Futuras

### Mejoras Planificadas
- **Autenticación JWT**: Sistema de usuarios y roles
- **Webhooks**: Notificaciones en tiempo real
- **Analytics**: Estadísticas avanzadas de asistencia
- **Backup automático**: Respaldo de embeddings y datos
- **Optimización de modelos**: Modelos más precisos y rápidos

### Escalabilidad
- **Caché Redis**: Para embeddings frecuentemente consultados
- **Microservicios**: Separación de responsabilidades
- **Load balancing**: Distribución de carga
- **CDN**: Distribución global de imágenes

---

**Desarrollado con ❤️ para la gestión eficiente de asistencias académicas**
