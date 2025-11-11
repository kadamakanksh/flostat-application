import 'device_model.dart';

class BlockModel {
  final String id;
  final String name;
  final List<DeviceModel> pumps;
  final List<Map<String, dynamic>> tanks;
  final Map<String, dynamic> raw;

  BlockModel({
    required this.id,
    required this.name,
    required this.pumps,
    required this.tanks,
    required this.raw,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final pumpsRaw = json['pumps'] ?? json['devices'] ?? [];
    final pumps = List<Map<String, dynamic>>.from(pumpsRaw).map((d) => DeviceModel.fromJson(d)).toList();
    final tanks = List<Map<String, dynamic>>.from(json['tanks'] ?? json['tank'] ?? []);
    return BlockModel(
      id: json['id']?.toString() ?? json['blockId']?.toString() ?? '',
      name: json['name'] ?? json['blockName'] ?? 'Block',
      pumps: pumps,
      tanks: tanks,
      raw: json,
    );
  }

  // helper to get overall waterPercent if available
  double getWaterPercent() {
    if (tanks.isEmpty) return 0.0;
    final first = tanks.first;
    final val = first['waterPercent'] ?? first['water_level'] ?? first['percentage'];
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
