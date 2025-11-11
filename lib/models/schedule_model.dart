class ScheduleModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> days; // e.g., ["Mon", "Wed", "Fri"]
  final bool isActive;

  ScheduleModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.isActive,
  });

  // Factory method to create a ScheduleModel from JSON
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? '',
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['end_time'] ?? DateTime.now().toIso8601String()),
      days: List<String>.from(json['days'] ?? []),
      isActive: json['is_active'] ?? true,
    );
  }

  // Convert ScheduleModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'days': days,
      'is_active': isActive,
    };
  }
}
