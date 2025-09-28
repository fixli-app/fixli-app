// lib/presentation/screens/applicants_screen.dart
import 'package:fixli_app/data/repositories/job_application_repository.dart';
import 'package:fixli_app/presentation/providers/application_provider.dart';
import 'package:fixli_app/presentation/providers/request_provider.dart';
import 'package:fixli_app/presentation/screens/public_profile_screen.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApplicantsScreen extends ConsumerWidget {
  final String requestId;
  const ApplicantsScreen({super.key, required this.requestId});

  Future<void> _accept(BuildContext context, WidgetRef ref, ApplicantWithDetails applicant) async {
    await locator<JobApplicationRepository>().acceptApplicant(
      applicationId: applicant.application.id,
      requestId: requestId,
      applicantId: applicant.applicant.id,
    );
    ref.invalidate(applicantsProvider(requestId));
    ref.invalidate(requestListProvider);
    ref.invalidate(latestRequestsProvider);
    ref.invalidate(myRequestsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(applicantsProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sökande till uppdraget')),
      body: applicantsAsync.when(
        loading: () => const ShimmerListPlaceholder(),
        error: (err, st) => Center(child: Text('Fel: $err')),
        data: (applicants) {
          if (applicants.isEmpty) {
            return const EmptyStateWidget(title: 'Inga sökande', subtitle: 'Ingen har anmält intresse för detta uppdrag än.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: applicants.length,
            itemBuilder: (ctx, index) {
              final applicantDetails = applicants[index];
              final applicant = applicantDetails.applicant;
              final application = applicantDetails.application;
              final rating = applicantDetails.averageRating;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(applicant.name.substring(0, 1).toUpperCase())),
                  title: Text(applicant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${rating.average} (${rating.count} betyg)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('"${application.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _accept(context, ref, applicantDetails),
                    child: const Text('Välj'),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        userId: applicant.id,
                        userName: applicant.name,
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}