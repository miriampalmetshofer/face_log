class VideoAnnotation {
  final String videoPath;
  final Map<String, dynamic> answers;
  final DateTime timestamp;

  VideoAnnotation({
    required this.videoPath,
    required this.answers,
    required this.timestamp,
  });

  // Serialize to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'videoPath': videoPath,
      'answers': answers,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Serialize to JSON for Firebase upload
  Map<String, dynamic> toUploadJson(String userName) {
    // Extract just the filename from the full path
    final fileName = videoPath.split('/').last;

    return {
      'user': userName,
      'video_filename': fileName,
      'timestamp': timestamp.toIso8601String(),
      'annotations': answers,
    };
  }

  // Deserialize from JSON
  factory VideoAnnotation.fromJson(Map<String, dynamic> json) {
    // Deep copy answers and convert List<dynamic> to List<String> for multiple choice
    final Map<String, dynamic> answersMap = {};
    (json['answers'] as Map).forEach((key, value) {
      if (value is List) {
        // Convert List<dynamic> to List<String> for multiple choice answers
        answersMap[key] = List<String>.from(value);
      } else {
        answersMap[key] = value;
      }
    });

    return VideoAnnotation(
      videoPath: json['videoPath'] as String,
      answers: answersMap,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Create a copy with updated fields
  VideoAnnotation copyWith({
    String? videoPath,
    Map<String, dynamic>? answers,
    DateTime? timestamp,
  }) {
    return VideoAnnotation(
      videoPath: videoPath ?? this.videoPath,
      answers: answers ?? this.answers,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
