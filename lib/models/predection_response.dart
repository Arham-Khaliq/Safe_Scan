class Detection {
  final String className;
  final double confidence;

  Detection({
    required this.className,
    required this.confidence,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['class'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class PredictionResponse {
  final String status;
  final String? predictedImageUrl;
  final String? predictedVideoUrl;
  final String description;
  final List<Detection> detections;
  final int totalObjects;
  final String? error;

  PredictionResponse({
    required this.status,
    this.predictedImageUrl,
    this.predictedVideoUrl,
    required this.description,
    this.detections = const [],
    this.totalObjects = 0,
    this.error,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    List<Detection> detectionsList = [];
    if (json['detections'] != null) {
      detectionsList = (json['detections'] as List)
          .map((detection) => Detection.fromJson(detection))
          .toList();
    }

    return PredictionResponse(
      status: json['status'] ?? 'unknown',
      predictedImageUrl: json['predicted_image_url'],
      predictedVideoUrl: json['predicted_video_url'],
      description: json['description'] ?? '',
      detections: detectionsList,
      totalObjects: json['total_objects'] ?? 0,
    );
  }

  factory PredictionResponse.error(String errorMessage) {
    return PredictionResponse(
      status: 'error',
      description: '',
      error: errorMessage,
    );
  }

  bool get hasError => error != null || status == 'error';
  bool get hasImageUrl => predictedImageUrl != null && predictedImageUrl!.isNotEmpty;
  bool get hasVideoUrl => predictedVideoUrl != null && predictedVideoUrl!.isNotEmpty;
  bool get isSuccess => status == 'success';
}
