# Numbers mission — trained models

This folder holds the **`digit_cnn.pt`** weights file used by
`DigitRecognitionService` to recognize hand-drawn digits (0–9) on the canvas.

The file is **not checked into git** (see `.gitignore`); each developer
generates it locally.

## Train the model

From the `Backend/` directory:

```bash
# MNIST only — quick (~3 min on CPU, < 1 min on GPU)
python -m scripts.train_digit_recognizer
```

Or, for a more robust model that's better at the messy hand-drawing
children produce, augment MNIST with the Kaggle
[Handwritten Digits Dataset (not in MNIST)](https://www.kaggle.com/datasets/jcprogjava/handwritten-digits-dataset-not-in-mnist)
by jcprogjava:

1. Download the dataset zip from Kaggle and extract it.
2. Make sure the extracted folder contains sub-folders `0/`, `1/`, ..., `9/`
   (one per digit class). If the zip wraps everything in a parent folder,
   pass the inner folder path.
3. Run:

```bash
python -m scripts.train_digit_recognizer --kaggle path/to/extracted/dataset
```

After training you should see a line like:

```
✓ Saved model to .../Backend/features/numbers/models/digit_cnn.pt (1234.5 KB)
```

The backend picks up the new weights on next startup (and on the next
`recognize_truth` call thanks to lazy loading).

## What if the file isn't here?

`DigitRecognitionService` falls back to a small geometry-based heuristic so
the mission keeps working — but the heuristic is intentionally weak and
only there as a last resort. **For real use, train the CNN.**
