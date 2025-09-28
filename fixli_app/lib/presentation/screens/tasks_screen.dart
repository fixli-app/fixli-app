// lib/presentation/screens/tasks_screen.dart

import 'dart:io';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/edit_request_screen.dart';
import 'package:fixli_app/presentation/screens/radius_filter_screen.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

Future<void> _deleteRequest(WidgetRef ref, String requestId) async {
  try {
    await locator<RequestRepository>().deleteRequest(requestId);
    ref.invalidate(requestListProvider);
    ref.invalidate(latestRequestsProvider);
    ref.invalidate(myRequestsProvider);
  } catch (e) {
    // Hantera fel om det behövs
  }
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Radera uppdrag'),
      content: const Text('Är du säker på att du vill radera detta uppdrag permanent?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Avbryt')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Radera', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  return confirmed ?? false;
}

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsyncValue = ref.watch(filteredRequestsProvider);
    final cities = ref.watch(uniqueCitiesProvider);
    final selectedCity = ref.watch(cityFilterProvider);
    final currentUser = ref.watch(authProvider).user;
    final radiusCenter = ref.watch(radiusCenterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alla uppdrag')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Sök på titel, plats, namn...', prefixIcon: Icon(Icons.search)),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ActionChip(
                      avatar: Icon(Icons.travel_explore, color: radiusCenter != null ? Colors.white : Colors.black54),
                      label: Text('Avstånd', style: TextStyle(color: radiusCenter != null ? Colors.white : Colors.black87)),
                      backgroundColor: radiusCenter != null ? Colors.teal : Colors.grey.shade300,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RadiusFilterScreen()));
                      },
                    ),
                    const SizedBox(width: 10),
                    if (cities.length > 1)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, color: Colors.teal),
                            const SizedBox(width: 10),
                            Flexible(
                              child: DropdownButton<String>(
                                value: selectedCity,
                                isExpanded: true,
                                items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city, overflow: TextOverflow.ellipsis,))).toList(),
                                onChanged: (value) { if (value != null) { ref.read(cityFilterProvider.notifier).state = value; } },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (radiusCenter != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    child: const Text('Nollställ avståndsfilter'),
                    onPressed: () => ref.read(radiusCenterProvider.notifier).state = null,
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(requestListProvider.notifier).fetchRequests(),
              child: requestsAsyncValue.when(
                loading: () => const ShimmerListPlaceholder(),
                error: (err, stack) => Center(child: Text('Fel: $err')),
                data: (requests) {
                  if (requests.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'Inga träffar',
                      subtitle: 'Prova en annan sökning eller ändra ditt filter.',
                    );
                  }
                  return GroupedListView<RequestWithUser, DateTime>(
                    elements: requests,
                    groupBy: (element) => DateTime(
                      element.request.createdAt.year,
                      element.request.createdAt.month,
                      element.request.createdAt.day,
                    ),
                    groupSeparatorBuilder: (DateTime groupByValue) {
                      String formattedDate = DateFormat.yMMMMd('sv_SE').format(groupByValue);
                      final today = DateTime.now();
                      final yesterday = today.subtract(const Duration(days: 1));
                      if (groupByValue.year == today.year && groupByValue.month == today.month && groupByValue.day == today.day) {
                        formattedDate = 'Idag';
                      } else if (groupByValue.year == yesterday.year && groupByValue.month == yesterday.month && groupByValue.day == yesterday.day) {
                        formattedDate = 'Igår';
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      );
                    },
                    itemBuilder: (context, RequestWithUser element) {
                      final request = element.request;
                      final isMyOwnPost = currentUser?.id == request.uploadedBy;

                      // 🟢 Byt ut ListTile mot den nya _RequestCard-widgeten
                      return _RequestCard(
                        element: element,
                        isMyOwnPost: isMyOwnPost,
                        onDelete: () async {
                          final confirmed = await _showDeleteConfirmationDialog(context);
                          if (confirmed) {
                            await _deleteRequest(ref, request.id);
                          }
                        },
                      );
                    },
                    padding: const EdgeInsets.all(8.0),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 NY, SNYGGARE WIDGET FÖR UPPDRAGSKORT
class _RequestCard extends ConsumerWidget {
  final RequestWithUser element;
  final bool isMyOwnPost;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.element,
    required this.isMyOwnPost,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = element.request;

    return Slidable(
      key: ValueKey(request.id),
      enabled: isMyOwnPost,
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditRequestScreen(requestToEdit: element)));
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Redigera',
          ),
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Radera',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        clipBehavior: Clip.antiAlias, // Klipper kanterna på bilden
        child: InkWell(
          onTap: () => showRequestDetailDialog(context, element, ref),
          child: Row(
            children: [
              // Bilden (eller en platshållare)
              SizedBox(
                width: 100,
                height: 100,
                child: request.imagePath != null
                    ? Image.file(File(request.imagePath!), fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40)),
              ),
              // Textinnehållet
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.location} • ${request.price} kr',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: isMyOwnPost
                            ? const Icon(Icons.swipe_left_outlined, color: Colors.grey, size: 20)
                            : StatusDisplay(status: request.status),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class StatusDisplay extends StatelessWidget {
  final String status;
  const StatusDisplay({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    switch (status) {
      case 'in_progress':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        label = 'Pågående';
        break;
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        label = 'Slutförd';
        break;
      case 'archived':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = 'Arkiverad';
        break;
      default:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Öppen';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}