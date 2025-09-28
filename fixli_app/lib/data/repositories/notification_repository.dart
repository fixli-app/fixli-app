// lib/data/repositories/notification_repository.dart

import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';

class NotificationRepository {
  final AppDatabase _db;
  NotificationRepository(this._db);

  /// Skapar en ny notis för en specifik användare
  Future<void> createNotification({
    required int userId,
    required String title,
    required String body,
    String? requestId,
  }) async {
    final newNotification = NotificationsCompanion.insert(
      userId: userId,
      title: title,
      body: body,
      requestId: Value(requestId),
      createdAt: DateTime.now(),
    );
    await _db.into(_db.notifications).insert(newNotification);
  }

  /// Hämtar alla olästa notiser för en användare
  Future<List<Notification>> getUnreadNotifications(int userId) {
    return (_db.select(_db.notifications)
      ..where((n) => n.userId.equals(userId) & n.isRead.equals(false))
      ..orderBy([(n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Hämtar alla notiser för en användare
  Future<List<Notification>> getAllNotifications(int userId) {
    return (_db.select(_db.notifications)
      ..where((n) => n.userId.equals(userId))
      ..orderBy([(n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Markerar en specifik notis som läst
  Future<void> markAsRead(int notificationId) async {
    final companion = NotificationsCompanion(isRead: const Value(true));
    await (_db.update(_db.notifications)..where((n) => n.id.equals(notificationId))).write(companion);
  }

  // 🟢 NY METOD: Markerar ALLA notiser för en användare som lästa
  Future<void> markAllAsRead(int userId) async {
    final companion = NotificationsCompanion(isRead: const Value(true));
    await (_db.update(_db.notifications)..where((n) => n.userId.equals(userId))).write(companion);
  }

  /// Räknar antalet olästa notiser
  Stream<int> watchUnreadNotificationCount(int userId) {
    final countExpression = countAll(filter: _db.notifications.isRead.equals(false) & _db.notifications.userId.equals(userId));
    final query = _db.selectOnly(_db.notifications)..addColumns([countExpression]);

    return query.map((row) => row.read(countExpression) ?? 0).watchSingle();
  }
}