import 'package:flostat_application/screens/TANK/tank_list_screen.dart';
import 'package:flostat_application/screens/VALVE/valve_list_screen.dart';
import 'package:flostat_application/screens/PUMP/pump_list_screen.dart';
import 'package:flostat_application/screens/SUMP/sump_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_drawer.dart';
import '../providers/org_provider.dart';
import '../providers/device_provider.dart';

class DashboardScreenExtended extends StatefulWidget {
  const DashboardScreenExtended({super.key});

  @override
  State<DashboardScreenExtended> createState() =>
      _DashboardScreenExtendedState();
}

class _DashboardScreenExtendedState extends State<DashboardScreenExtended>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) _animController.forward();
    });
  }

  Future<void> _refreshData() async {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    if (orgProvider.selectedOrgId != null) {
      await deviceProvider.fetchDevices(orgProvider.selectedOrgId!);
      await deviceProvider.fetchBlocks(orgProvider.selectedOrgId!);
      await deviceProvider.fetchBlockModes(orgProvider.selectedOrgId!);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _bottomContent(String label, int count, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text("$count", style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _onBottomNavTapped(int index, List<Map<String, dynamic>> allDevices) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    final blockName = deviceProvider.selectedBlockId != null && deviceProvider.selectedBlockId != ""
        ? (deviceProvider.blocks.firstWhere(
                (b) => b['block_id'] == deviceProvider.selectedBlockId,
                orElse: () => {'block_name': 'Unknown'})['block_name'] ??
            'Unknown')
        : null;

    switch (index) {
      case 0: // Tanks
        final tanks = allDevices
            .where((d) => d['device_type'] == 'tank')
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TankListScreen(
              tanks: tanks,
              blockName: blockName,
            ),
          ),
        );
        break;
      case 1: // Valves
        final valves = allDevices
            .where((d) => d['device_type'] == 'valve')
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ValveListScreen(
              valves: valves,
              blockName: blockName,
            ),
          ),
        );
        break;
      case 2: // Pumps
        final pumps = allDevices
            .where((d) => d['device_type'] == 'pump')
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PumpListScreen(
              pumps: pumps,
              blockName: blockName,
            ),
          ),
        );
        break;
      case 3: // Sumps
        final sumps = allDevices
            .where((d) => d['device_type'] == 'sump')
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SumpListScreen(
              sumps: sumps,
              blockName: blockName,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = Provider.of<OrgProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final width = MediaQuery.of(context).size.width;

    final allDevices = deviceProvider.devices;
    
    final devices = deviceProvider.selectedBlockId == null ||
            deviceProvider.selectedBlockId == ""
        ? allDevices
        : allDevices
            .where((d) => d['block_id'] == deviceProvider.selectedBlockId)
            .toList();

    final counts = {
      'tank': devices.where((d) => d['device_type'] == 'tank').length,
      'valve': devices.where((d) => d['device_type'] == 'valve').length,
      'pump': devices.where((d) => d['device_type'] == 'pump').length,
      'sump': devices.where((d) => d['device_type'] == 'sump').length,
    };

    final isMobile = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                if (orgProvider.selectedOrgId != null)
                  Container(
                    width: double.infinity,
                    color: Colors.blue.shade50,
                    padding: EdgeInsets.all(width * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Organization: ${orgProvider.selectedOrgName ?? ''}",
                          style: TextStyle(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: width * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Select Block"),
                                value: deviceProvider.selectedBlockId == ""
                                    ? ""
                                    : deviceProvider.selectedBlockId,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: "",
                                    child: Text("All Blocks"),
                                  ),
                                  ...deviceProvider.blocks.map((block) {
                                    final mode = deviceProvider
                                            .blockModes[block['block_id']] ??
                                        '';
                                    return DropdownMenuItem<String>(
                                      value: block['block_id'],
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(block['block_name'] ?? ''),
                                          if (mode.isNotEmpty)
                                            Text(
                                              mode.toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  })
                                ],
                                onChanged: (value) {
                                  deviceProvider.selectBlock(value ?? "");
                                  if (value != "") {
                                    deviceProvider.fetchParentDevices(
                                      orgProvider.selectedOrgId!,
                                    );
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            if (deviceProvider.selectedBlockId != "")
                              ElevatedButton(
                                onPressed: () {
                                  final currentMode =
                                      deviceProvider.blockModes[
                                              deviceProvider.selectedBlockId] ??
                                          "auto";
                                  final newMode = currentMode == "auto"
                                      ? "manual"
                                      : "auto";
                                  deviceProvider.changeBlockMode(
                                    deviceProvider.selectedBlockId!,
                                    newMode,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Block mode changed to $newMode mode"),
                                    ),
                                  );
                                },
                                child: const Text("Toggle Block Mode"),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: width * 0.015),
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnim.value,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: width * 0.006),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Devices",
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${devices.length} devices",
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Device counts",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _bottomContent("TANK", counts['tank'] ?? 0, Icons.water),
                          _bottomContent("VALVE", counts['valve'] ?? 0, Icons.toggle_on),
                          _bottomContent("PUMP", counts['pump'] ?? 0, Icons.invert_colors),
                          _bottomContent("SUMP", counts['sump'] ?? 0, Icons.layers),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentBottomIndex = idx);
          _onBottomNavTapped(idx, devices);
        },
        height: 65,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: "Tanks",
          ),
          NavigationDestination(
            icon: Icon(Icons.toggle_off_outlined),
            selectedIcon: Icon(Icons.toggle_on),
            label: "Valves",
          ),
          NavigationDestination(
            icon: Icon(Icons.invert_colors_off),
            selectedIcon: Icon(Icons.invert_colors),
            label: "Pumps",
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: "Sumps",
          ),
        ],
      ),
    );
  }
}
