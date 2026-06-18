import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:vego/core/storage/token_storage.dart';

/// A single notification entry shown in the in-app notifications list.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final String? type;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.type,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'type': type,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        receivedAt:
            DateTime.tryParse(j['receivedAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        type: j['type']?.toString(),
        read: j['read'] == true,
      );
}

/// In-app history of received push notifications.
///
/// Push messages are otherwise transient (rendered by the OS tray and gone), so
/// this keeps a persisted list the user can revisit from the AppBar bell.
/// Captures foreground messages and messages the user taps to open the app;
/// background-delivered messages that are never tapped won't appear (FCM gives
/// us no hook to record those without a data-only handler).
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  static const _storageKey = 'app_notifications';
  static const _maxEntries = 100;

  final List<AppNotification> _items = [];
  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  /// Load persisted notifications. Safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await TokenStorage.getValue(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _items
          ..clear()
          ..addAll(list);
        notifyListeners();
      }
    } catch (_) {
      // Corrupt/legacy data — start clean rather than crash.
    }
  }

  /// Record a newly received notification (most recent first).
  Future<void> add({
    required String id,
    required String title,
    required String body,
    String? type,
    DateTime? receivedAt,
    bool read = false,
  }) async {
    // De-dupe by id so a foreground-then-tapped message isn't listed twice.
    if (_items.any((n) => n.id == id)) return;
    _items.insert(
      0,
      AppNotification(
        id: id,
        title: title.isEmpty ? 'Notification' : title,
        body: body,
        receivedAt: receivedAt ?? DateTime.now(),
        type: type,
        read: read,
      ),
    );
    if (_items.length > _maxEntries) {
      _items.removeRange(_maxEntries, _items.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead() async {
    var changed = false;
    for (final n in _items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> clear() async {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await TokenStorage.saveValue(
        _storageKey,
        jsonEncode(_items.map((n) => n.toJson()).toList()),
      );
    } catch (_) {
      // best-effort — losing history is preferable to crashing the UI
    }
  }
}
