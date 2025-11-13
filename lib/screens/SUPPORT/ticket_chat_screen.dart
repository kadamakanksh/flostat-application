import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/support_ticket_provider.dart';
import '../../providers/org_provider.dart';
import '../../models/support_ticket.dart';

class TicketChatScreen extends StatefulWidget {
  final SupportTicket ticket;

  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);
    final ticketProvider = Provider.of<SupportTicketProvider>(context, listen: false);
    
    final messages = await ticketProvider.getChatMessages(
      orgProvider.selectedOrgId!,
      widget.ticket.queryId,
    );
    
    // If no messages from API, show initial issue and auto-reply
    if (messages.isEmpty) {
      _messages = [
        {
          'message': widget.ticket.description,
          'userType': 'customer',
          'timestamp': widget.ticket.createdAt.toIso8601String(),
          'user': widget.ticket.createdBy,
        },
        {
          'message': 'Thanks for reaching out to us, our executive will get back to you within 24 hours',
          'userType': 'flostat',
          'timestamp': widget.ticket.createdAt.add(const Duration(seconds: 1)).toIso8601String(),
          'user': 'Support Team',
        },
      ];
    } else {
      _messages = messages;
    }
    
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    final message = _messageController.text.trim();
    _messageController.clear();

    final orgProvider = Provider.of<OrgProvider>(context, listen: false);
    final ticketProvider = Provider.of<SupportTicketProvider>(context, listen: false);

    final success = await ticketProvider.sendChatMessage(
      orgProvider.selectedOrgId!,
      widget.ticket.queryId,
      message,
    );

    setState(() => _isSending = false);

    if (success) {
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat - ${_getQueryTypeLabel(widget.ticket.queryType)}"),
        backgroundColor: Colors.orange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'complete') {
                _showCompleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark as Completed'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              "No messages yet",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isCustomer = msg['userType'] == 'customer';
                          return _buildMessageBubble(msg, isCustomer);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isCustomer) {
    final timestamp = msg['timestamp'] != null
        ? DateTime.parse(msg['timestamp'])
        : DateTime.now();
    final formattedTime = DateFormat('MM/dd/yyyy, hh:mm:ss a').format(timestamp);

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isCustomer ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCustomer ? 16 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCustomer)
              Text(
                "Support Team",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            if (!isCustomer) const SizedBox(height: 4),
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: isCustomer ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 11,
                color: isCustomer ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Ticket"),
        content: const Text("Mark this ticket as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final orgProvider = Provider.of<OrgProvider>(context, listen: false);
              final ticketProvider = Provider.of<SupportTicketProvider>(context, listen: false);
              
              final success = await ticketProvider.completeTicket(
                orgProvider.selectedOrgId!,
                widget.ticket.queryId,
              );
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket completed successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to complete ticket')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
