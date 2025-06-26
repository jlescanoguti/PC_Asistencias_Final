from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from app.database import get_connection
import numpy as np
import cv2
import io
from PIL import Image
import torch
import torchvision.transforms as transforms
from torchvision.models import resnet18
from fastapi.responses import StreamingResponse
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import io as sysio

app = FastAPI()

# Inicializar modelo ResNet18 preentrenado (sin la última capa)
resnet_model = resnet18(pretrained=True)
resnet_model.eval()
# Quitar la última capa (fc) para obtener el embedding
resnet_model = torch.nn.Sequential(*list(resnet_model.children())[:-1])

# Transformaciones para preprocesar la imagen
preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

@app.get("/")
def read_root():
    return {"message": "API de Asistencias funcionando"}

@app.get("/test-db")
def test_db():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT DATABASE();")
        db = cursor.fetchone()
        cursor.close()
        conn.close()
        return {"success": True, "database": db[0]}
    except Exception as e:
        return {"success": False, "error": str(e)}

@app.post("/alumnos/registrar")
async def registrar_alumno(
    nombre: str = Form(...),
    apellido: str = Form(...),
    codigo: str = Form(...),
    correo: str = Form(...),
    foto: UploadFile = File(...)
):
    # Leer la foto como bytes
    foto_bytes = await foto.read()

    # Convertir los bytes a una imagen de OpenCV
    image = Image.open(io.BytesIO(foto_bytes)).convert("RGB")
    image_np = np.array(image)
    image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)

    # Cargar el clasificador Haar
    cascade_path = "models/haarcascade_frontalface_default.xml"
    face_cascade = cv2.CascadeClassifier(cascade_path)

    # Detectar rostros
    faces = face_cascade.detectMultiScale(image_cv, scaleFactor=1.1, minNeighbors=5)

    if len(faces) == 0:
        raise HTTPException(status_code=400, detail="No se detectó ningún rostro en la imagen.")

    # Tomar el primer rostro detectado
    (x, y, w, h) = faces[0]
    rostro = image_cv[y:y+h, x:x+w]

    # Convertir el rostro recortado a bytes para guardar (opcional)
    _, buffer = cv2.imencode('.jpg', rostro)
    rostro_bytes = buffer.tobytes()

    # Obtener el embedding facial usando ResNet18
    rostro_rgb = cv2.cvtColor(rostro, cv2.COLOR_BGR2RGB)
    rostro_pil = Image.fromarray(rostro_rgb)
    rostro_tensor = preprocess(rostro_pil)
    print('Tipo de rostro_tensor:', type(rostro_tensor))  # Depuración
    if not isinstance(rostro_tensor, torch.Tensor):
        raise HTTPException(status_code=500, detail="Error al convertir la imagen a tensor")
    rostro_tensor = torch.unsqueeze(rostro_tensor, 0)  # Añadir batch dimension
    with torch.no_grad():
        embedding_tensor = resnet_model(rostro_tensor)
    embedding_np = embedding_tensor.squeeze().numpy()  # (512,)
    embedding_bytes = embedding_np.tobytes()

    try:
        conn = get_connection()
        cursor = conn.cursor()
        sql = """
            INSERT INTO alumnos (nombre, apellido, codigo, correo, foto, embedding)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (nombre, apellido, codigo, correo, rostro_bytes, embedding_bytes))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Alumno registrado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/reiniciar-tablas")
def reiniciar_tablas():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Borrar datos de asistencias primero por las claves foráneas
        cursor.execute("DELETE FROM asistencias;")
        cursor.execute("ALTER TABLE asistencias AUTO_INCREMENT = 1;")
        cursor.execute("DELETE FROM sesiones;")
        cursor.execute("ALTER TABLE sesiones AUTO_INCREMENT = 1;")
        cursor.execute("DELETE FROM alumnos;")
        cursor.execute("ALTER TABLE alumnos AUTO_INCREMENT = 1;")
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Tablas reiniciadas correctamente"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/sesiones/crear")
def crear_sesion(nombre: str = Form(...)):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Obtener todos los alumnos
        cursor.execute("SELECT id FROM alumnos")
        alumnos = cursor.fetchall()
        if not alumnos:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="No hay alumnos registrados. No se puede crear la sesión.")
        # Crear la sesión
        sql_sesion = "INSERT INTO sesiones (nombre) VALUES (%s)"
        cursor.execute(sql_sesion, (nombre,))
        sesion_id = cursor.lastrowid
        # Registrar a todos los alumnos como 'Faltó' en asistencias
        sql_asistencia = "INSERT INTO asistencias (sesion_id, alumno_id, estado) VALUES (%s, %s, 'Faltó')"
        alumno_ids = []
        for row in alumnos:
            if isinstance(row, tuple) and isinstance(row[0], int):
                alumno_ids.append(row[0])
        for alumno_id in alumno_ids:
            cursor.execute(sql_asistencia, (sesion_id, alumno_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Sesión creada y asistencias inicializadas", "sesion_id": sesion_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/sesiones")
def listar_sesiones():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nombre, fecha, finalizada FROM sesiones ORDER BY fecha DESC")
        sesiones = cursor.fetchall()
        cursor.close()
        conn.close()
        return {"success": True, "sesiones": sesiones}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/sesiones/{sesion_id}")
def detalles_sesion(sesion_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        # Obtener datos de la sesión
        cursor.execute("SELECT id, nombre, fecha, finalizada FROM sesiones WHERE id = %s", (sesion_id,))
        sesion = cursor.fetchone()
        if not sesion:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Sesión no encontrada")
        # Obtener lista de alumnos y su estado de asistencia
        cursor.execute('''
            SELECT a.id as alumno_id, a.nombre, a.apellido, a.codigo, a.correo, asis.estado
            FROM alumnos a
            JOIN asistencias asis ON a.id = asis.alumno_id
            WHERE asis.sesion_id = %s
        ''', (sesion_id,))
        alumnos = cursor.fetchall()
        cursor.close()
        conn.close()
        return {"success": True, "sesion": sesion, "alumnos": alumnos}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/sesiones/{sesion_id}/finalizar")
def finalizar_sesion(sesion_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Verificar si la sesión existe
        cursor.execute("SELECT finalizada FROM sesiones WHERE id = %s", (sesion_id,))
        sesion = cursor.fetchone()
        if not sesion:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Sesión no encontrada")
        finalizada = sesion[0] if isinstance(sesion, (tuple, list)) else sesion['finalizada']
        if finalizada:
            cursor.close()
            conn.close()
            return {"success": False, "message": "La sesión ya está finalizada"}
        # Marcar la sesión como finalizada
        cursor.execute("UPDATE sesiones SET finalizada = TRUE WHERE id = %s", (sesion_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Sesión finalizada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/sesiones/{sesion_id}/asistencia")
async def pasar_asistencia(sesion_id: int, foto: UploadFile = File(...)):
    try:
        # Verificar si la sesión está finalizada
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT finalizada FROM sesiones WHERE id = %s", (sesion_id,))
        sesion = cursor.fetchone()
        if not sesion:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Sesión no encontrada")
        finalizada = sesion[0] if isinstance(sesion, (tuple, list)) else sesion['finalizada']
        if finalizada:
            cursor.close()
            conn.close()
            return {"success": False, "message": "No se puede pasar asistencia. La sesión ya está finalizada."}
        cursor.close()
        conn.close()
        # Leer la foto como bytes
        foto_bytes = await foto.read()
        # Convertir los bytes a una imagen de OpenCV
        image = Image.open(io.BytesIO(foto_bytes)).convert("RGB")
        image_np = np.array(image)
        image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
        # Cargar el clasificador Haar
        cascade_path = "models/haarcascade_frontalface_default.xml"
        face_cascade = cv2.CascadeClassifier(cascade_path)
        # Detectar rostros
        faces = face_cascade.detectMultiScale(image_cv, scaleFactor=1.1, minNeighbors=5)
        if len(faces) == 0:
            raise HTTPException(status_code=400, detail="No se detectó ningún rostro en la imagen.")
        # Tomar el primer rostro detectado
        (x, y, w, h) = faces[0]
        rostro = image_cv[y:y+h, x:x+w]
        # Obtener el embedding facial usando ResNet18
        rostro_rgb = cv2.cvtColor(rostro, cv2.COLOR_BGR2RGB)
        rostro_pil = Image.fromarray(rostro_rgb)
        rostro_tensor = preprocess(rostro_pil)
        if not isinstance(rostro_tensor, torch.Tensor):
            raise HTTPException(status_code=500, detail="Error al convertir la imagen a tensor")
        rostro_tensor = torch.unsqueeze(rostro_tensor, 0)
        with torch.no_grad():
            embedding_tensor = resnet_model(rostro_tensor)
        embedding_np = embedding_tensor.squeeze().numpy()  # (512,)
        # Buscar alumnos de la sesión y comparar embeddings
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT a.id, a.nombre, a.codigo, a.embedding
            FROM alumnos a
            JOIN asistencias asis ON a.id = asis.alumno_id
            WHERE asis.sesion_id = %s
        ''', (sesion_id,))
        alumnos = cursor.fetchall()
        min_dist = float('inf')
        alumno_identificado = None
        umbral = 0.7  # Puedes ajustar este valor según pruebas
        for alumno in alumnos:
            alumno_id, nombre, codigo, embedding_bytes = alumno
            if not isinstance(embedding_bytes, (bytes, bytearray)):
                continue
            alumno_embedding = np.frombuffer(embedding_bytes, dtype=np.float32)
            if alumno_embedding.shape != embedding_np.shape:
                continue
            dist = np.linalg.norm(embedding_np - alumno_embedding)
            if dist < min_dist:
                min_dist = dist
                alumno_identificado = (alumno_id, nombre, codigo)
        if alumno_identificado and min_dist < umbral:
            # Marcar asistencia como 'Asistió'
            alumno_id_raw = alumno_identificado[0]
            sesion_id_raw = sesion_id
            # Solo permite int, str o float para conversión segura
            if not isinstance(alumno_id_raw, (int, str, float)) or not isinstance(sesion_id_raw, (int, str, float)):
                cursor.close()
                conn.close()
                raise HTTPException(status_code=500, detail="ID de alumno o sesión no convertible a entero")
            try:
                alumno_id_final = int(alumno_id_raw)
                sesion_id_final = int(sesion_id_raw)
            except Exception:
                cursor.close()
                conn.close()
                raise HTTPException(status_code=500, detail="ID de alumno o sesión no convertible a entero")
            cursor.execute('''
                UPDATE asistencias SET estado = 'Asistió'
                WHERE sesion_id = %s AND alumno_id = %s
            ''', (sesion_id_final, alumno_id_final))
            conn.commit()
            cursor.close()
            conn.close()
            return {
                "success": True,
                "message": "Asistencia registrada",
                "alumno": {
                    "id": alumno_id_final,
                    "nombre": alumno_identificado[1],
                    "codigo": alumno_identificado[2]
                }
            }
        else:
            cursor.close()
            conn.close()
            return {"success": False, "message": "No se pudo identificar al alumno"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/sesiones/{sesion_id}/reporte-pdf")
def generar_reporte_pdf(sesion_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        # Obtener datos de la sesión
        cursor.execute("SELECT nombre, fecha FROM sesiones WHERE id = %s", (sesion_id,))
        sesion = cursor.fetchone()
        if not sesion:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Sesión no encontrada")
        # Obtener lista de alumnos y su estado de asistencia
        cursor.execute('''
            SELECT a.nombre, a.apellido, a.codigo, a.correo, asis.estado
            FROM alumnos a
            JOIN asistencias asis ON a.id = asis.alumno_id
            WHERE asis.sesion_id = %s
        ''', (sesion_id,))
        alumnos = cursor.fetchall()
        cursor.close()
        conn.close()
        # Crear PDF en memoria
        buffer = sysio.BytesIO()
        p = canvas.Canvas(buffer, pagesize=letter)
        width, height = letter
        # Acceso robusto a los campos de sesión
        nombre_sesion = sesion['nombre'] if isinstance(sesion, dict) else str(sesion[0])
        fecha_sesion = sesion['fecha'] if isinstance(sesion, dict) else str(sesion[1])
        p.setFont("Helvetica-Bold", 16)
        p.drawString(50, height - 50, f"Reporte de Asistencia - {nombre_sesion}")
        p.setFont("Helvetica", 12)
        p.drawString(50, height - 70, f"Fecha: {fecha_sesion}")
        # Encabezados de tabla
        y = height - 110
        p.setFont("Helvetica-Bold", 11)
        p.drawString(50, y, "Nombre")
        p.drawString(180, y, "Apellido")
        p.drawString(310, y, "Código")
        p.drawString(400, y, "Correo")
        p.drawString(520, y, "Estado")
        y -= 20
        p.setFont("Helvetica", 10)
        for alumno in alumnos:
            # Acceso robusto a los campos de alumno
            nombre = alumno['nombre'] if isinstance(alumno, dict) else str(alumno[0])
            apellido = alumno['apellido'] if isinstance(alumno, dict) else str(alumno[1])
            codigo = alumno['codigo'] if isinstance(alumno, dict) else str(alumno[2])
            correo = alumno['correo'] if isinstance(alumno, dict) else str(alumno[3])
            estado = alumno['estado'] if isinstance(alumno, dict) else str(alumno[4])
            if y < 50:
                p.showPage()
                y = height - 50
            p.drawString(50, y, str(nombre))
            p.drawString(180, y, str(apellido))
            p.drawString(310, y, str(codigo))
            p.drawString(400, y, str(correo))
            p.drawString(520, y, str(estado))
            y -= 18
        p.save()
        buffer.seek(0)
        return StreamingResponse(buffer, media_type="application/pdf", headers={
            "Content-Disposition": f"attachment; filename=reporte_sesion_{sesion_id}.pdf"
        })
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))