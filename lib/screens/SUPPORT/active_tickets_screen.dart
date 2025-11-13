import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../models/support_ticket.dart';
import 'ticket_chat_screen.dart';

class ActiveTicketsScreen extends StatelessWidget {
  const ActiveTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Tickets"), backgroundColor: Colors.orange),
      body: Consumer<SupportTicketProvider>(
        builder: (context, ticketProvider, _) {
          final tickets = ticketProvider.activeTickets;
          if (tickets.isEmpty) {
            return const Center(child: Text("No active tickets"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) => _buildTicketCard(context, tickets[index]),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TicketChatScreen(ticket: ticket)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getQueryTypeLabel(ticket.queryType),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap to open chat",
                      style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
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
}
