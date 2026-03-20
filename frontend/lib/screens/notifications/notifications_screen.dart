import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sama/models/app_notification.dart';
import 'package:sama/services/notification_service.dart';
import 'package:sama/services/notification_sound.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _blueBright = Color(0xFF42AAFE);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  final NotificationService _service = NotificationService();
  bool _loading = false;
  List<AppNotification> _items = [];
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load(playSound: false);
  }

  Future<void> _load({bool playSound = true}) async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMyNotifications();
      if (!mounted) return;
      final newUnreadCount = data.where((n) => !n.isRead).length;
      if (playSound && newUnreadCount > _previousUnreadCount) {
        await NotificationSound.playAlert();
      }
      _previousUnreadCount = newUnreadCount;
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await _service.markRead(n.id);
      await _load(playSound: false);
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteOne(AppNotification n) async {
    try {
      await _service.deleteNotification(n.id);
      setState(() => _items.removeWhere((item) => item.id == n.id));
      Fluttertoast.showToast(
          msg: "Notification supprimée",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT);
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red);
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tout supprimer",
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: const Text("Voulez-vous supprimer toutes les notifications ?",
            style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler", style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Supprimer tout",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteAllNotifications();
      setState(() => _items.clear());
      Fluttertoast.showToast(
          msg: "Toutes les notifications supprimées",
          backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Row(children: [
          const Text("Notifications",
              style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          if (unreadCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _amber, borderRadius: BorderRadius.circular(20)),
              child: Text("$unreadCount non lue${unreadCount > 1 ? 's' : ''}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ),
          ],
        ]),
        actions: [
          IconButton(
            onPressed: () => _load(playSound: true),
            icon: const Icon(Icons.refresh, color: _textPrimary),
            tooltip: "Rafraîchir",
          ),
          if (_items.isNotEmpty)
            IconButton(
              onPressed: _deleteAll,
              icon:
                  const Icon(Icons.delete_sweep_outlined, color: _textPrimary),
              tooltip: "Tout supprimer",
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : _items.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: _appBlue,
                  backgroundColor: _bgCard,
                  onRefresh: () => _load(playSound: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _notifCard(_items[i]),
                  ),
                ),
    );
  }

  Widget _notifCard(AppNotification n) {
    final isUnread = !n.isRead;
    return Dismissible(
      key: Key(n.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        await _deleteOne(n);
        return true;
      },
      child: GestureDetector(
        onTap: () => _markRead(n),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? _appBlue.withValues(alpha: 0.12) : _bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isUnread ? _appBlue.withValues(alpha: 0.40) : _border),
            boxShadow: [
              BoxShadow(
                  color: isUnread
                      ? _appBlue.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? _appBlue.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUnread
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: isUnread ? _blueBright : _textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(n.title,
                            style: TextStyle(
                                color: isUnread ? _blueBright : _textPrimary,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 14))),
                    if (isUnread)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _appBlue)),
                  ]),
                  if (n.message != null && n.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(n.message!,
                        style: const TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    if (isUnread)
                      Text("Appuyer pour marquer lu",
                          style: TextStyle(
                              color: _appBlue.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _deleteOne(n),
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 14, color: Colors.red.shade400),
                        const SizedBox(width: 3),
                        Text("Supprimer",
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ])),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
            color: _appBlue.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none, color: _appBlue, size: 36),
      ),
      const SizedBox(height: 16),
      const Text("Aucune notification",
          style: TextStyle(
              color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      const Text("Vous êtes à jour !",
          style: TextStyle(color: _textMuted, fontSize: 13)),
    ]));
  }
}
