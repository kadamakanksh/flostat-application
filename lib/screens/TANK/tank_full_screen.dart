// lib/screens/TANK/tank_full_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '/providers/device_provider.dart';
import '/providers/org_provider.dart';
import '/config/api_endpoints.dart';

class TankFullScreen extends StatefulWidget {
  final String deviceId;

  const TankFullScreen({super.key, required this.deviceId});

  @override
  State<TankFullScreen> createState() => _TankFullScreenState();
}

class _TankFullScreenState extends State<TankFullScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _shakeController;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _reports = [];
  Timer? _reportTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadSchedules();
    _loadReports();
    _startReportTimer();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _shakeController.dispose();
    _reportTimer?.cancel();
    super.dispose();
  }

  void _startReportTimer() {
    _reportTimer = Timer.periodic(const Duration(hours: 1), (_) => _addReport());
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('schedules_${widget.deviceId}');
    if (data != null) setState(() => _schedules = List<Map<String, dynamic>>.from(jsonDecode(data)));
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('schedules_${widget.deviceId}', jsonEncode(_schedules));
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('reports_${widget.deviceId}');
    if (data != null) setState(() => _reports = List<Map<String, dynamic>>.from(jsonDecode(data)));
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reports_${widget.deviceId}', jsonEncode(_reports));
  }

  void _addReport() {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final tank = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => {});
    if (tank.isEmpty) return;

    final report = {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'timestamp': DateFormat('HH:mm:ss').format(DateTime.now()),
      'water_level': tank['status'].toString(),
    };

    setState(() {
      _reports.insert(0, report);
      if (_reports.length > 100) _reports.removeLast();
    });
    _saveReports();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final tank = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => {});

    if (tank.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Tank Details")), body: const Center(child: Text("Tank not found")));
    }

    final currentLevel = int.tryParse(tank['status'].toString()) ?? 0;
    final minThreshold = int.tryParse(tank["min_threshold"]?.toString() ?? "0") ?? 0;
    final maxThreshold = int.tryParse(tank["max_threshold"]?.toString() ?? "100") ?? 100;

    Color statusColor = Colors.blue;
    String statusText = "Normal";
    if (currentLevel <= minThreshold) {
      statusColor = Colors.red;
      statusText = "Low Water";
      _shakeController.forward(from: 0);
    } else if (currentLevel >= maxThreshold) {
      statusColor = Colors.orange;
      statusText = "High Water";
      _shakeController.forward(from: 0);
    }

    final connectedDevices = deviceProvider.devices.where((d) => d['parent_id']?.toString() == widget.deviceId).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(tank['device_name'] ?? "Tank"),
        backgroundColor: statusColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWaterLevelCard(tank, currentLevel, minThreshold, maxThreshold, statusColor, statusText),
            _buildConnectedDevicesCard(connectedDevices, deviceProvider),
            _buildScheduleCard(tank),
            _buildReportsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLevelCard(Map tank, int level, int min, int max, Color color, String status) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Live Status", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (_, child) => Transform.translate(offset: Offset(sin(_shakeController.value * pi * 10) * 6, 0), child: child),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Text("$level%", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(painter: WaterTankPainter(level: level / 100, color: color, animation: _waveController), size: const Size(200, 250)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, size: 60, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 8),
                    Text("$level%", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: _buildThresholdChip("Min", min, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildThresholdChip("Max", max, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showThresholdDialog(tank),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text("Set"),
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("$value%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildConnectedDevicesCard(List devices, DeviceProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.device_hub, color: Colors.green)),
                const SizedBox(width: 12),
                const Text("Connected Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          devices.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No connected devices", style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final device = devices[i];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: Icon(_getDeviceIcon(device['device_type']), color: Colors.green, size: 20)),
                      title: Text(device['device_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${device['device_type']?.toString().toUpperCase()} • ${device['status']}"),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)), child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map tank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.schedule, color: Colors.purple)),
                    const SizedBox(width: 12),
                    const Text("Schedule Manager", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: () => _showAddScheduleDialog(tank), icon: const Icon(Icons.add_circle, color: Colors.purple, size: 28)),
              ],
            ),
          ),
          const Divider(height: 1),
          _schedules.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No schedules", style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _schedules.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final s = _schedules[i];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.purple.withOpacity(0.1), child: Text("${i + 1}", style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                      title: Text(s['name'] ?? 'Schedule ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${s['device_name']} • ${s['start_time']} - ${s['end_time']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () => _showEditScheduleDialog(i), icon: const Icon(Icons.edit, color: Colors.blue, size: 20)),
                          IconButton(onPressed: () => _deleteSchedule(i), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildReportsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assessment, color: Colors.orange)),
                    const SizedBox(width: 12),
                    const Text("Water Level Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: _downloadPDF, icon: const Icon(Icons.download, color: Colors.orange, size: 28)),
              ],
            ),
          ),
          const Divider(height: 1),
          _reports.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No reports yet", style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reports.length > 10 ? 10 : _reports.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final r = _reports[i];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.water_drop, color: Colors.orange, size: 20)),
                      title: Text("${r['date']} at ${r['timestamp']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text("${r['water_level']}%", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(Map tank) {
    final nameCtrl = TextEditingController();
    final deviceNameCtrl = TextEditingController(text: tank['device_name'] ?? '');
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Schedule"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Schedule Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: deviceNameCtrl, decoration: const InputDecoration(labelText: "Device Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Start Time (HH:MM)", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "End Time (HH:MM)", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || deviceNameCtrl.text.isEmpty || startCtrl.text.isEmpty || endCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
                return;
              }
              setState(() => _schedules.add({'name': nameCtrl.text, 'device_name': deviceNameCtrl.text, 'start_time': startCtrl.text, 'end_time': endCtrl.text}));
              _saveSchedules();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule added"), backgroundColor: Colors.green));
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(int index) {
    final s = _schedules[index];
    final nameCtrl = TextEditingController(text: s['name']);
    final deviceNameCtrl = TextEditingController(text: s['device_name']);
    final startCtrl = TextEditingController(text: s['start_time']);
    final endCtrl = TextEditingController(text: s['end_time']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Schedule"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Schedule Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: deviceNameCtrl, decoration: const InputDecoration(labelText: "Device Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Start Time", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "End Time", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _schedules[index] = {'name': nameCtrl.text, 'device_name': deviceNameCtrl.text, 'start_time': startCtrl.text, 'end_time': endCtrl.text});
              _saveSchedules();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule updated"), backgroundColor: Colors.green));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showThresholdDialog(Map tank) {
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);
    final minCtrl = TextEditingController(text: tank['min_threshold']?.toString() ?? '0');
    final maxCtrl = TextEditingController(text: tank['max_threshold']?.toString() ?? '100');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text("Set Threshold"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Min (%)", border: OutlineInputBorder()),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max (%)", border: OutlineInputBorder()),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Min: ${minCtrl.text}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text("Max: ${maxCtrl.text}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating threshold..."), duration: Duration(seconds: 1)));
                
                try {
                  final response = await http.put(
                    Uri.parse(DeviceEndpoints.updateDevice),
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${deviceProvider.authProvider.token}'},
                    body: jsonEncode({
                      'org_id': orgProvider.selectedOrgId,
                      'device_id': widget.deviceId,
                      'device_name': tank['device_name'],
                      'block_id': tank['block_id'],
                      'parent_device_id': tank['parent_id'],
                      'min_threshold': int.parse(minCtrl.text),
                      'max_threshold': int.parse(maxCtrl.text),
                    }),
                  );

                  if (response.statusCode == 200) {
                    await deviceProvider.fetchDevices(orgProvider.selectedOrgId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Threshold updated successfully!"), backgroundColor: Colors.green));
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.statusCode}"), backgroundColor: Colors.red));
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSchedule(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _schedules.removeAt(index));
              _saveSchedules();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule deleted")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final tank = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => {});

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Tank Water Level Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text("Tank: ${tank['device_name']}", style: const pw.TextStyle(fontSize: 16)),
          pw.Text("Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Time', 'Water Level'],
            data: _reports.map((r) => [r['date'], r['timestamp'], '${r['water_level']}%']).toList(),
          ),
        ],
      );
    }));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pump':
        return Icons.invert_colors;
      case 'valve':
        return Icons.toggle_on;
      case 'tank':
        return Icons.water;
      case 'sump':
        return Icons.layers;
      default:
        return Icons.device_unknown;
    }
  }
}

class WaterTankPainter extends CustomPainter {
  final double level;
  final Color color;
  final Animation<double> animation;

  WaterTankPainter({required this.level, required this.color, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 3;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20));
    canvas.drawRRect(rect, paint);

    final waterHeight = size.height * level;
    final waterPaint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height - waterHeight);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height - waterHeight + sin((i / size.width * 2 * pi) + (animation.value * 2 * pi)) * 8);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.clipRRect(rect);
    canvas.drawPath(path, waterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
