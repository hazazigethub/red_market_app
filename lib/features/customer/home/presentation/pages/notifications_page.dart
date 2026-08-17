import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:red_market/main.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _notifStream; // ✅ مضاف

  @override
  void initState() {
    super.initState();
    // ✅ تعريف الـ Stream مرة واحدة فقط هنا
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      _notifStream = supabase
          .from('notifications_log')
          .stream(primaryKey: ['id'])
          .eq('status', 'sent')
          .order('created_at', ascending: false)
          .map((List<Map<String, dynamic>> data) {
            return data.where((notif) {
              final type = notif['target_type'];
              final targetId = notif['target_id'];
              final segment = notif['segment_filter'];
              if (type == 'all') return true;
              if (type == 'specific' && targetId == userId) return true;
              if (type == 'segment' && segment != null) {
                if (segment.contains('users')) return true;
                if (segment.contains('merchants')) return true;
              }
              return false;
            }).toList();
          });
    } else {
      _notifStream = const Stream.empty();
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await supabase
          .from('notifications_log')
          .update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await supabase.from('notifications_log').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  void _showNotificationDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFC21815)),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['title'] ?? 'تنبيه',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child:
                      const Icon(Icons.close, color: Colors.white70, size: 22),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              item['body'] ?? '',
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          actions: const [],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
      }
      return "${date.day}/${date.month}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "التنبيهات",
            style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notifStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC21815)));
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final bool isRead = notif['is_read'] ?? false;

                return Dismissible(
                  key: Key(notif['id'].toString()),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) =>
                      _deleteNotification(notif['id'].toString()),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.delete_sweep,
                        color: Colors.white, size: 28),
                  ),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      _markAsRead(notif['id'].toString());
                      _showNotificationDialog(notif);
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isRead
                          ? null
                          : const Color(0xFFC21815).withOpacity(0.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(
                          color: Color(0xFFC21815),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: isRead
                                    ? Colors.grey.shade100
                                    : const Color(0xFFC21815).withOpacity(0.1),
                                child: Icon(
                                  isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.notifications_active_rounded,
                                  color: isRead
                                      ? Colors.grey
                                      : const Color(0xFFC21815),
                                  size: 22,
                                ),
                              ),
                              if (!isRead)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC21815),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            notif['title'] ?? 'تنبيه جديد',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              notif['body'] ?? '',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isRead ? Colors.grey : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Text(
                            _formatDate(notif['created_at']),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 70, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text(
            "صندوق التنبيهات فارغ",
            style: TextStyle(
                fontFamily: 'Cairo', color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
