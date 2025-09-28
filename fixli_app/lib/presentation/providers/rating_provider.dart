// lib/presentation/providers/rating_provider.dart

import 'package:fixli_app/data/models/user_model.dart';
import 'package:fixli_app/data/repositories/auth_repository.dart';
import 'package:fixli_app/data/repositories/rating_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// En ny klass för att hålla ALLA publika profildata
class PublicUserProfile {
  final UserModel user;
  final AverageRating averageRating;
  final List<RatingDetails> allRatings;

  PublicUserProfile({
    required this.user,
    required this.averageRating,
    required this.allRatings,
  });
}

// Denna klass behövs för den gamla providern som används på din egen profilsida.
class UserRatingProfile {
  final AverageRating averageRating;
  final List<RatingDetails> allRatings;

  UserRatingProfile({required this.averageRating, required this.allRatings});
}

// Uppdaterad provider som hämtar en fullständig profil
final publicUserProfileProvider = FutureProvider.autoDispose.family<PublicUserProfile, int>((ref, userId) async {
  final ratingRepository = locator<RatingRepository>();
  final authRepository = locator<AuthRepository>();

  // Hämta all information samtidigt
  final userFuture = authRepository.getUserById(userId);
  final averageFuture = ratingRepository.getAverageRatingForUser(userId);
  final allRatingsFuture = ratingRepository.getRatingsForUser(userId);

  final results = await Future.wait([userFuture, averageFuture, allRatingsFuture]);

  final user = results[0] as UserModel?;
  final averageRating = results[1] as AverageRating;
  final allRatings = results[2] as List<RatingDetails>;

  if (user == null) {
    throw Exception('Användaren kunde inte hittas');
  }

  return PublicUserProfile(
    user: user,
    averageRating: averageRating,
    allRatings: allRatings,
  );
});

// Den gamla providern finns kvar för att inte krascha andra delar (som profilsidan)
final userRatingProvider = FutureProvider.autoDispose.family<UserRatingProfile, int>((ref, userId) async {
  final ratingRepository = locator<RatingRepository>();
  final averageFuture = ratingRepository.getAverageRatingForUser(userId);
  final allRatingsFuture = ratingRepository.getRatingsForUser(userId);
  final results = await Future.wait([averageFuture, allRatingsFuture]);
  final averageRating = results[0] as AverageRating;
  final allRatings = results[1] as List<RatingDetails>;
  return UserRatingProfile(averageRating: averageRating, allRatings: allRatings);
});

final hasRatedProvider = FutureProvider.autoDispose.family<bool, String>((ref, requestId) {
  final raterId = ref.watch(authProvider).user?.id;
  if (raterId == null) return true;

  final ratingRepository = locator<RatingRepository>();
  return ratingRepository.hasUserRatedRequest(requestId: requestId, raterUserId: raterId);
});