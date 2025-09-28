// lib/presentation/screens/notifications_screen.dart

import 'package:fixli_app/data/repositories/notification_repository.dart';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/notification_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    // Anropa "markera som läst" så fort skärmen byggs, men efter den första bildrutan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aviseringar'),
      ),
      body: notificationsAsync.when(
        loading: () => const ShimmerListPlaceholder(),
        error: (err, st) => Center(child: Text('Fel: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'Inga aviseringar',
              subtitle: 'När något händer i appen kommer du se det här.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (ctx, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead ? Colors.grey.shade200 : Colors.teal.shade100,
                    child: Icon(
                      Icons.notifications,
                      color: notification.isRead ? Colors.grey : Colors.teal,
                    ),
                  ),
                  title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(notification.body),
                  trailing: Text(
                    timeago.format(notification.createdAt, locale: 'sv'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () async {
                    // Markera den specifika notisen som läst
                    await locator<NotificationRepository>().markAsRead(notification.id);
                    ref.invalidate(notificationsProvider);

                    // Om notisen är kopplad till ett uppdrag, navigera dit
                    if (notification.requestId != null) {
                      // 🟢 KORRIGERING: Använder den nya, säkra metoden
                      final requestRepo = locator<RequestRepository>();
                      final targetRequest = await requestRepo.getRequestById(notification.requestId!);

                      if (targetRequest != null && context.mounted) {
                        // Om vi hittar uppdraget, stäng aviseringssidan och visa detaljvyn
                        Navigator.of(context).pop();
                        showRequestDetailDialog(context, targetRequest, ref);
                      } else if (context.mounted) {
                        // Om uppdraget inte hittas (t.ex. raderat), visa ett meddelande
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Det länkade uppdraget kunde inte hittas.')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}