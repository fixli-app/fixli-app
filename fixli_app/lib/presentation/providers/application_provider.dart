// lib/presentation/providers/application_provider.dart
import 'package:fixli_app/data/repositories/job_application_repository.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final applicantsProvider = FutureProvider.autoDispose.family<List<ApplicantWithDetails>, String>((ref, requestId) {
  final repo = locator<JobApplicationRepository>();
  return repo.getApplicantsForRequest(requestId);
});