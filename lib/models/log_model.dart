class LogModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String action; // e.g., "ON", "OFF", "Threshold Exceeded"
  final DateTime timestamp;
   String? logType; 

 

  LogModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.action,
    required this.timestamp,
    this.logType,
  });

  // Factory method to create a LogModel from JSON
  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] ?? '',
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      action: json['action'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  String? get message => null;

  // Convert LogModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
