// lib/data/repositories/news_repository.dart

import 'dart:io'; // För filhantering om bilder ska sparas lokalt
import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/models/article_model.dart'; // Importera din ArticleModel
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class NewsRepository {
  final AppDatabase _db;

  NewsRepository(this._db);

  // Hämtar alla artiklar, sorterade efter skapandedatum (senaste först)
  // Observera att vi använder en Stream för reaktiva uppdateringar, liknande NotificationRepository
  Stream<List<ArticleModel>> watchAllArticles() {
    return (_db.select(_db.newsArticles)
      ..orderBy([(n) => OrderingTerm(expression: n.createdAt, mode: OrderingMode.desc)]))
        .watch()
        .map((listOfNewsArticles) =>
        listOfNewsArticles.map((article) => ArticleModel.fromDrift(article)).toList());
  }

  // Hämtar en specifik artikel
  Future<ArticleModel?> getArticleById(String id) async {
    final newsArticle = await (_db.select(_db.newsArticles)..where((n) => n.id.equals(id))).getSingleOrNull();
    return newsArticle != null ? ArticleModel.fromDrift(newsArticle) : null;
  }

  // Skapar en ny artikel
  Future<void> createArticle({
    required String title,
    required String content,
    String? imageUrl,
    required int authorId,
    required String authorName, // Behövs för notiser/visning, men lagras ej i ArticleModel direkt
    File? imageFile, // För att hantera uppladdning av bild
  }) async {
    String? finalImagePath = imageUrl; // Använd befintlig URL om den finns

    // Hantera lokal bildfil om den tillhandahålls
    if (imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(imageFile.path);
      final newFileName = 'news_${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await imageFile.copy(newPath);
      finalImagePath = newFile.path; // Spara den lokala sökvägen
    }

    final newArticleId = const Uuid().v4();
    final now = DateTime.now();

    final newArticleCompanion = NewsArticlesCompanion.insert(
      id: newArticleId,
      title: title,
      content: content,
      imageUrl: Value(finalImagePath),
      authorId: authorId,
      createdAt: now,
      updatedAt: Value(now), // Sätt initial updatedAt till createdAt
    );
    await _db.into(_db.newsArticles).insert(newArticleCompanion);

    // 💡 OBS: Om du vill skicka en notis när en ny artikel skapas,
    // skulle du göra det här, t.ex. via en `NotificationRepository`.
    // För tillfället hoppar vi över det för att hålla fokus.
    // await locator<NotificationRepository>().createNotification(...)
  }

  // Uppdaterar en befintlig artikel
  Future<void> updateArticle({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    File? imageFile, // För att hantera uppladdning av ny bild
    bool deleteExistingImage = false, // För att markera om befintlig bild ska tas bort
  }) async {
    String? finalImagePath = imageUrl;

    if (deleteExistingImage) {
      // Radera gammal fil om den finns
      if (imageUrl != null) {
        final oldFile = File(imageUrl);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      finalImagePath = null; // Nollställ sökvägen i databasen
    } else if (imageFile != null) {
      // Radera gammal fil om en ny laddas upp
      if (imageUrl != null) {
        final oldFile = File(imageUrl);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(imageFile.path);
      final newFileName = 'news_${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await imageFile.copy(newPath);
      finalImagePath = newFile.path;
    }

    final updatedArticleCompanion = NewsArticlesCompanion(
      title: Value(title),
      content: Value(content),
      imageUrl: Value(finalImagePath),
      updatedAt: Value(DateTime.now()),
    );
    await (_db.update(_db.newsArticles)..where((n) => n.id.equals(id)))
        .write(updatedArticleCompanion);
  }


  // Raderar en artikel
  Future<void> deleteArticle(String id) async {
    // 💡 OBS: Om artikeln har en bild, vill du troligen radera den filen också.
    // Hämta artikeln först för att få imageUrl.
    final articleToDelete = await getArticleById(id);
    if (articleToDelete?.imageUrl != null) {
      final file = File(articleToDelete!.imageUrl!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await (_db.delete(_db.newsArticles)..where((n) => n.id.equals(id))).go();
  }
}