// lib/presentation/providers/ad_provider.dart

import 'dart:async';
import 'dart:io'; // 🟢 Ny import
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/repositories/ad_repository.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haversine_distance/haversine_distance.dart';

class AdListNotifier extends StateNotifier<AsyncValue<List<Ad>>> {
  final AdRepository _adRepository = locator<AdRepository>();
  final Ref _ref;

  AdListNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchAds();
  }

  Future<void> fetchAds() async {
    state = const AsyncValue.loading();
    try {
      final ads = await _adRepository.getActiveAds();
      state = AsyncValue.data(ads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addAd({
    required String title,
    required String body,
    required String city,
    required String category,
    String? email,
    String? phone,
    double? latitude,
    double? longitude,
    File? logoFile, // 🟢 Ny parameter för logotypen
  }) async {
    try {
      await _adRepository.createAd(
          title: title, body: body, city: city, category: category,
          email: email, phone: phone, latitude: latitude, longitude: longitude,
          logoFile: logoFile // 🟢 Skickar vidare logotypen
      );
      await fetchAds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      await _adRepository.deleteAd(adId);
      await fetchAds();
    } catch (e) {
      // Hantera eventuellt fel
    }
  }
}

final adListProvider = StateNotifierProvider<AdListNotifier, AsyncValue<List<Ad>>>((ref) {
  return AdListNotifier(ref);
});

// --- Providers för filtrering av annonser ---

final adSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final adCityFilterProvider = StateProvider.autoDispose<String>((ref) => 'Alla');
final adCategoryFilterProvider = StateProvider.autoDispose<String>((ref) => 'Alla');
final showAdListProvider = StateProvider.autoDispose<bool>((ref) => false);

final adRadiusCenterProvider = StateProvider.autoDispose<LatLng?>((ref) => null);
final adRadiusDistanceProvider = StateProvider.autoDispose<double>((ref) => 10.0);

final adUniqueCitiesProvider = Provider.autoDispose<List<String>>((ref) {
  final allAds = ref.watch(adListProvider);
  return allAds.when(
    data: (ads) {
      final cities = ads.map((ad) => ad.city).toSet().toList();
      cities.sort();
      return ['Alla', ...cities];
    },
    loading: () => ['Alla'],
    error: (e, st) => ['Alla'],
  );
});

final filteredAdsProvider = Provider.autoDispose<AsyncValue<List<Ad>>>((ref) {
  final allAds = ref.watch(adListProvider);
  final searchQuery = ref.watch(adSearchQueryProvider);
  final selectedCity = ref.watch(adCityFilterProvider);
  final selectedCategory = ref.watch(adCategoryFilterProvider);
  final radiusCenter = ref.watch(adRadiusCenterProvider);
  final radiusDistance = ref.watch(adRadiusDistanceProvider);

  return allAds.when(
    data: (ads) {
      final filtered = ads.where((ad) {
        // Sök-matchning
        final query = searchQuery.toLowerCase();
        final searchMatch = query.isEmpty ||
            ad.title.toLowerCase().contains(query) ||
            ad.body.toLowerCase().contains(query) ||
            ad.city.toLowerCase().contains(query);

        if (!searchMatch) return false;

        // Kategori-matchning
        final categoryMatch = selectedCategory == 'Alla' || ad.category == selectedCategory;
        if (!categoryMatch) return false;

        // Plats-matchning (antingen stad ELLER radie)
        final isRadiusFilterActive = radiusCenter != null;

        if (isRadiusFilterActive) {
          if (ad.latitude != null && ad.longitude != null) {
            final start = Location(radiusCenter.latitude, radiusCenter.longitude);
            final end = Location(ad.latitude!, ad.longitude!);
            final distanceInKm = HaversineDistance().haversine(start, end, Unit.KM);
            return distanceInKm <= radiusDistance;
          }
          return false; // Annonser utan koordinater visas inte i radie-sök
        } else {
          // Använd stadsfiltret om inget avståndsfilter är aktivt
          return selectedCity == 'Alla' || ad.city == selectedCity;
        }

      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});