import torch
from model import ColorClassifier

if __name__ == "__main__":
    model = ColorClassifier(num_classes=5)
    torch.save(model.state_dict(), "saved_model.pth")
    print("Saved dummy saved_model.pth")
