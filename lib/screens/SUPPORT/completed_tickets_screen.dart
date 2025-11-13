import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../models/support_ticket.dart';

class CompletedTicketsScreen extends StatelessWidget {
  const CompletedTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completed Tickets"), backgroundColor: Colors.blue),
      body: Consumer<SupportTicketProvider>(
        builder: (context, ticketProvider, _) {
          final tickets = ticketProvider.completedTickets;
          if (tickets.isEmpty) {
            return const Center(child: Text("No completed tickets"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(_getQueryTypeLabel(ticket.queryType), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                  child: const Text("COMPLETED", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Created by: ${ticket.createdBy}", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(ticket.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text("Created: ${_formatDate(ticket.createdAt)}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (ticket.updatedAt != null)
              Text("Completed: ${_formatDate(ticket.updatedAt!)}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  String _getQueryTypeLabel(String type) {
    switch (type) {
      case 'mobile': return 'Mobile Issue';
      case 'web': return 'Web Issue';
      case 'billing': return 'Billing';
      case 'technical': return 'Technical Issue';
      case 'other': return 'Other';
      default: return type;
    }
  }

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
}
