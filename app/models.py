import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import transforms, datasets
from torch.utils.data import DataLoader
from PIL import Image
import os

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

# Transformaciones para imágenes (con data augmentation para entrenamiento)
train_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(20),
    transforms.ColorJitter(brightness=0.3, contrast=0.3),
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

def train_cnn_model(image_dir, model_path, epochs=10, lr=0.001):
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
