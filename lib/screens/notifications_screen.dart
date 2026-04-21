import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trust_model.dart';
import '../services/payment_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _items = await PaymentService.getNotifications();
    setState(() => _isLoading = false);
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'PAYMENT_SUCCESS': return Icons.check_circle_outline;
      case 'WINNER_ANNOUNCEMENT': return Icons.emoji_events_outlined;
      case 'PAYMENT_REMINDER': return Icons.alarm_outlined;
      case 'ESCROW_RELEASE': return Icons.lock_open_outlined;
      case 'AUTO_PAY_CONFIRMATION': return Icons.autorenew;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'PAYMENT_SUCCESS': return const Color(0xFF10B981);
      case 'WINNER_ANNOUNCEMENT': return const Color(0xFFF59E0B);
      case 'PAYMENT_REMINDER': return const Color(0xFFEF4444);
      case 'ESCROW_RELEASE': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF1E3A8A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final n = _items[index];
                      final color = _colorFor(n.type);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: n.isRead ? null : color.withOpacity(0.04),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.12),
                            child: Icon(_iconFor(n.type), color: color, size: 20),
                          ),
                          title: Text(n.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.body, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                              Text(DateFormat('MMM d • h:mm a').format(n.sentAt),
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
                            ],
                          ),
                          trailing: !n.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
