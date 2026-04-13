import torch
from model import ColorClassifier

LABELS = ["red", "green", "blue", "yellow", "orange", "purple", "pink", "brown", "black", "white"]

if __name__ == "__main__":
    model = ColorClassifier(num_classes=len(LABELS))
    torch.save({
        "state_dict": model.state_dict(),
        "labels": LABELS,
    }, "saved_model.pth")
    print("Saved dummy saved_model.pth")
