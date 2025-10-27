from datasets import load_dataset
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from pathlib import Path
from model import ColorClassifier

# === CONFIG ===
MODEL_PATH = Path(__file__).parent / "saved_model.pth"
EPOCHS = 15
BATCH_SIZE = 64
LR = 0.001

# === LOAD DATASET ===
print("📦 Loading dataset from Hugging Face...")
ds = load_dataset("chungimungi/Colors")

label_names = ds["train"].features["label"].names
print(f"Classes found: {label_names}")

# === CUSTOM DATASET ===
class ColorDataset(Dataset):
    def __init__(self, hf_dataset):
        self.data = hf_dataset

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        color = torch.tensor(self.data[idx]["rgb"], dtype=torch.float32) / 255.0
        label = torch.tensor(self.data[idx]["label"], dtype=torch.long)
        return color, label

train_data = ColorDataset(ds["train"])
train_loader = DataLoader(train_data, batch_size=BATCH_SIZE, shuffle=True)

# === MODEL ===
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = ColorClassifier(num_classes=len(label_names)).to(device)
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=LR)

# === TRAIN ===
print("🚀 Training started...")
for epoch in range(EPOCHS):
    total_loss = 0
    for colors, labels in train_loader:
        colors, labels = colors.to(device), labels.to(device)
        optimizer.zero_grad()
        outputs = model(colors)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    print(f"Epoch [{epoch+1}/{EPOCHS}] - Loss: {total_loss/len(train_loader):.4f}")

# === SAVE MODEL ===
torch.save({
    "state_dict": model.state_dict(),
    "labels": label_names
}, MODEL_PATH)
print(f"✅ Model saved to {MODEL_PATH}")
