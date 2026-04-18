import torch
import torch.nn as nn
import torch.nn.functional as F


class ColorClassifier(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.fc1 = nn.Linear(3, 64)  # R, G, B
        self.fc2 = nn.Linear(64, 128)
        self.fc3 = nn.Linear(128, num_classes)

    def forward(self, x):
        x = F.relu(self.fc1(x))
        x = F.relu(self.fc2(x))
        return self.fc3(x)


class ShapeClassifier(nn.Module):
    """Legacy 3-class RGB 128×128 shape classifier (kept for backwards compat)."""

    def __init__(self, num_classes=3):
        super().__init__()
        self.conv1 = nn.Conv2d(3, 16, 3, padding=1)
        self.conv2 = nn.Conv2d(16, 32, 3, padding=1)
        self.pool = nn.MaxPool2d(2, 2)
        self.fc1 = nn.Linear(32 * 32 * 32, 128)
        self.fc2 = nn.Linear(128, num_classes)

    def forward(self, x):
        x = self.pool(F.relu(self.conv1(x)))
        x = self.pool(F.relu(self.conv2(x)))
        x = x.view(-1, 32 * 32 * 32)
        x = F.relu(self.fc1(x))
        x = self.fc2(x)
        return x


class HDSShapeClassifier(nn.Module):
    """
    Small CNN trained on the Hand-drawn Shapes (HDS) dataset.

    Input:  1-channel grayscale image, 70×70, values in [0,1], dark strokes on
            light background (same convention as HDS).
    Output: logits over 4 classes — by default ordered alphabetically to match
            torchvision.datasets.ImageFolder sorting:
              ['ellipse', 'other', 'rectangle', 'triangle']

    Architecture: 3 conv blocks → global-avg-pool → 2-layer MLP.
    Total params: ~180k. Fast on CPU (≤5ms per image).
    """

    def __init__(self, num_classes: int = 4, dropout: float = 0.3):
        super().__init__()
        self.features = nn.Sequential(
            # Block 1: 70 → 35
            nn.Conv2d(1, 32, 3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 32, 3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            # Block 2: 35 → 17
            nn.Conv2d(32, 64, 3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.Conv2d(64, 64, 3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            # Block 3: 17 → 8
            nn.Conv2d(64, 128, 3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
        )
        # Global average pooling makes the head independent of small size shifts.
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(dropout),
            nn.Linear(128, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
            nn.Linear(64, num_classes),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)
        x = self.pool(x)
        return self.classifier(x)
