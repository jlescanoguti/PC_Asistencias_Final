import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import transforms, datasets
from torch.utils.data import DataLoader
from PIL import Image
import os
import cv2
import numpy as np
from skimage.metrics import structural_similarity as ssim
from collections import defaultdict

# Modelo CNN sencillo
class SimpleCNN(nn.Module):
    def __init__(self, num_classes):
        super(SimpleCNN, self).__init__()
        self.conv1 = nn.Conv2d(3, 16, 3, padding=1)
        self.pool = nn.MaxPool2d(2, 2)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)
        self.fc1 = nn.Linear(32 * 56 * 56, 128)
        self.fc2 = nn.Linear(128, num_classes)
        self.relu = nn.ReLU()

    def forward(self, x):
        x = self.pool(self.relu(self.conv1(x)))
        x = self.pool(self.relu(self.conv2(x)))
        x = x.view(x.size(0), -1)
        x = self.relu(self.fc1(x))
        x = self.fc2(x)
        return x

# Transformaciones para imágenes (data augmentation agresivo para entrenamiento)
train_transform = transforms.Compose([
    transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(30),
    transforms.ColorJitter(brightness=0.5, contrast=0.5, saturation=0.5, hue=0.2),
    transforms.RandomAffine(degrees=0, translate=(0.1, 0.1), shear=10),
    transforms.GaussianBlur(3, sigma=(0.1, 2.0)),
    transforms.ToTensor(),
])

# Transformación para validación/predicción (sin augmentation)
predict_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
])

def get_cnn_model(num_classes):
    return SimpleCNN(num_classes)

# Entrenamiento incremental del modelo CNN
# image_dir: carpeta con imágenes (nombre archivo = código alumno)
# model_path: ruta para guardar el modelo
# epochs: número de épocas de entrenamiento
# lr: learning rate

def train_cnn_model(image_dir, model_path, epochs=40, lr=0.001):
    # Crear dataset con data augmentation
    dataset = datasets.ImageFolder(
        image_dir,
        transform=train_transform
    )
    dataloader = DataLoader(dataset, batch_size=4, shuffle=True)
    num_classes = len(dataset.classes)
    model = get_cnn_model(num_classes)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)
    # Entrenamiento
    model.train()
    for epoch in range(epochs):
        for inputs, labels in dataloader:
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
    # Guardar modelo y clases
    torch.save({
        'model_state_dict': model.state_dict(),
        'classes': dataset.classes
    }, model_path)
    return model, dataset.classes

# Predicción con el modelo CNN
# Devuelve el código del alumno predicho y la probabilidad

def predict_cnn_model(image_path, model_path):
    checkpoint = torch.load(model_path, map_location=torch.device('cpu'))
    classes = checkpoint['classes']
    num_classes = len(classes)
    model = get_cnn_model(num_classes)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    image = Image.open(image_path).convert('RGB')
    tensor = predict_transform(image)
    if not isinstance(tensor, torch.Tensor):
        raise Exception('El resultado de transform no es un tensor de PyTorch')
    input_tensor = tensor.unsqueeze(0)
    with torch.no_grad():
        outputs = model(input_tensor)
        probs = torch.softmax(outputs, dim=1)
        prob, pred = torch.max(probs, 1)
        codigo_predicho = classes[pred.item()]
        return codigo_predicho, prob.item()

# Función para comparación directa usando SSIM
def compare_images_ssim(img1_path, img2_path):
    # Cargar imágenes
    img1 = cv2.imread(img1_path)
    img2 = cv2.imread(img2_path)
    if img1 is None or img2 is None:
        return 0.0
    # Redimensionar a mismo tamaño
    img1 = cv2.resize(img1, (224, 224))
    img2 = cv2.resize(img2, (224, 224))
    # Convertir a escala de grises
    gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
    gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
    # Calcular SSIM
    similarity = ssim(gray1, gray2)
    return similarity

# Función para comparación usando histogramas de color
def compare_images_histogram(img1_path, img2_path):
    # Cargar imágenes
    img1 = cv2.imread(img1_path)
    img2 = cv2.imread(img2_path)
    if img1 is None or img2 is None:
        return 0.0
    # Redimensionar
    img1 = cv2.resize(img1, (224, 224))
    img2 = cv2.resize(img2, (224, 224))
    # Calcular histogramas
    hist1 = cv2.calcHist([img1], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
    hist2 = cv2.calcHist([img2], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
    # Normalizar histogramas
    cv2.normalize(hist1, hist1, 0, 1, cv2.NORM_MINMAX)
    cv2.normalize(hist2, hist2, 0, 1, cv2.NORM_MINMAX)
    # Calcular correlación
    similarity = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)
    return similarity

# Función principal para comparación directa (solo SSIM)
def direct_image_comparison(test_image_path, alumnos_img_dir):
    best_match = None
    best_score = -1
    best_method = None
    
    # Iterar sobre todas las carpetas de alumnos
    for codigo in os.listdir(alumnos_img_dir):
        alumno_dir = os.path.join(alumnos_img_dir, codigo)
        if os.path.isdir(alumno_dir):
            # Buscar imagen del alumno
            for filename in os.listdir(alumno_dir):
                if filename.endswith('.jpg') or filename.endswith('.png'):
                    alumno_img_path = os.path.join(alumno_dir, filename)
                    # Comparar usando solo SSIM
                    ssim_score = compare_images_ssim(test_image_path, alumno_img_path)
                    current_score = ssim_score
                    current_method = 'SSIM'
                    if current_score > best_score:
                        best_score = current_score
                        best_match = codigo
                        best_method = current_method
    return best_match, best_score, best_method
