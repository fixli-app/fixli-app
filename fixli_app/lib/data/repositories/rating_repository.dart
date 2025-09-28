// lib/data/repositories/rating_repository.dart

import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:drift/drift.dart';

class AverageRating {
  final double average;
  final int count;
  AverageRating(this.average, this.count);
}

class RatingDetails {
  final Rating rating;
  final User rater;
  final String requestTitle;
  RatingDetails({required this.rating, required this.rater, required this.requestTitle});
}

class RatingRepository {
  final AppDatabase _db;
  RatingRepository(this._db);

  Future<void> submitRating({
    required String requestId,
    required int ratingValue,
    String? comment,
    required int ratedUserId,
    required int raterUserId,
  }) async {
    final newRating = RatingsCompanion.insert(
      requestId: requestId,
      ratingValue: ratingValue,
      ratedUserId: ratedUserId,
      raterUserId: raterUserId,
      createdAt: DateTime.now(),
      comment: Value(comment),
    );
    await _db.into(_db.ratings).insert(newRating);

    final ratingsForThisRequest = await (_db.select(_db.ratings)..where((r) => r.requestId.equals(requestId))).get();
    if (ratingsForThisRequest.length >= 2) {
      final companion = RequestsCompanion(status: const Value('archived'));
      await (_db.update(_db.requests)..where((r) => r.id.equals(requestId))).write(companion);
    }
  }

  Future<List<RatingDetails>> getRatingsForUser(int userId) {
    final query = _db.select(_db.ratings).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.ratings.raterUserId)),
      innerJoin(_db.requests, _db.requests.id.equalsExp(_db.ratings.requestId)),
    ])
      ..where(_db.ratings.ratedUserId.equals(userId));

    return query.get().then((rows) {
      return rows.map((row) {
        return RatingDetails(
          rating: row.readTable(_db.ratings),
          rater: row.readTable(_db.users),
          requestTitle: row.readTable(_db.requests).title,
        );
      }).toList();
    });
  }

  Future<bool> hasUserRatedRequest({required String requestId, required int raterUserId}) async {
    final existingRating = await (_db.select(_db.ratings)
      ..where((r) => r.requestId.equals(requestId) & r.raterUserId.equals(raterUserId)))
        .getSingleOrNull();
    return existingRating != null;
  }

  Future<AverageRating> getAverageRatingForUser(int userId) async {
    final ratingsQuery = _db.select(_db.ratings)..where((r) => r.ratedUserId.equals(userId));
    final ratings = await ratingsQuery.get();
    if (ratings.isEmpty) {
      return AverageRating(0.0, 0);
    }
    final totalStars = ratings.map((r) => r.ratingValue).reduce((a, b) => a + b);
    final average = totalStars / ratings.length;
    return AverageRating((average * 10).round() / 10, ratings.length);
  }
}