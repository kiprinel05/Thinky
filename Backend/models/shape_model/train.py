import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from pathlib import Path
from model import ShapeClassifier

# === CONFIG ===
DATA_DIR = Path(r"C:\Users\Asus\Desktop\Thinky\Backend\Resources\1. Shapes Dataset\geometric shapes dataset")
MODEL_PATH = Path(__file__).parent / "saved_model.pth"
EPOCHS = 10
BATCH_SIZE = 32
LR = 0.001

# === TRANSFORMĂRI ===
transform = transforms.Compose([
    transforms.Resize((128, 128)),
    transforms.ToTensor(),
])

# === DATASET ===
dataset = datasets.ImageFolder(root=str(DATA_DIR), transform=transform)
train_loader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=True)

print(f"Classes found: {dataset.classes}")

# === MODEL ===
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = ShapeClassifier(num_classes=len(dataset.classes)).to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=LR)

# === TRAIN LOOP ===
for epoch in range(EPOCHS):
    running_loss = 0.0
    for inputs, labels in train_loader:
        inputs, labels = inputs.to(device), labels.to(device)
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        running_loss += loss.item()

    print(f"Epoch [{epoch+1}/{EPOCHS}] - Loss: {running_loss/len(train_loader):.4f}")

# === SAVE MODEL ===
torch.save(model.state_dict(), MODEL_PATH)
print(f"✅ Model saved to: {MODEL_PATH}")
