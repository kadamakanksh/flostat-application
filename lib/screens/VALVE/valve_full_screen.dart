import 'package:flostat_application/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '/providers/device_provider.dart';
import '/providers/org_provider.dart';

class ValveFullScreen extends StatefulWidget {
  final String deviceId;
  const ValveFullScreen({super.key, required this.deviceId});

  @override
  State<ValveFullScreen> createState() => _ValveFullScreenState();
}

class _ValveFullScreenState extends State<ValveFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  List<Map<String, dynamic>> _reports = [];
  Timer? _reportTimer;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

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
    if (data != null) {
      setState(() => _reports = List<Map<String, dynamic>>.from(jsonDecode(data)));
    }
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reports_${widget.deviceId}', jsonEncode(_reports));
  }

  void _addReport() {
    if (!mounted) return;
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final valve = deviceProvider.devices.firstWhere(
      (d) => d['device_id'].toString() == widget.deviceId,
      orElse: () => <String, dynamic>{},
    );
    if (valve.isEmpty) return;

    final status = valve['status']?.toString().toUpperCase() ?? ValveStatus.CLOSE;
    final report = {
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'timestamp': DateFormat('HH:mm:ss').format(DateTime.now()),
      'status': status,
    };

    setState(() {
      _reports.insert(0, report);
      if (_reports.length > 100) _reports.removeLast();
    });
    _saveReports();
  }

  Future<void> _showToggleConfirmation(Map valve, bool isOpen) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOpen ? 'Close Valve?' : 'Open Valve?'),
        content: Text(
            'Are you sure you want to ${isOpen ? 'close' : 'open'} ${valve['device_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: isOpen ? Colors.red : Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) _toggleValve(valve, isOpen);
  }

  Future<void> _toggleValve(Map valve, bool isOpen) async {
    if (!mounted || _isToggling) return;
    setState(() => _isToggling = true);
    HapticFeedback.mediumImpact();

    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    if (orgProvider.selectedOrgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Organization not selected")),
      );
      setState(() => _isToggling = false);
      return;
    }

    final currentStatus = valve['status']?.toString().toUpperCase() ?? ValveStatus.CLOSE;
    final success = await deviceProvider.toggleValve(widget.deviceId, currentStatus);

    setState(() => _isToggling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "Valve ${isOpen ? 'closed' : 'opened'} successfully"
            : "Failed to toggle valve"),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final valve = deviceProvider.devices.firstWhere(
      (d) => d['device_id'].toString() == widget.deviceId,
      orElse: () => <String, dynamic>{},
    );

    if (valve.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Valve Details")),
        body: const Center(child: Text("Valve not found")),
      );
    }

    final status = valve['status']?.toString().toUpperCase() ?? ValveStatus.CLOSE;
    final bool isOn = status == ValveStatus.OPEN;
    final Color statusColor = isOn ? Colors.green : Colors.grey;

    final connectedTank = valve['parent_id'] != null
        ? deviceProvider.devices.firstWhere(
            (d) => d['device_id'].toString() == valve['parent_id'].toString(),
            orElse: () => <String, dynamic>{},
          )
        : <String, dynamic>{};

    final connectedChildren = deviceProvider.devices
        .where((d) => d['parent_id']?.toString() == widget.deviceId)
        .toList();

    List<Map<String, dynamic>> connectedDevices = [];
    if (connectedTank.isNotEmpty) connectedDevices.add(connectedTank);
    connectedDevices.addAll(connectedChildren);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(valve['device_name'] ?? "Valve"),
        backgroundColor: statusColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildValveStatusCard(valve, isOn, statusColor),
            _buildConnectedDevicesCard(connectedDevices),
            if (connectedTank.isNotEmpty && connectedTank['device_type'] == DeviceType.TANK)
              _buildScheduleCard(connectedTank),
            _buildReportsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildValveStatusCard(Map valve, bool isOn, Color color) {
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
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Live Status", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    isOn ? "VALVE OPEN" : "VALVE CLOSE",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ]),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(scale: 1.0 + (_pulseController.value * 0.1), child: child),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(isOn ? Icons.toggle_on : Icons.toggle_off, size: 60, color: color),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _isToggling ? null : () => _showToggleConfirmation(valve, isOn),
              icon: _isToggling
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isOn ? Icons.toggle_off : Icons.toggle_on, size: 24),
              label: Text(_isToggling ? "Toggling..." : (isOn ? "Close Valve" : "Open Valve")),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOn ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDevicesCard(List devices) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [Icon(Icons.device_hub, color: Colors.blue), SizedBox(width: 8), Text("Connected Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          ),
          const Divider(height: 1),
          devices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text("No connected devices", style: TextStyle(color: Colors.grey))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final device = devices[i];
                    final status = device['status']?.toString().toUpperCase() ?? ValveStatus.CLOSE;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(_getDeviceIcon(device['device_type']), color: Colors.blue)),
                      title: Text(device['device_name'] ?? 'Unknown'),
                      subtitle: Text("${device['device_type']} • $status"),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map tank) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadTankSchedules(tank['device_id'].toString()),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? [];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.schedule, color: Colors.orange),
                title: Text("Tank Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              schedules.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text("No schedules for connected tank", style: TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: schedules.map((s) => ListTile(title: Text(s['name'] ?? 'Schedule'), subtitle: Text("${s['start_time']} - ${s['end_time']}"))).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadTankSchedules(String tankId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('schedules_$tankId');
    if (data != null) return List<Map<String, dynamic>>.from(jsonDecode(data));
    return [];
  }

  Widget _buildReportsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.assessment, color: Colors.purple),
            title: const Text("Valve Status Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            trailing: IconButton(onPressed: _downloadPDF, icon: const Icon(Icons.download, color: Colors.purple)),
          ),
          const Divider(height: 1),
          _reports.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No reports yet", style: TextStyle(color: Colors.grey))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reports.length > 10 ? 10 : _reports.length,
                  itemBuilder: (_, i) {
                    final r = _reports[i];
                    final status = r['status']?.toString().toUpperCase() ?? ValveStatus.CLOSE;
                    final isOpen = status == ValveStatus.OPEN;
                    final color = isOpen ? Colors.green : Colors.grey;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(isOpen ? Icons.toggle_on : Icons.toggle_off, color: color)),
                      title: Text("${r['date']} ${r['timestamp']}"),
                      trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Valve Status Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Date', 'Time', 'Status'],
              data: _reports.map((r) => [r['date'], r['timestamp'], r['status']]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pump': return Icons.invert_colors;
      case 'valve': return Icons.toggle_on;
      case 'tank': return Icons.water;
      case 'sump': return Icons.layers;
      default: return Icons.device_unknown;
    }
  }
}
