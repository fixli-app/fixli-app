// lib/presentation/providers/request_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/presentation/providers/ad_provider.dart'; // 🟢 Ny import
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haversine_distance/haversine_distance.dart';

class RequestListNotifier extends StateNotifier<AsyncValue<List<RequestWithUser>>> {
  final RequestRepository _requestRepository = locator<RequestRepository>();
  final Ref _ref;
  RequestListNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchRequests();
  }
  Future<void> fetchRequests() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _requestRepository.getActiveRequests();
      state = AsyncValue.data(requests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<bool> addRequest({
    required String title, required String location, required String time,
    required String price, required int userId, String? body,
    String? contactPreference, File? imageFile,
    double? latitude, double? longitude,
  }) async {
    try {
      await _requestRepository.createRequest(
        title: title, location: location, time: time,
        price: price, userId: userId, body: body,
        contactPreference: contactPreference, imageFile: imageFile,
        latitude: latitude, longitude: longitude,
      );
      await fetchRequests();
      _ref.invalidate(latestRequestsProvider);
      _ref.invalidate(myRequestsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRequest({
    required String requestId,
    required String title,
    required String body,
    required String location,
    required String price,
    required String contactPreference
  }) async {
    try {
      await _requestRepository.updateRequest(
        requestId: requestId,
        title: title,
        body: body,
        location: location,
        price: price,
        contactPreference: contactPreference,
      );
      await fetchRequests();
      _ref.invalidate(latestRequestsProvider);
      _ref.invalidate(myRequestsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final requestListProvider = StateNotifierProvider<RequestListNotifier, AsyncValue<List<RequestWithUser>>>((ref) {
  return RequestListNotifier(ref);
});

final latestRequestsProvider = FutureProvider.autoDispose<List<RequestWithUser>>((ref) async {
  final requestRepository = locator<RequestRepository>();
  return requestRepository.getLatestRequests(limit: 5);
});

final myRequestsProvider = FutureProvider.autoDispose<List<RequestWithUser>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId != null) {
    final requestRepository = locator<RequestRepository>();
    return requestRepository.getRequestsForUser(userId);
  } else {
    return <RequestWithUser>[];
  }
});

// --- Providers för filtrering ---
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final cityFilterProvider = StateProvider.autoDispose<String>((ref) => 'Alla');

final radiusCenterProvider = StateProvider.autoDispose<LatLng?>((ref) => null);
final radiusDistanceProvider = StateProvider.autoDispose<double>((ref) => 10.0);

final uniqueCitiesProvider = Provider.autoDispose<List<String>>((ref) {
  final allRequests = ref.watch(requestListProvider);
  return allRequests.when(
    data: (requests) {
      final cities = requests.map((r) => r.request.location).toSet().toList();
      cities.sort();
      return ['Alla', ...cities];
    },
    loading: () => ['Alla'],
    error: (e, st) => ['Alla'],
  );
});

final filteredRequestsProvider = Provider.autoDispose<AsyncValue<List<RequestWithUser>>>((ref) {
  final allRequests = ref.watch(requestListProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCity = ref.watch(cityFilterProvider);
  final radiusCenter = ref.watch(radiusCenterProvider);
  final radiusDistance = ref.watch(radiusDistanceProvider);

  return allRequests.when(
    data: (requests) {
      final filteredList = requests.where((requestWithUser) {
        final request = requestWithUser.request;
        final user = requestWithUser.user;

        final query = searchQuery.toLowerCase();
        final searchMatch = query.isEmpty ||
            request.title.toLowerCase().contains(query) ||
            (request.body?.toLowerCase().contains(query) ?? false) ||
            request.location.toLowerCase().contains(query) ||
            request.price.toLowerCase().contains(query) ||
            user.name.toLowerCase().contains(query);

        if (!searchMatch) return false;

        final isRadiusFilterActive = radiusCenter != null;

        if (isRadiusFilterActive) {
          if (request.latitude != null && request.longitude != null) {
            final start = Location(radiusCenter.latitude, radiusCenter.longitude);
            final end = Location(request.latitude!, request.longitude!);
            final distanceInKm = HaversineDistance().haversine(start, end, Unit.KM);
            return distanceInKm <= radiusDistance;
          }
          return false;
        } else {
          return selectedCity == 'Alla' || request.location.contains(selectedCity);
        }
      }).toList();

      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final userRequestsProvider = FutureProvider.autoDispose.family<List<RequestWithUser>, int>((ref, userId) {
  final requestRepository = locator<RequestRepository>();
  return requestRepository.getRequestsForUser(userId);
});

final myApplicationsProvider = FutureProvider.autoDispose<List<RequestWithUser>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId != null) {
    final requestRepository = locator<RequestRepository>();
    return requestRepository.getMyApplications(userId);
  } else {
    return [];
  }
});

final myFixerJobsProvider = FutureProvider.autoDispose<List<RequestWithUser>>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId != null) {
    final requestRepository = locator<RequestRepository>();
    return requestRepository.getMyFixerJobs(userId);
  } else {
    return [];
  }
});

// 🟢 NYTT FÖR KARTAN 🟢

// En enkel klass för att representera ett objekt på kartan
class MappableItem {
  final String id;
  final String title;
  final LatLng position;
  final bool isSponsored;

  MappableItem({
    required this.id,
    required this.title,
    required this.position,
    this.isSponsored = false,
  });
}

// En provider som kombinerar vanliga uppdrag och sponsrade annonser till en lista
// som kan visas på kartan.
final mappableItemsProvider = Provider.autoDispose<List<MappableItem>>((ref) {
  final allRequests = ref.watch(requestListProvider).asData?.value ?? [];
  final allAds = ref.watch(adListProvider).asData?.value ?? [];

  final List<MappableItem> items = [];

  // Lägg till vanliga uppdrag
  for (final req in allRequests) {
    if (req.request.latitude != null && req.request.longitude != null) {
      items.add(MappableItem(
        id: req.request.id,
        title: req.request.title,
        position: LatLng(req.request.latitude!, req.request.longitude!),
      ));
    }
  }

  // Lägg till sponsrade annonser
  for (final ad in allAds) {
    if (ad.latitude != null && ad.longitude != null) {
      items.add(MappableItem(
        id: ad.id,
        title: ad.title,
        position: LatLng(ad.latitude!, ad.longitude!),
        isSponsored: true, // Markera att detta är en sponsrad annons
      ));
    }
  }

  return items;
});