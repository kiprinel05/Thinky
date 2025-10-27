import torch
from model import ShapeClassifier

if __name__ == "__main__":
    model = ShapeClassifier(num_classes=4)
    torch.save(model.state_dict(), "saved_model.pth")
    print("Saved dummy saved_model.pth")
