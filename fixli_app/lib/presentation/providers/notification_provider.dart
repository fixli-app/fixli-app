// lib/presentation/providers/notification_provider.dart

import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/repositories/notification_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🟢 Ny Notifier som kan hantera state-ändringar (som att markera som läst)
class NotificationNotifier extends StateNotifier<AsyncValue<List<Notification>>> {
  final NotificationRepository _repo = locator<NotificationRepository>();
  final int _userId;
  final Ref _ref;

  NotificationNotifier(this._userId, this._ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repo.getAllNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 🟢 Ny metod för att markera alla som lästa
  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead(_userId);
    // Ladda om listan för att UI:t ska uppdateras och visa dem som lästa
    fetchNotifications();
  }
}

// En provider som hämtar ALLA notiser för den inloggade användaren
final notificationsProvider = StateNotifierProvider.autoDispose<NotificationNotifier, AsyncValue<List<Notification>>>((ref) {
  final user = ref.watch(authProvider).user;
  // Om ingen är inloggad, returnera en notifier med en tom lista
  if (user == null) {
    return NotificationNotifier(-1, ref)..state = const AsyncValue.data([]);
  }
  return NotificationNotifier(user.id, ref);
});

// En provider som i realtid lyssnar på antalet OLÄSTA notiser
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value(0); // Om ingen är inloggad, är antalet 0

  final repo = locator<NotificationRepository>();
  return repo.watchUnreadNotificationCount(user.id);
});