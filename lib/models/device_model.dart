class DeviceModel {
  String deviceId;
  String deviceName;
  String deviceType;
  String status;
  int? maxThreshold;
  int? minThreshold;
  String? parentId;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.status,
    this.maxThreshold,
    this.minThreshold,
    this.parentId,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['device_id'],
      deviceName: json['device_name'] ?? 'Unknown',
      deviceType: json['device_type'],
      status: json['status'],
      maxThreshold: json['max_threshold'],
      minThreshold: json['min_threshold'],
      parentId: json['parent_id'],
    );
  }
}
