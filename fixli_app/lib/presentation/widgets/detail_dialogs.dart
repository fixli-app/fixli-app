// lib/presentation/widgets/detail_dialogs.dart

import 'dart:io';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/repositories/auth_repository.dart';
import 'package:fixli_app/data/repositories/job_application_repository.dart';
import 'package:fixli_app/data/repositories/rating_repository.dart';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/providers/rating_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/applicants_screen.dart';
import 'package:fixli_app/presentation/screens/public_profile_screen.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';

void showRequestDetailDialog(BuildContext context, RequestWithUser requestWithUser, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: RequestDialog(requestWithUser: requestWithUser),
    ),
  );
}

void _copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label har kopierats!'),
      backgroundColor: Colors.green,
    ),
  );
}

Future<void> _launchMaps(BuildContext context, String address) async {
  final Uri mapUri = Uri.parse('https://maps.google.com/maps?q=${Uri.encodeComponent(address)}');
  try {
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      throw 'Could not launch $mapUri';
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kunde inte öppna kart-appen.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// 🟢 HELA DENNA FUNKTION ÄR OMBYGGD FÖR EN PROFFSIGARE LOOK
void showAdDetailDialog(BuildContext context, Ad ad) {
  showDialog(
    context: context,
    builder: (_) => _CustomDialog(
      // Skickar med logotypens sökväg till headern
      header: _DialogHeader(
        isSponsored: true,
        imagePath: ad.logoPath, // Använder logoPath som bild
      ),
      content: [
        // Visar titeln och en "Sponsrad"-tagg
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                ad.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: Colors.green, size: 24),
          ],
        ),
        const SizedBox(height: 24),
        if (ad.body.isNotEmpty) ...[
          _InfoCard(title: 'Beskrivning', children: [Text(ad.body, style: Theme.of(context).textTheme.bodyLarge)]),
          const SizedBox(height: 16),
        ],
        _InfoCard(
          title: 'Kontaktinformation',
          children: [
            InkWell(
              onTap: () => _launchMaps(context, ad.city),
              child: _DetailRow(icon: Icons.pin_drop_outlined, title: 'Plats (tryck för att visa på kartan)', subtitle: ad.city),
            ),
            if (ad.phone?.isNotEmpty ?? false)
              InkWell(
                onTap: () => _copyToClipboard(context, ad.phone!, 'Telefonnummer'),
                child: _DetailRow(icon: Icons.phone_outlined, title: 'Telefon (tryck för att kopiera)', subtitle: ad.phone!),
              ),
            if (ad.email?.isNotEmpty ?? false)
              InkWell(
                onTap: () => _copyToClipboard(context, ad.email!, 'E-postadress'),
                child: _DetailRow(icon: Icons.email_outlined, title: 'E-post (tryck för att kopiera)', subtitle: ad.email!),
              ),
          ],
        ),
      ],
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
          onPressed: () {
            final shareText = '''
Sponsrad annons från Fixli:
${ad.title}

${ad.body}

Stad: ${ad.city}
E-post: ${ad.email ?? 'saknas'}
Telefon: ${ad.phone ?? 'saknas'}
            ''';
            Share.share(shareText.trim());
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Dela annons'),
        ),
      ],
    ),
  );
}

class RequestDialog extends ConsumerStatefulWidget {
  final RequestWithUser requestWithUser;
  const RequestDialog({super.key, required this.requestWithUser});

  @override
  ConsumerState<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends ConsumerState<RequestDialog> {
  late Request _request;
  late User _user;

  @override
  void initState() {
    super.initState();
    _request = widget.requestWithUser.request;
    _user = widget.requestWithUser.user;
  }

  Future<void> _applyForJob() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final repo = locator<JobApplicationRepository>();
    final hasApplied = await repo.hasUserApplied(_request.id, currentUser.id);
    if (hasApplied) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Du har redan sökt detta uppdrag.')));
      return;
    }

    final messageController = TextEditingController();
    final bool? shouldApply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anmäl intresse'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ditt meddelande till uppdragsgivaren:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Hej! Jag kan hjälpa till...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Avbryt')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Skicka ansökan'),
          ),
        ],
      ),
    );

    if (shouldApply == true) {
      await repo.applyForJob(
        requestId: _request.id,
        applicantId: currentUser.id,
        message: messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Din intresseanmälan är skickad!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _markAsCompletedByCreator() async {
    final repo = locator<RequestRepository>();
    await repo.markRequestAsCompleted(requestId: _request.id);

    ref.invalidate(requestListProvider);
    ref.invalidate(latestRequestsProvider);
    ref.invalidate(myRequestsProvider);

    if (mounted) Navigator.of(context).pop();
  }

  void _showRatingDialog({required int ratedUserId, required String ratedUserName}) {
    final ratingRepo = locator<RatingRepository>();
    final currentUserId = ref.read(authProvider).user!.id;
    int ratingValue = 3;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Betygsätt $ratedUserName'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Hur nöjd är du? (1-5 stjärnor)'),
          StatefulBuilder(builder: (context, setDialogState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                icon: Icon(index < ratingValue ? Icons.star : Icons.star_border, color: Colors.amber, size: 30),
                onPressed: () => setDialogState(() => ratingValue = index + 1),
              )),
            );
          }),
          TextField(controller: commentController, decoration: const InputDecoration(labelText: 'Kommentar (valfri)'), maxLines: 3)
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Avbryt')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
            onPressed: () async {
              await ratingRepo.submitRating(
                requestId: _request.id,
                ratingValue: ratingValue,
                comment: commentController.text,
                ratedUserId: ratedUserId,
                raterUserId: currentUserId,
              );
              ref.invalidate(hasRatedProvider(_request.id));
              ref.invalidate(userRatingProvider(ratedUserId));
              if (mounted) Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Skicka betyg'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    final isCreator = currentUser.id == _request.uploadedBy;
    final isFixer = currentUser.id == _request.fixerId;
    final hasAlreadyRated = ref.watch(hasRatedProvider(_request.id)).asData?.value ?? true;

    return _CustomDialog(
      header: _DialogHeader(imagePath: _request.imagePath),
      content: [
        Text(_request.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_request.body?.isNotEmpty ?? false) ...[
          _InfoCard(title: 'Beskrivning', children: [Text(_request.body!, style: Theme.of(context).textTheme.bodyLarge)]),
          const SizedBox(height: 16),
        ],
        _InfoCard(
          title: 'Uppdragsinformation',
          children: [
            InkWell(
              onTap: () => _launchMaps(context, _request.location),
              child: _DetailRow(icon: Icons.pin_drop_outlined, title: 'Plats (tryck för att visa på kartan)', subtitle: _request.location),
            ),
            _DetailRow(icon: Icons.sell_outlined, title: 'Ersättning', subtitle: '${_request.price} kr'),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              title: 'Skapat',
              subtitle: timeago.format(_request.createdAt, locale: 'sv'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Kontaktinformation',
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: _user.id, userName: _user.name)));
              },
              child: _DetailRow(icon: Icons.person_outline, title: 'Namn (Klicka för att se profil)', subtitle: _user.name),
            ),
            if (_user.phone?.isNotEmpty ?? false)
              InkWell(
                onTap: () => _copyToClipboard(context, _user.phone!, 'Telefonnummer'),
                child: _DetailRow(icon: Icons.phone_outlined, title: 'Telefon (tryck för att kopiera)', subtitle: _user.phone!),
              ),
            if (_user.email.isNotEmpty)
              InkWell(
                onTap: () => _copyToClipboard(context, _user.email, 'E-postadress'),
                child: _DetailRow(icon: Icons.email_outlined, title: 'E-post (tryck för att kopiera)', subtitle: _user.email),
              ),
            if (_request.contactPreference?.isNotEmpty ?? false)
              _DetailRow(icon: Icons.chat_bubble_outline, title: 'Önskemål', subtitle: _request.contactPreference!),
          ],
        ),
      ],
      actions: [
        if (!isCreator && _request.status == 'open')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: _applyForJob,
            icon: const Icon(Icons.handyman_outlined, size: 18),
            label: const Text('Anmäl intresse'),
          ),
        if (isCreator && _request.status == 'open')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantsScreen(requestId: _request.id)));
            },
            icon: const Icon(Icons.people_outline, size: 18),
            label: const Text('Visa sökande'),
          ),
        if (isCreator && _request.status == 'in_progress')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: _markAsCompletedByCreator,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Markera som slutförd'),
          ),
        if (_request.status == 'completed' && isCreator && _request.fixerId != null && !hasAlreadyRated)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () => _showRatingDialog(ratedUserId: _request.fixerId!, ratedUserName: "Fixaren"),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Betygsätt Fixaren'),
          ),
        if (_request.status == 'completed' && isFixer && !hasAlreadyRated)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () => _showRatingDialog(ratedUserId: _request.uploadedBy, ratedUserName: _user.name),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Betygsätt Skaparen'),
          ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.1),
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () {
            final text = '''
Uppdrag från Fixli: ${_request.title}

${_request.body ?? ''}

Upplagt av: ${_user.name}
Plats: ${_request.location}
Pris: ${_request.price} kr
Kontakt: ${_user.email} / ${_user.phone ?? ''}
Kontaktönskemål: ${_request.contactPreference ?? 'Inga'}
            ''';
            Share.share(text.trim());
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Dela uppdrag'),
        ),
      ],
    );
  }
}

class _CustomDialog extends StatelessWidget {
  final Widget header;
  final List<Widget> content;
  final List<Widget> actions;
  const _CustomDialog({required this.header, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: actions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String? title;
  final bool isSponsored;
  final String? imagePath;
  const _DialogHeader({this.title, this.isSponsored = false, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final double? headerHeight = imagePath != null ? 180 : 120;

    return GestureDetector(
      onTap: imagePath != null ? () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PhotoViewerScreen(imagePath: imagePath!),
          ),
        );
      } : null,
      child: Container(
        height: headerHeight,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          image: imagePath != null ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)) : null,
          color: Colors.teal,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/fixli_logo.png', height: 60, color: Colors.white),
                  if (isSponsored) ...[
                    const SizedBox(height: 8),
                    Text(
                        'Sponsrad Annonsör',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)
                    ),
                  ]
                ],
              ),
            ),
            if (imagePath != null)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Tryck för att zooma', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _DetailRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoViewerScreen extends StatelessWidget {
  final String imagePath;
  const PhotoViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
      ),
    );
  }
}