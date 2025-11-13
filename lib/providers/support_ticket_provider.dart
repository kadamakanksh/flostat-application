import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/support_ticket.dart';
import '../config/api_endpoints.dart';
import 'auth_provider.dart';

class SupportTicketProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<SupportTicket> _tickets = [];

  SupportTicketProvider({required this.authProvider});

  List<SupportTicket> get activeTickets => _tickets.where((t) => t.status == 'active').toList();
  List<SupportTicket> get completedTickets => _tickets.where((t) => t.status == 'close').toList();

  Future<void> fetchTickets(String orgId) async {
    if (authProvider.token == null) {
      debugPrint('🔴 [SUPPORT] Cannot fetch tickets - No auth token');
      return;
    }

    debugPrint('🔵 [SUPPORT] Fetching tickets for org: $orgId');
    try {
      final response = await http.post(
        Uri.parse(SupportEndpoints.getAllOrgQuery),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({'org_id': orgId}),
      );

      debugPrint('🔵 [SUPPORT] Fetch response status: ${response.statusCode}');
      debugPrint('🔵 [SUPPORT] Fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _tickets = (data['customerQuerys'] as List).map((e) => SupportTicket.fromJson(e)).toList();
          debugPrint('✅ [SUPPORT] Fetched ${_tickets.length} tickets');
          notifyListeners();
        } else {
          debugPrint('🔴 [SUPPORT] API returned success=false: ${data['message']}');
        }
      } else {
        debugPrint('🔴 [SUPPORT] Failed to fetch tickets: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SUPPORT] Error fetching tickets: $e');
      debugPrint('🔴 [SUPPORT] Stack trace: $stackTrace');
    }
  }

  Future<bool> createTicket(String orgId, String queryType, String description) async {
    if (authProvider.token == null) {
      debugPrint('🔴 [SUPPORT] Cannot create ticket - No auth token');
      return false;
    }

    debugPrint('🔵 [SUPPORT] Creating ticket...');
    debugPrint('🔵 [SUPPORT] Org ID: $orgId');
    debugPrint('🔵 [SUPPORT] Query Type: $queryType');
    debugPrint('🔵 [SUPPORT] Description: $description');

    try {
      final requestBody = {
        'org_id': orgId,
        'description': description,
        'queryType': queryType,
      };
      debugPrint('🔵 [SUPPORT] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(SupportEndpoints.createQuery),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
          'org_id': orgId,
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('🔵 [SUPPORT] Create response status: ${response.statusCode}');
      debugPrint('🔵 [SUPPORT] Create response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [SUPPORT] Ticket created successfully');
          await fetchTickets(orgId);
          return true;
        } else {
          debugPrint('🔴 [SUPPORT] API returned success=false: ${data['message']}');
        }
      } else {
        debugPrint('🔴 [SUPPORT] Failed to create ticket: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SUPPORT] Error creating ticket: $e');
      debugPrint('🔴 [SUPPORT] Stack trace: $stackTrace');
    }
    return false;
  }

  Future<bool> completeTicket(String orgId, String queryId) async {
    if (authProvider.token == null) {
      debugPrint('🔴 [SUPPORT] Cannot complete ticket - No auth token');
      return false;
    }

    debugPrint('🔵 [SUPPORT] Completing ticket: $queryId');
    try {
      final requestBody = {
        'org_id': orgId,
        'query_id': queryId,
        'status': 'close',
      };
      debugPrint('🔵 [SUPPORT] Update request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse(SupportEndpoints.updateQuery),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('🔵 [SUPPORT] Complete response status: ${response.statusCode}');
      debugPrint('🔵 [SUPPORT] Complete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [SUPPORT] Ticket completed successfully');
          await fetchTickets(orgId);
          return true;
        } else {
          debugPrint('🔴 [SUPPORT] API returned success=false: ${data['message']}');
        }
      } else {
        debugPrint('🔴 [SUPPORT] Failed to complete ticket: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SUPPORT] Error completing ticket: $e');
      debugPrint('🔴 [SUPPORT] Stack trace: $stackTrace');
    }
    return false;
  }

  Future<bool> deleteTicket(String orgId, String queryId) async {
    if (authProvider.token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse(SupportEndpoints.deleteQuery),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'org_id': orgId,
          'query_id': queryId,
        }),
      );

      if (response.statusCode == 200) {
        await fetchTickets(orgId);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String orgId, String queryId) async {
    if (authProvider.token == null) {
      debugPrint('🔴 [SUPPORT] Cannot get messages - No auth token');
      return [];
    }

    debugPrint('🔵 [SUPPORT] Fetching chat messages for ticket: $queryId');
    try {
      final response = await http.post(
        Uri.parse(SupportEndpoints.customerSupportChat),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'query_id': queryId,
          'org_id': orgId,
        }),
      );

      debugPrint('🔵 [SUPPORT] Chat response status: ${response.statusCode}');
      debugPrint('🔵 [SUPPORT] Chat response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['chats'] != null) {
          final messages = data['chats']['messages'] as List? ?? [];
          debugPrint('✅ [SUPPORT] Fetched ${messages.length} messages');
          return List<Map<String, dynamic>>.from(messages);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SUPPORT] Error fetching messages: $e');
      debugPrint('🔴 [SUPPORT] Stack trace: $stackTrace');
    }
    return [];
  }

  Future<bool> sendChatMessage(String orgId, String queryId, String message) async {
    if (authProvider.token == null) {
      debugPrint('🔴 [SUPPORT] Cannot send message - No auth token');
      return false;
    }

    debugPrint('🔵 [SUPPORT] Sending chat message...');
    debugPrint('🔵 [SUPPORT] Message: $message');

    try {
      final requestBody = {
        'query_id': queryId,
        'org_id': orgId,
        'message': message,
        'userType': 'customer',
      };
      debugPrint('🔵 [SUPPORT] Chat request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(SupportEndpoints.customerSupportChat),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('🔵 [SUPPORT] Send message response status: ${response.statusCode}');
      debugPrint('🔵 [SUPPORT] Send message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ [SUPPORT] Message sent successfully');
          return true;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SUPPORT] Error sending message: $e');
      debugPrint('🔴 [SUPPORT] Stack trace: $stackTrace');
    }
    return false;
  }
}
