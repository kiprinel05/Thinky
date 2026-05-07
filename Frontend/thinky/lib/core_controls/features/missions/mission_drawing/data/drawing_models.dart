/// Model for drawing analysis result from backend
class DrawingAnalysisResult {
  final String? detectedShape;
  final String? detectedColor;
  final int vertexCount;
  final bool isTriangle;
  final bool isBlue;
  final bool isCorrect;
  final double confidenceShape;
  final double confidenceColor;
  final String message;
  final String pixyEmotion;

  DrawingAnalysisResult({
    this.detectedShape,
    this.detectedColor,
    this.vertexCount = 0,
    this.isTriangle = false,
    this.isBlue = false,
    this.isCorrect = false,
    this.confidenceShape = 0.0,
    this.confidenceColor = 0.0,
    this.message = '',
    this.pixyEmotion = 'neutral',
  });

  static const _shapeNormalize = {
    'ellipse': 'circle',
  };

  static String? _normalizeShape(String? shape) {
    if (shape == null) return null;
    return _shapeNormalize[shape.toLowerCase()] ?? shape;
  }

  factory DrawingAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DrawingAnalysisResult(
      detectedShape: _normalizeShape(json['detected_shape'] as String?),
      detectedColor: json['detected_color'] as String?,
      vertexCount: json['vertex_count'] as int? ?? 0,
      isTriangle: json['is_triangle'] as bool? ?? false,
      isBlue: json['is_blue'] as bool? ?? false,
      isCorrect: json['is_correct'] as bool? ?? false,
      confidenceShape: (json['confidence_shape'] as num?)?.toDouble() ?? 0.0,
      confidenceColor: (json['confidence_color'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      pixyEmotion: json['pixy_emotion'] as String? ?? 'neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected_shape': detectedShape,
      'detected_color': detectedColor,
      'vertex_count': vertexCount,
      'is_triangle': isTriangle,
      'is_blue': isBlue,
      'is_correct': isCorrect,
      'confidence_shape': confidenceShape,
      'confidence_color': confidenceColor,
      'message': message,
      'pixy_emotion': pixyEmotion,
    };
  }
}
