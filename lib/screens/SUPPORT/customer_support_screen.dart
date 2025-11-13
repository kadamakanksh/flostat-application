import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../providers/org_provider.dart';
import 'new_ticket_screen.dart';
import 'active_tickets_screen.dart';
import 'completed_tickets_screen.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgProvider = Provider.of<OrgProvider>(context, listen: false);
      if (orgProvider.selectedOrgId != null) {
        Provider.of<SupportTicketProvider>(context, listen: false).fetchTickets(orgProvider.selectedOrgId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Support"),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<SupportTicketProvider>(
        builder: (context, ticketProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSupportCard(
                  context,
                  icon: Icons.add_circle_outline,
                  title: "New Ticket",
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewTicketScreen())),
                ),
                const SizedBox(height: 20),
                _buildSupportCard(
                  context,
                  icon: Icons.pending_actions,
                  title: "Active Tickets",
                  subtitle: "${ticketProvider.activeTickets.length} tickets",
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTicketsScreen())),
                ),
                const SizedBox(height: 20),
                _buildSupportCard(
                  context,
                  icon: Icons.check_circle_outline,
                  title: "Completed Tickets",
                  subtitle: "${ticketProvider.completedTickets.length} tickets",
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedTicketsScreen())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, {required IconData icon, required String title, String? subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
