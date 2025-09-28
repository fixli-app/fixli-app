// lib/data/repositories/job_application_repository.dart

import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/repositories/notification_repository.dart';
import 'package:fixli_app/data/repositories/rating_repository.dart';
import 'package:fixli_app/service_locator.dart';

class ApplicantWithDetails {
  final JobApplication application;
  final User applicant;
  final AverageRating averageRating;

  ApplicantWithDetails({
    required this.application,
    required this.applicant,
    required this.averageRating,
  });
}

class JobApplicationRepository {
  final AppDatabase _db;
  JobApplicationRepository(this._db);

  Future<void> applyForJob({
    required String requestId,
    required int applicantId,
    required String message,
  }) async {
    final newApplication = JobApplicationsCompanion.insert(
      requestId: requestId,
      applicantId: applicantId,
      message: message,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.jobApplications).insert(newApplication);

    // 🟢 SKAPA EN NOTIS TILL UPDRAGETS SKAPARE
    // 1. Hämta först uppdraget för att se vem som skapade det
    final request = await (_db.select(_db.requests)..where((r) => r.id.equals(requestId))).getSingle();
    final applicant = await (_db.select(_db.users)..where((u) => u.id.equals(applicantId))).getSingle();

    // 2. Skapa notisen
    await locator<NotificationRepository>().createNotification(
      userId: request.uploadedBy, // Notisen är till den som skapade uppdraget
      title: 'Ny ansökan till ditt uppdrag!',
      body: '${applicant.name} har anmält intresse för ditt uppdrag "${request.title}".',
      requestId: requestId,
    );
  }

  Future<List<ApplicantWithDetails>> getApplicantsForRequest(String requestId) async {
    final ratingRepo = locator<RatingRepository>();
    final query = _db.select(_db.jobApplications).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.jobApplications.applicantId))
    ])
      ..where(_db.jobApplications.requestId.equals(requestId));

    final rows = await query.get();

    final results = await Future.wait(rows.map((row) async {
      final user = row.readTable(_db.users);
      final application = row.readTable(_db.jobApplications);
      final rating = await ratingRepo.getAverageRatingForUser(user.id);

      return ApplicantWithDetails(
        application: application,
        applicant: user,
        averageRating: rating,
      );
    }));

    return results;
  }

  Future<void> acceptApplicant({
    required int applicationId,
    required String requestId,
    required int applicantId,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.jobApplications)..where((tbl) => tbl.requestId.equals(requestId)))
          .write(const JobApplicationsCompanion(status: Value('rejected')));

      await (_db.update(_db.jobApplications)..where((tbl) => tbl.id.equals(applicationId)))
          .write(const JobApplicationsCompanion(status: Value('accepted')));

      final requestCompanion = RequestsCompanion(
        fixerId: Value(applicantId),
        status: const Value('in_progress'),
      );
      await (_db.update(_db.requests)..where((tbl) => tbl.id.equals(requestId))).write(requestCompanion);

      // 🟢 SKAPA EN NOTIS TILL DEN VALDA FIXAREN
      final request = await (_db.select(_db.requests)..where((r) => r.id.equals(requestId))).getSingle();
      await locator<NotificationRepository>().createNotification(
        userId: applicantId, // Notisen är till den som blev vald
        title: 'Du har blivit vald för ett uppdrag!',
        body: 'Du har blivit vald som fixare för uppdraget "${request.title}".',
        requestId: requestId,
      );
    });
  }

  Future<bool> hasUserApplied(String requestId, int applicantId) async {
    final existing = await (_db.select(_db.jobApplications)
      ..where((tbl) => tbl.requestId.equals(requestId) & tbl.applicantId.equals(applicantId)))
        .getSingleOrNull();
    return existing != null;
  }
}