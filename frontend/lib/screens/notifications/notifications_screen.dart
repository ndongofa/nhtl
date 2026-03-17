import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sama/models/app_notification.dart';
import 'package:sama/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService service = NotificationService();
  bool _loading = false;
  List<AppNotification> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await service.getMyNotifications();
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await service.markRead(n.id);
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text("Aucune notification"))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      onTap: () => _markRead(n),
                      leading: Icon(
                        n.isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                        color: n.isRead ? Colors.grey : Colors.blue,
                      ),
                      title: Text(n.title),
                      subtitle: Text(n.message ?? ''),
                      trailing: n.isRead ? null : const Text("Nouveau"),
                    );
                  },
                ),
    );
  }
}
