// lib/data/repositories/request_repository.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class RequestWithUser {
  final Request request;
  final User user;
  RequestWithUser({required this.request, required this.user});
}

class RequestRepository {
  final AppDatabase _db;
  RequestRepository(this._db);

  Future<void> createRequest({
    required String title,
    required String location,
    required String time,
    required String price,
    required int userId,
    String? body,
    String? contactPreference,
    File? imageFile,
    double? latitude,
    double? longitude,
  }) async {
    String? finalImagePath;
    if (imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(imageFile.path);
      final newFileName = '${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await imageFile.copy(newPath);
      finalImagePath = newFile.path;
    }
    final now = DateTime.now();
    final newRequest = RequestsCompanion.insert(
      id: const Uuid().v4(),
      title: title,
      body: Value(body),
      location: location,
      price: price,
      uploadedBy: userId,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      contactPreference: Value(contactPreference),
      imagePath: Value(finalImagePath),
      status: const Value('open'),
      latitude: Value(latitude),
      longitude: Value(longitude),
    );
    await _db.into(_db.requests).insert(newRequest);
  }

  Future<void> updateRequest({
    required String requestId,
    required String title,
    required String body,
    required String location,
    required String price,
    required String contactPreference
  }) async {
    final companion = RequestsCompanion(
      title: Value(title),
      body: Value(body),
      location: Value(location),
      price: Value(price),
      contactPreference: Value(contactPreference),
    );
    await (_db.update(_db.requests)..where((r) => r.id.equals(requestId))).write(companion);
  }

  Future<void> assignFixerToRequest({required String requestId, required int fixerId}) async {
    final companion = RequestsCompanion(
      status: const Value('in_progress'),
      fixerId: Value(fixerId),
    );
    await (_db.update(_db.requests)..where((r) => r.id.equals(requestId))).write(companion);
  }

  Future<void> markRequestAsCompleted({required String requestId}) async {
    final companion = RequestsCompanion(status: const Value('completed'));
    await (_db.update(_db.requests)..where((r) => r.id.equals(requestId))).write(companion);
  }

  Future<List<RequestWithUser>> _mapRowsToRequestsWithUsers(dynamic aQuery) async {
    final rows = await aQuery.get();
    final mappedIterable = rows.map((row) {
      return RequestWithUser(
        request: row.readTable(_db.requests),
        user: row.readTable(_db.users),
      );
    });
    return List<RequestWithUser>.from(mappedIterable);
  }

  Future<List<RequestWithUser>> getActiveRequests() async {
    final now = DateTime.now();
    await (_db.delete(_db.requests)..where((r) => r.expiresAt.isSmallerThan(Constant(now)))).go();
    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.status.equals('archived').not())
      ..orderBy([OrderingTerm(expression: _db.requests.createdAt, mode: OrderingMode.desc)]);
    return _mapRowsToRequestsWithUsers(query);
  }

  Future<List<RequestWithUser>> getLatestRequests({int limit = 5}) async {
    final now = DateTime.now();
    await (_db.delete(_db.requests)..where((r) => r.expiresAt.isSmallerThan(Constant(now)))).go();
    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.status.equals('archived').not())
      ..orderBy([OrderingTerm(expression: _db.requests.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);
    return _mapRowsToRequestsWithUsers(query);
  }

  Future<List<RequestWithUser>> getRequestsForUser(int userId) async {
    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.uploadedBy.equals(userId))
      ..orderBy([OrderingTerm(expression: _db.requests.createdAt, mode: OrderingMode.desc)]);
    return _mapRowsToRequestsWithUsers(query);
  }

  Future<void> deleteRequest(String requestId) async {
    await (_db.delete(_db.requests)..where((r) => r.id.equals(requestId))).go();
  }

  Future<List<RequestWithUser>> getMyApplications(int applicantId) async {
    final applicationsQuery = _db.select(_db.jobApplications)
      ..where((tbl) => tbl.applicantId.equals(applicantId));
    final applications = await applicationsQuery.get();
    final requestIds = applications.map((app) => app.requestId).toList();

    if (requestIds.isEmpty) {
      return [];
    }

    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.id.isIn(requestIds))
      ..orderBy([OrderingTerm(expression: _db.requests.createdAt, mode: OrderingMode.desc)]);

    return _mapRowsToRequestsWithUsers(query);
  }

  Future<List<RequestWithUser>> getMyFixerJobs(int fixerId) async {
    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.fixerId.equals(fixerId))
      ..orderBy([OrderingTerm(expression: _db.requests.createdAt, mode: OrderingMode.desc)]);

    return _mapRowsToRequestsWithUsers(query);
  }

  // 🟢 NY METOD: Hämtar ett enstaka uppdrag baserat på dess ID
  Future<RequestWithUser?> getRequestById(String requestId) async {
    final query = _db.select(_db.requests).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.requests.uploadedBy))
    ])
      ..where(_db.requests.id.equals(requestId));

    final result = await query.getSingleOrNull();

    if (result != null) {
      return RequestWithUser(
        request: result.readTable(_db.requests),
        user: result.readTable(_db.users),
      );
    }
    return null;
  }
}