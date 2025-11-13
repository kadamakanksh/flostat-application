// lib/screens/PUMP/pump_full_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '/providers/device_provider.dart';
import '/providers/org_provider.dart';
import '/config/api_endpoints.dart';

class PumpFullScreen extends StatefulWidget {
  final String deviceId;

  const PumpFullScreen({super.key, required this.deviceId});

  @override
  State<PumpFullScreen> createState() => _PumpFullScreenState();
}

class _PumpFullScreenState extends State<PumpFullScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  List<Map<String, dynamic>> _reports = [];
  Timer? _reportTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _loadReports();
    _startReportTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _reportTimer?.cancel();
    super.dispose();
  }

  void _startReportTimer() {
    _reportTimer = Timer.periodic(const Duration(hours: 1), (_) => _addReport());
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
    final pump = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => <String, dynamic>{});
    if (pump.isEmpty) return;

    final status = pump['status']?.toString().toLowerCase() ?? 'off';
    final bool isOn = status == 'on' || status == '1' || status == 'true';

    final report = {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'timestamp': DateFormat('HH:mm:ss').format(DateTime.now()),
      'status': isOn ? 'ON' : 'OFF',
    };

    setState(() {
      _reports.insert(0, report);
      if (_reports.length > 100) _reports.removeLast();
    });
    _saveReports();
  }

  Future<void> _togglePump(Map pump, bool currentState) async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    try {
      final response = await http.put(
        Uri.parse(DeviceEndpoints.updateDeviceStatus),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${deviceProvider.authProvider.token}'},
        body: jsonEncode({
          'org_id': orgProvider.selectedOrgId,
          'device_id': widget.deviceId,
          'device_name': pump['device_name'],
          'block_id': pump['block_id'],
          'parent_device_id': pump['parent_id'],
          'status': currentState ? 'off' : 'on',
        }),
      );

      if (response.statusCode == 200) {
        await deviceProvider.fetchDevices(orgProvider.selectedOrgId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pump turned ${currentState ? 'OFF' : 'ON'}"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final pump = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => <String, dynamic>{});

    if (pump.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text("Pump Details")), body: const Center(child: Text("Pump not found")));
    }

    final status = pump['status']?.toString().toLowerCase() ?? 'off';
    final bool isOn = status == 'on' || status == '1' || status == 'true';
    final Color statusColor = isOn ? Colors.blue : Colors.grey;

    // Find connected sump (child - sump has pump as parent_id)
    final connectedSump = deviceProvider.devices.where(
      (d) => d['parent_id']?.toString() == widget.deviceId && d['device_type'] == 'sump'
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(pump['device_name'] ?? "Pump"),
        backgroundColor: statusColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPumpStatusCard(pump, isOn, statusColor),
            _buildConnectedDevicesCard(connectedSump, deviceProvider),
            _buildReportsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPumpStatusCard(Map pump, bool isOn, Color color) {
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
                    Text(isOn ? "PUMP ON" : "PUMP OFF", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(scale: 1.0 + (_pulseController.value * 0.1), child: child),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.invert_colors, size: 60, color: color),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Icon(Icons.invert_colors, size: 120, color: color),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _togglePump(pump, isOn),
                    icon: Icon(isOn ? Icons.power_settings_new : Icons.power, size: 24),
                    label: Text(isOn ? "Turn OFF" : "Turn ON", style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOn ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.device_hub, color: Colors.orange)),
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
                      leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: Icon(_getDeviceIcon(device['device_type']), color: Colors.orange, size: 20)),
                      title: Text(device['device_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${device['device_type']?.toString().toUpperCase()} • ${device['status']}"),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)), child: const Text("Connected", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
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
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assessment, color: Colors.teal)),
                    const SizedBox(width: 12),
                    const Text("Pump Status Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: _downloadPDF, icon: const Icon(Icons.download, color: Colors.teal, size: 28)),
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
                    final isOn = r['status'] == 'ON';
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: isOn ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1), child: Icon(Icons.invert_colors, color: isOn ? Colors.blue : Colors.grey, size: 20)),
                      title: Text("${r['date']} at ${r['timestamp']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: isOn ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(r['status'], style: TextStyle(color: isOn ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final pump = deviceProvider.devices.firstWhere((d) => d['device_id'].toString() == widget.deviceId, orElse: () => <String, dynamic>{});

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Pump Status Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text("Pump: ${pump['device_name']}", style: const pw.TextStyle(fontSize: 16)),
          pw.Text("Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Time', 'Status'],
            data: _reports.map((r) => [r['date'], r['timestamp'], r['status']]).toList(),
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
