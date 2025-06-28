import numpy as np
import cv2
from insightface.app import FaceAnalysis
from insightface.model_zoo import model_zoo
from numpy.linalg import norm

# Inicializar el analizador de rostros (modelo preentrenado de InsightFace)
# Se recomienda inicializar una sola vez y reutilizar
face_app = FaceAnalysis(name='buffalo_l', providers=['CPUExecutionProvider'])
face_app.prepare(ctx_id=0, det_size=(224, 224))

def get_face_embedding(image: np.ndarray) -> np.ndarray:
    """
    Extrae el embedding facial de una imagen (asume que el rostro está centrado).
    Retorna None si no se detecta rostro.
    """
    faces = face_app.get(image)
    if not faces:
        return None
    # Tomar el embedding del rostro más grande
    faces = sorted(faces, key=lambda f: f.bbox[2]*f.bbox[3], reverse=True)
    return faces[0].embedding

def cosine_similarity(emb1: np.ndarray, emb2: np.ndarray) -> float:
    """
    Calcula la similitud coseno entre dos embeddings.
    """
    return np.dot(emb1, emb2) / (norm(emb1) * norm(emb2))

def euclidean_distance(emb1: np.ndarray, emb2: np.ndarray) -> float:
    """
    Calcula la distancia euclidiana entre dos embeddings.
    """
    return norm(emb1 - emb2) 