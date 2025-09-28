// lib/presentation/providers/news_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:fixli_app/data/models/article_model.dart';
import 'package:fixli_app/data/repositories/news_repository.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart'; // Behövs för att hämta aktuell användare
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier för att hantera listan av nyhetsartiklar och CRUD-operationer
class NewsListNotifier extends StateNotifier<AsyncValue<List<ArticleModel>>> {
  final NewsRepository _newsRepository = locator<NewsRepository>();
  final Ref _ref;
  StreamSubscription? _articlesSubscription;

  NewsListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _startListeningToArticles();
  }

  void _startListeningToArticles() {
    _articlesSubscription?.cancel(); // Avbryt eventuellt befintlig prenumeration
    _articlesSubscription = _newsRepository.watchAllArticles().listen(
          (articles) {
        state = AsyncValue.data(articles);
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
  }

  // Metoder för CRUD-operationer
  Future<bool> createArticle({
    required String title,
    required String content,
    String? imageUrl,
    File? imageFile,
  }) async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) {
      state = AsyncValue.error('Ingen användare inloggad', StackTrace.current);
      return false;
    }

    // Vi skickar inte authorName till ArticleModel, men det kan vara bra att logga/hantera.
    // authorName är mest för UI-visning om vi vill visa vem som skrev artikeln.
    try {
      await _newsRepository.createArticle(
        title: title,
        content: content,
        imageUrl: imageUrl,
        authorId: currentUser.id,
        authorName: currentUser.name, // Används här om du skulle skapa en notis t.ex.
        imageFile: imageFile,
      );
      // _startListeningToArticles() kommer att uppdatera state automatiskt via streamen
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateArticle({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      await _newsRepository.updateArticle(
        id: id,
        title: title,
        content: content,
        imageUrl: imageUrl,
        imageFile: imageFile,
        deleteExistingImage: deleteExistingImage,
      );
      // _startListeningToArticles() kommer att uppdatera state automatiskt via streamen
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteArticle(String articleId) async {
    try {
      await _newsRepository.deleteArticle(articleId);
      // _startListeningToArticles() kommer att uppdatera state automatiskt via streamen
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _articlesSubscription?.cancel();
    super.dispose();
  }
}

// 🟢 Den globala providern för nyhetsartiklarna
final newsListProvider = StateNotifierProvider<NewsListNotifier, AsyncValue<List<ArticleModel>>>((ref) {
  return NewsListNotifier(ref);
});

// 🟢 En specifik provider för att hämta en enskild artikel (t.ex. för redigering eller detaljvy)
final singleArticleProvider = FutureProvider.autoDispose.family<ArticleModel?, String>((ref, articleId) async {
  final newsRepo = locator<NewsRepository>();
  return newsRepo.getArticleById(articleId);
});