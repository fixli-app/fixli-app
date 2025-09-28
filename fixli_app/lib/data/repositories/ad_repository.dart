// lib/data/repositories/ad_repository.dart

import 'dart:io'; // 🟢 Ny import
import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart'; // 🟢 Ny import
import 'package:path/path.dart' as p; // 🟢 Ny import

class AdRepository {
  final AppDatabase _db;
  AdRepository(this._db);

  Future<void> createAd({
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
    final now = DateTime.now();

    // 🟢 Ny logik för att spara logotypen
    String? finalLogoPath;
    if (logoFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(logoFile.path);
      final newFileName = 'ad_logo_${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await logoFile.copy(newPath);
      finalLogoPath = newFile.path;
    }

    final newAd = SponsoredAdsCompanion.insert(
      id: const Uuid().v4(),
      title: title,
      body: body,
      city: city,
      category: Value(category),
      createdAt: now,
      expiresAt: now.add(const Duration(days: 365)),
      email: Value(email),
      phone: Value(phone),
      latitude: Value(latitude),
      longitude: Value(longitude),
      logoPath: Value(finalLogoPath), // 🟢 Sparar sökvägen till logotypen
    );
    await _db.into(_db.sponsoredAds).insert(newAd);
  }

  Future<List<Ad>> getActiveAds() async {
    final now = DateTime.now();
    await (_db.delete(_db.sponsoredAds)..where((ad) => ad.expiresAt.isSmallerThan(Constant(now)))).go();
    final query = _db.select(_db.sponsoredAds)..orderBy([(ad) => OrderingTerm(expression: ad.createdAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  Future<void> deleteAd(String adId) async {
    await (_db.delete(_db.sponsoredAds)..where((ad) => ad.id.equals(adId))).go();
  }
}