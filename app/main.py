from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from app.database import get_connection
import numpy as np
import cv2
import io
from PIL import Image
from fastapi.responses import StreamingResponse
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import io as sysio
import os
from app.face_embedding import get_face_embedding, cosine_similarity
import cloudinary
import cloudinary.uploader
from app.cloudinary_config import cloudinary
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permitir todos los orígenes (ajusta en producción si lo deseas)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    # Validar que no exista un alumno con el mismo código o correo
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, codigo, correo, embedding FROM alumnos")
        alumnos = cursor.fetchall()
        # Convertir los bytes a una imagen de OpenCV
        image = Image.open(io.BytesIO(foto_bytes)).convert("RGB")
        image_np = np.array(image)
        image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
        # Extraer embedding facial
        embedding = get_face_embedding(image_cv)
        if embedding is None:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="No se pudo extraer el embedding facial. Asegúrate de que el rostro esté bien visible y centrado.")
        embedding_bytes = embedding.astype(np.float32).tobytes()
        # Validar código y correo
        for alumno in alumnos:
            _, cod, mail, emb_blob = alumno
            if cod == codigo or mail == correo:
                cursor.close()
                conn.close()
                raise HTTPException(status_code=400, detail="Ya existe un alumno con ese código o correo.")
            # Validar rostro duplicado
            if emb_blob is not None:
                emb_np = np.frombuffer(emb_blob, dtype=np.float32)
                if emb_np.shape[0] == embedding.shape[0]:
                    score = cosine_similarity(embedding, emb_np)
                    if score > 0.6:
                        cursor.close()
                        conn.close()
                        raise HTTPException(status_code=400, detail=f"El rostro ya está registrado para otro alumno (código: {cod}, correo: {mail})")
        cursor.close()
        conn.close()
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    # Subir la imagen a Cloudinary
    upload_result = cloudinary.uploader.upload(foto_bytes, folder=f"alumnos/{codigo}")
    url_imagen = upload_result["secure_url"]
    # Guardar en la base de datos (URL de la imagen y embedding)
    try:
        conn = get_connection()
        cursor = conn.cursor()
        sql = """
            INSERT INTO alumnos (nombre, apellido, codigo, correo, foto, embedding)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (nombre, apellido, codigo, correo, url_imagen, embedding_bytes))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Alumno registrado correctamente con embedding facial y foto en la nube"}
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
        # Validar que no exista una sesión con el mismo nombre
        cursor.execute("SELECT id FROM sesiones WHERE nombre = %s", (nombre,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Ya existe una sesión con ese nombre.")
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
        finalizada = sesion[0] if isinstance(sesion, (tuple, list)) and len(sesion) > 0 else sesion.get('finalizada') if isinstance(sesion, dict) else None
        if finalizada:
            cursor.close()
            conn.close()
            return {"success": False, "message": "No se puede pasar asistencia. La sesión ya está finalizada."}
        # Leer la foto como bytes
        foto_bytes = await foto.read()
        image = Image.open(io.BytesIO(foto_bytes)).convert("RGB")
        image_np = np.array(image)
        image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
        # Extraer embedding facial de la imagen de prueba
        test_embedding = get_face_embedding(image_cv)
        if test_embedding is None:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="No se pudo extraer el embedding facial de la imagen de asistencia.")
        # Buscar todos los alumnos y comparar embeddings
        cursor.execute("SELECT id, nombre, codigo, embedding FROM alumnos")
        alumnos = cursor.fetchall()
        best_score = -1
        best_alumno = None
        for alumno in alumnos:
            alumno_id, nombre, codigo, emb_blob = alumno
            if emb_blob is None:
                continue
            emb_np = np.frombuffer(emb_blob, dtype=np.float32)
            if emb_np.shape[0] != test_embedding.shape[0]:
                continue
            score = cosine_similarity(test_embedding, emb_np)
            if score > best_score:
                best_score = score
                best_alumno = (alumno_id, nombre, codigo)
        # Umbral de similitud (ajustable, típico: 0.5-0.6)
        if best_score < 0.5 or best_alumno is None:
            cursor.close()
            conn.close()
            return {"success": False, "message": "No se pudo identificar al alumno con suficiente confianza."}
        alumno_id, nombre, codigo = best_alumno
        # Validar si ya tiene asistencia registrada
        cursor.execute('''SELECT estado FROM asistencias WHERE sesion_id = %s AND alumno_id = %s''', (sesion_id, alumno_id))
        asistencia = cursor.fetchone()
        if asistencia and asistencia[0] == 'Asistió':
            cursor.close()
            conn.close()
            return {"success": False, "message": "La asistencia ya fue registrada para este alumno en esta sesión."}
        # Marcar asistencia
        cursor.execute('''
            UPDATE asistencias SET estado = 'Asistió'
            WHERE sesion_id = %s AND alumno_id = %s
        ''', (sesion_id, alumno_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "success": True,
            "message": "Asistencia registrada con embedding facial",
            "alumno": {
                "id": alumno_id,
                "nombre": nombre,
                "codigo": codigo,
                "similitud": float(best_score)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/sesiones/{sesion_id}/reporte-pdf")
def generar_reporte_pdf(sesion_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        # Verificar si la sesión está finalizada
        cursor.execute("SELECT nombre, fecha, finalizada FROM sesiones WHERE id = %s", (sesion_id,))
        sesion = cursor.fetchone()
        if not sesion:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="Sesión no encontrada")
        finalizada = sesion['finalizada'] if isinstance(sesion, dict) else sesion[2]
        if not finalizada:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Solo se puede descargar el PDF de sesiones finalizadas.")
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

@app.put("/alumnos/{alumno_id}")
async def editar_alumno(
    alumno_id: int,
    nombre: str = Form(None),
    apellido: str = Form(None),
    codigo: str = Form(None),
    correo: str = Form(None),
    foto: UploadFile = File(None)
):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        campos = []
        valores = []
        if nombre is not None:
            campos.append("nombre=%s")
            valores.append(nombre)
        if apellido is not None:
            campos.append("apellido=%s")
            valores.append(apellido)
        if codigo is not None:
            campos.append("codigo=%s")
            valores.append(codigo)
        if correo is not None:
            campos.append("correo=%s")
            valores.append(correo)
        if foto is not None:
            foto_bytes = await foto.read()
            image = Image.open(io.BytesIO(foto_bytes)).convert("RGB")
            image_np = np.array(image)
            image_cv = cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR)
            # Extraer embedding facial
            embedding = get_face_embedding(image_cv)
            if embedding is None:
                raise HTTPException(status_code=400, detail="No se pudo extraer el embedding facial de la nueva foto.")
            embedding_bytes = embedding.astype(np.float32).tobytes()
            # Subir la nueva imagen a Cloudinary
            upload_result = cloudinary.uploader.upload(foto_bytes, folder=f"alumnos/{codigo if codigo is not None else alumno_id}")
            url_imagen = upload_result["secure_url"]
            campos.append("foto=%s")
            valores.append(url_imagen)
            campos.append("embedding=%s")
            valores.append(embedding_bytes)
        if not campos:
            cursor.close()
            conn.close()
            return {"success": False, "message": "No se enviaron datos para actualizar"}
        sql = f"UPDATE alumnos SET {', '.join(campos)} WHERE id=%s"
        valores.append(alumno_id)
        cursor.execute(sql, tuple(valores))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Alumno actualizado correctamente con embedding facial y foto en la nube"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/alumnos/{alumno_id}")
def eliminar_alumno(alumno_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Eliminar asistencias del alumno
        cursor.execute("DELETE FROM asistencias WHERE alumno_id = %s", (alumno_id,))
        # Eliminar el alumno
        cursor.execute("DELETE FROM alumnos WHERE id = %s", (alumno_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Alumno eliminado correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.put("/sesiones/{sesion_id}")
def editar_sesion(sesion_id: int, nombre: str = Form(...)):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Verificar si la sesión está finalizada
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
            return {"success": False, "message": "No se puede editar una sesión finalizada"}
        cursor.execute("UPDATE sesiones SET nombre = %s WHERE id = %s", (nombre, sesion_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Sesión actualizada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.delete("/sesiones/{sesion_id}")
def eliminar_sesion(sesion_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        # Eliminar asistencias de la sesión
        cursor.execute("DELETE FROM asistencias WHERE sesion_id = %s", (sesion_id,))
        # Eliminar la sesión
        cursor.execute("DELETE FROM sesiones WHERE id = %s", (sesion_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": "Sesión eliminada correctamente"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/alumnos/{alumno_id}/asistencias")
def listar_asistencias_alumno(alumno_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT s.id as sesion_id, s.nombre as sesion_nombre, s.fecha, s.finalizada, a.estado
            FROM sesiones s
            JOIN asistencias a ON s.id = a.sesion_id
            WHERE a.alumno_id = %s
            ORDER BY s.fecha DESC
        ''', (alumno_id,))
        asistencias = cursor.fetchall()
        cursor.close()
        conn.close()
        return {"success": True, "asistencias": asistencias}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/alumnos")
def listar_alumnos():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, nombre, apellido, codigo, correo, foto FROM alumnos ORDER BY id ASC")
        alumnos = cursor.fetchall()
        cursor.close()
        conn.close()
        return {"success": True, "alumnos": alumnos}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
