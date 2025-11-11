import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/org_provider.dart';
import '../providers/auth_provider.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final orgProvider = Provider.of<OrgProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final orgId = orgProvider.selectedOrgId;
      final token = authProvider.token;

      if (orgId != null && token != null && token.isNotEmpty) {
        deviceProvider.fetchDevices(orgId);
      }

      _isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Devices")),
      body: Consumer<DeviceProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.devices.isEmpty) return const Center(child: Text("No devices found"));

          return ListView.builder(
            itemCount: provider.devices.length,
            itemBuilder: (_, index) {
              final device = provider.devices[index];
              return ListTile(
                title: Text(device['device_name'] ?? "Unnamed"),
                subtitle: Text(device['device_type'] ?? ""),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
