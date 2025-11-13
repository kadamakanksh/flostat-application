import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'device_provider.dart';
import '../models/log_model.dart';

class MqttProvider with ChangeNotifier {
  final DeviceProvider deviceProvider;

  MqttProvider({required this.deviceProvider});

  late MqttServerClient _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final List<LogModel> _logs = [];
  List<LogModel> get logs => _logs;

  // ===== MQTT CONFIG =====
  final String broker = 'YOUR_MQTT_BROKER_URL';
  final int port = 1883;
  final String username = 'YOUR_USERNAME';
  final String password = 'YOUR_PASSWORD';
  final String clientId =
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

  // ===== INITIALIZE & CONNECT =====
  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client.port = port;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;
    _client.onUnsubscribed = _onUnsubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      debugPrint("MQTT connection error: $e");
      disconnect();
      return;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint("✅ MQTT Connected");
      _isConnected = true;
      notifyListeners();
      _subscribeToTopics();
      _client.updates?.listen(_onMessageReceived);
    } else {
      debugPrint("❌ MQTT Connection failed: ${_client.connectionStatus}");
      disconnect();
    }
  }

  void disconnect() {
    _client.disconnect();
    _isConnected = false;
    notifyListeners();
    debugPrint("MQTT Disconnected");
  }

  void _onConnected() {
    debugPrint("MQTT Client Connected");
    _isConnected = true;
    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint("MQTT Client Disconnected");
    _isConnected = false;
    notifyListeners();
    // Auto-reconnect after 5 seconds
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void _onSubscribed(String topic) {
    debugPrint("Subscribed to $topic");
  }

  void _onUnsubscribed(String? topic) {
    debugPrint("Unsubscribed from $topic");
  }

  // ===== SUBSCRIBE TO DEVICE TOPICS =====
  void _subscribeToTopics() {
    if (deviceProvider.selectedOrgId == null) return;
    final orgId = deviceProvider.selectedOrgId!;
    for (var device in deviceProvider.devices) {
      final topic = 'org/$orgId/device/${device['device_id']}/status';
      _client.subscribe(topic, MqttQos.atMostOnce);
      debugPrint("Subscribed to $topic");
    }
  }

  // ===== HANDLE INCOMING MESSAGES =====
  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage?>>? events) {
    if (events == null) return;

    for (var event in events) {
      final recMess = event.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = jsonDecode(payload);
        final deviceId = data['device_id'];

        // ===== UPDATE DEVICE STATUS IN PROVIDER =====
        deviceProvider.updateDeviceFromMqtt(data);

        // ===== DETERMINE LOG TYPE =====
        String logType = 'info';
        if (data.containsKey('action')) {
          final action = data['action'].toString().toLowerCase();

          if (action.contains('error') ||
              (data['device_type'] == 'tank' &&
                  (data['current_level'] < data['min_threshold'] ||
                      data['current_level'] > data['max_threshold']))) {
            logType = 'error';
          } else if (action.contains('warning')) {
            logType = 'warning';
          }

          // ===== ADD LOG ENTRY =====
          final log = LogModel(
            id: data['log_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            deviceId: deviceId,
            deviceName: data['device_name'] ?? 'Unknown',
            action: data['action'],
            timestamp: DateTime.parse(
                data['timestamp'] ?? DateTime.now().toIso8601String()),
            logType: logType,
          );
          _logs.add(log);
          notifyListeners();
        }
      } catch (e) {
        debugPrint("🚨 Error parsing MQTT message: $e");
      }
    }
  }

  // ===== CLEAR LOGS IF NEEDED =====
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
