import 'package:flutter/material.dart';

class PumpTile extends StatelessWidget {
  final String name;
  final bool isOn;
  final VoidCallback onToggle;
  final VoidCallback onSchedule;
  const PumpTile({required this.name, required this.isOn, required this.onToggle, required this.onSchedule, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(isOn ? "Status: ON" : "Status: OFF"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: isOn, onChanged: (_) => onToggle()),
          IconButton(icon: Icon(Icons.schedule), onPressed: onSchedule),
        ],
      ),
    );
  }
}
