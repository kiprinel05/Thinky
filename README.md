## Missions Overview

Each mission is divided into chapters that teach both AI concepts and basic programming logic using **Python** and **PyTorch** on the backend, and **Flutter** on the frontend.

Below is the full mission structure with goals, Python concepts, and technical implementation details.

---

## Chapter 1 - What is Artificial Intelligence?

### Mission 1 - "Hi, I'm Pixy!"
- **Goal:** Introduce the child to the app and create a personal profile.  
- **Python Concepts:** REST API, data management, JSON serialization, ORM (SQLAlchemy).  
- **How it's done:** Backend receives the user's name, returns a custom message, and saves data in the database.  
- **Technical Notes:** FastAPI endpoints manage user sessions and profiles.

---

### Mission 2 - "What can AI do?"
- **Goal:** Learn basic ideas of what AI can and cannot do.  
- **Python Concepts:** Data structures (lists, dictionaries), quiz logic, JSON data handling.  
- **How it's done:** Backend sends multiple-choice questions, validates answers, and saves the score.  
- **Technical Notes:** Results can be stored for difficulty adjustment later.

---

### Mission 3 - "How does Pixy learn?"
- **Goal:** Explain how AI models learn from examples.  
- **Python Concepts:** Data organization, file storage, simulated training feedback.  
- **How it's done:** User labels simple images (e.g., apple, cat), and the backend "simulates" AI learning from examples.  
- **Technical Notes:** Number of learned examples is tracked for progress visualization.

---

## Chapter 2 - Visual Recognition and Classification

### Mission 1 - "Select all the animals."
- **Goal:** Understand image recognition and classification.  
- **Python Concepts:** PyTorch inference, image preprocessing, model evaluation.  
- **How it's done:** Backend runs inference on selected images using a pretrained PyTorch model (e.g., ResNet).  
- **Technical Notes:** Image normalization and label confidence scoring used for feedback.

---

### Mission 2 - "Find the red objects."
- **Goal:** Identify visual features such as color.  
- **Python Concepts:** OpenCV, HSV color space, pixel processing.  
- **How it's done:** Image converted to HSV; mask for red tones is created and analyzed.  
- **Technical Notes:** Dynamic thresholding for better accuracy across lighting conditions.

---

### Mission 3 - "Group images: fruits, vegetables, toys."
- **Goal:** Practice semantic grouping and categorization.  
- **Python Concepts:** Data mapping, validation logic.  
- **How it's done:** User drags and drops images into categories; backend checks correctness.  
- **Technical Notes:** Time and accuracy are logged for adaptive difficulty.

---

## Chapter 3 - Creative Missions (Drawing and Building)

### Mission 1 - "Draw a blue triangle."
- **Goal:** Enhance creativity and introduce shape recognition.  
- **Python Concepts:** OpenCV, contour detection, color analysis.  
- **How it's done:** Backend analyzes uploaded drawing to detect shape (3 sides) and dominant color (blue).  
- **Technical Notes:** Image sent from Flutter canvas and processed server-side.

---

### Mission 2 - "Color the circle in red."
- **Goal:** Associate instructions with visual results.  
- **Python Concepts:** Shape and color detection.  
- **How it's done:** Backend checks if the drawn area is circular and red.  
- **Technical Notes:** Uses binary masks and average pixel color checks.

---

## Chapter 4 - Language and Semantic Association

### Mission 1 — "Match the word to the correct image."
- **Goal:** Learn to connect words with visual objects.  
- **Python Concepts:** JSON data structures, simple validation.  
- **How it's done:** Backend provides word–image pairs; user selects matches.  
- **Technical Notes:** Selections saved to track vocabulary progress.

---

### Mission 2 - "Describe what you see in the image."
- **Goal:** Practice natural language association.  
- **Python Concepts:** Speech-to-Text, text comparison.  
- **How it's done:** App records voice, converts to text, and checks if key words match labels.  
- **Technical Notes:** Keyword-based matching for flexibility in phrasing.

---

## Chapter 5 - Logic and Cognitive Thinking

### Mission 1 - "Complete the pattern."
- **Goal:** Understand logical sequences and patterns.  
- **Python Concepts:** Lists, conditionals, pattern generation.  
- **How it's done:** Backend sends a visual sequence (shape, color) and checks user's next logical choice.  
- **Technical Notes:** Sequence difficulty scales with progress.

---

### Mission 2 - "Find the object that doesn’t fit."
- **Goal:** Identify outliers (elements that differ from the group).  
- **Python Concepts:** Data comparison, validation logic.  
- **How it's done:** User selects the image that doesn’t belong; backend validates.  
- **Technical Notes:** Similarity metrics can be added later using embeddings.

---

## Chapter 6 - Audio and Sound Missions

### Mission 1 - "Listen to the sound and choose the correct animal."
- **Goal:** Build auditory association with objects.  
- **Python Concepts:** Audio handling, metadata mapping.  
- **How it's done:** Backend serves audio file; user selects matching image.  
- **Technical Notes:** Audio hosted via secure storage (Firebase/S3) with metadata labels.

---

### Mission 2 - "Repeat the word you hear."
- **Goal:** Practice pronunciation and recognition.  
- **Python Concepts:** Speech recognition, string similarity.  
- **How it's done:** User repeats a word, backend transcribes and compares similarity.  
- **Technical Notes:** Use basic phonetic or textual distance metrics.

---

## Chapter 7 - Emotion and Empathy

### Mission 1 - "How do you feel today?"
- **Goal:** Introduce emotional awareness in interaction.  
- **Python Concepts:** State management, data persistence.  
- **How it's done:** User selects an emotion; backend saves it for tone adaptation.  
- **Technical Notes:** Stored emotions influence dialogue style or feedback tone.

---

### Mission 2 - "Show an image that makes you happy."
- **Goal:** Connect emotions with visual perception.  
- **Python Concepts:** Image tagging, metadata labeling.  
- **How it's done:** User uploads or selects an image; backend stores the emotional label.  
- **Technical Notes:** Optional: sentiment detection via facial expression analysis.

---

## Chapter 8 - How AI Learns

### Mission 1 - "Help Pixy learn fruits."
- **Goal:** Demonstrate dataset creation and training data labeling.  
- **Python Concepts:** File I/O, dataset management, labeling.  
- **How it's done:** User labels fruit images; backend stores them as structured dataset.  
- **Technical Notes:** Progress shown as AI "learning" new items.

---

### Mission 2 - "What if we show wrong images?"
- **Goal:** Explain data bias and errors in AI training.  
- **Python Concepts:** Error logging, dataset validation.  
- **How it's done:** User labels some images incorrectly; Professor explains model bias.  
- **Technical Notes:** Store wrong labels to illustrate model confusion.

---

### Mission 3 - "Pixy challenges you!"
- **Goal:** Adaptive learning based on user performance.  
- **Python Concepts:** Recommendation logic, progress analysis, adaptive difficulty.  
- **How it's done:** Backend selects next mission based on success rate and previous performance.  
- **Technical Notes:** Uses user history and scores for mission generation.

---

## Future Chapter — Adaptive Feedback and Progress Tracking

### (Optional) Mission - "Pixy learns from you."
- **Goal:** Personalize the AI experience.  
- **Python Concepts:** Data analytics, user profiling, reinforcement logic.  
- **How it's done:** Backend tracks time, accuracy, and preferences to adapt missions dynamically.  
- **Technical Notes:** Simple reinforcement-like system without heavy ML computation.
