// lib/presentation/screens/public_profile_screen.dart

import 'dart:io';
import 'package:fixli_app/presentation/providers/rating_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicProfileScreen extends ConsumerWidget {
  final int userId;
  final String userName;

  const PublicProfileScreen({super.key, required this.userId, required this.userName});

  // Hjälpfunktion för att ringa eller skicka e-post
  Future<void> _launchUrl(String urlScheme, BuildContext context) async {
    final Uri uri = Uri.parse(urlScheme);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte öppna $urlScheme'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicUserProfileProvider(userId));
    final userRequestsAsync = ref.watch(userRequestsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text(userName)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Fel: $err')),
        data: (profile) {
          final user = profile.user;
          final rating = profile.averageRating;
          final reviews = profile.allRatings;

          ImageProvider? profileImage;
          if (user.profilePicturePath != null) {
            profileImage = FileImage(File(user.profilePicturePath!));
          }

          return ListView( // Byt till ListView för att enkelt lägga till sektioner
            padding: const EdgeInsets.all(16.0),
            children: [
              // Header med bild, namn och betyg
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage,
                        child: profileImage == null ? const Icon(Icons.person, size: 40) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                            if (user.location != null && user.location!.isNotEmpty)
                              Text(user.location!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                            _StarRatingDisplay(rating: rating.average, count: rating.count, showText: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Om mig-sektion
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                _SectionHeader('Om mig'),
                const SizedBox(height: 8),
                Text(user.bio!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                const SizedBox(height: 24),
              ],

              // Kontakt-sektion
              if((user.phone != null && user.phone!.isNotEmpty) || (user.email.isNotEmpty)) ...[
                _SectionHeader('Kontakt'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      if (user.phone != null && user.phone!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: Colors.teal),
                          title: const Text('Telefonnummer'),
                          subtitle: Text(user.phone!),
                          onTap: () => _launchUrl('tel:${user.phone}', context),
                        ),
                      if (user.phone != null && user.phone!.isNotEmpty) const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.email_outlined, color: Colors.teal),
                        title: const Text('E-post'),
                        subtitle: Text(user.email),
                        onTap: () => _launchUrl('mailto:${user.email}', context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Användarens uppdrag
              _SectionHeader('Användarens uppdrag'),
              const SizedBox(height: 8),
              userRequestsAsync.when(
                loading: () => const ShimmerListPlaceholder(itemCount: 2),
                error: (err, st) => const Text('Kunde inte ladda användarens uppdrag.'),
                data: (requests) {
                  if (requests.isEmpty) {
                    return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child: Text('${user.name} har inga synliga uppdrag just nu.')));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (ctx, index) {
                      final requestWithUser = requests[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(requestWithUser.request.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(requestWithUser.request.location),
                          trailing: _StatusDisplay(status: requestWithUser.request.status),
                          onTap: () => showRequestDetailDialog(context, requestWithUser, ref),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Omdömen-sektion
              _SectionHeader('Omdömen (${reviews.length})'),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Användaren har inga omdömen än.')))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, index) {
                    final ratingDetails = reviews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(ratingDetails.rater.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Row(
                                  children: [
                                    Text(ratingDetails.rating.ratingValue.toString()),
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('För uppdraget: "${ratingDetails.requestTitle}"', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                            const Divider(height: 16),
                            Text('"${ratingDetails.rating.comment ?? 'Inget omdöme lämnat.'}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final bool showText;
  const _StarRatingDisplay({required this.rating, required this.count, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < rating.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            );
          }),
          if (showText) ...[
            const SizedBox(width: 8),
            Text('$rating ($count)', style: Theme.of(context).textTheme.bodyMedium),
          ]
        ],
      ),
    );
  }
}

class _StatusDisplay extends StatelessWidget {
  final String status;
  const _StatusDisplay({required this.status});

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
      ),
    );
  }
}