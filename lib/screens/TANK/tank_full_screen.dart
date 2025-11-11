// lib/screens/tank_full_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/device_provider.dart';
import 'dart:math';

class TankFullScreen extends StatefulWidget {
  final String deviceId;

  const TankFullScreen({super.key, required this.deviceId});

  @override
  State<TankFullScreen> createState() => _TankFullScreenState();
}

class _TankFullScreenState extends State<TankFullScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    // ✅ Shake animation controller
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);

    // ✅ Fetch tank data
    final tank = deviceProvider.devices.firstWhere(
      (d) => d['device_id'].toString() == widget.deviceId,
      orElse: () => {},
    );

    if (tank.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Tank Details")),
        body: const Center(child: Text("Tank not found")),
      );
    }

    // ✅ Extract fields
    final String tankName = tank['device_name'] ?? "Tank";
    final int currentLevel = int.tryParse(tank['status'].toString()) ?? 0;

    final int minThreshold = tank["min_threshold"] is int
        ? tank["min_threshold"]
        : int.tryParse(tank["min_threshold"]?.toString() ?? "0") ?? 0;

    final int maxThreshold = tank["max_threshold"] is int
        ? tank["max_threshold"]
        : int.tryParse(tank["max_threshold"]?.toString() ?? "100") ?? 100;

    // ✅ Color Logic
    Color tankColor = Colors.blue;
    IconData? alertIcon;
    String? alertMsg;

    if (currentLevel <= minThreshold) {
      tankColor = Colors.red;
      alertIcon = Icons.warning_rounded;
      alertMsg = "Tank level is below minimum limit!";
      _shakeController.forward(from: 0); // Trigger shake
    } else if (currentLevel >= maxThreshold) {
      tankColor = Colors.orange;
      alertIcon = Icons.error_rounded;
      alertMsg = "Tank level is above maximum limit!";
      _shakeController.forward(from: 0); // Trigger shake
    }

    // ✅ Shake animation (Left-right movement)
    final double shakeOffset =
        sin(_shakeController.value * pi * 10) * 6; // 6px small shake

    return Scaffold(
      appBar: AppBar(
        title: Text(tankName),
        backgroundColor: Colors.blue,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ================== Tank Name + % ==================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tankName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    if (alertIcon != null)
                      Icon(alertIcon, color: tankColor, size: 26),

                    const SizedBox(width: 6),

                    Text(
                      "$currentLevel%",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tankColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ ALERT MESSAGE
            if (alertMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tankColor),
                ),
                child: Row(
                  children: [
                    Icon(alertIcon, color: tankColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alertMsg!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: tankColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ================== Progress Bar ==================
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade300,
                  ),
                ),

                FractionallySizedBox(
                  widthFactor: (currentLevel / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: tankColor,
                    ),
                  ),
                ),

                Text(
                  "$currentLevel%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ================== Min / Max Labels ==================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Min: $minThreshold",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  "Max: $maxThreshold",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ================== Tank Icon + Shake Animation ==================
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(shakeOffset, 0),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water,
                        size: 140,
                        color: tankColor,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Current Level: $currentLevel%",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
