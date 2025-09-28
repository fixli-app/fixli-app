// lib/data/models/article_model.dart
import 'package:equatable/equatable.dart';
import 'package:fixli_app/data/datasources/app_database.dart'; // Importera din Drift-genererade databas

class ArticleModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final int authorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
  });

  // 🟢 Factory-konstruktor för att skapa en ArticleModel från en Drift NewsArticle entitet
  factory ArticleModel.fromDrift(NewsArticle newsArticle) {
    return ArticleModel(
      id: newsArticle.id,
      title: newsArticle.title,
      content: newsArticle.content,
      imageUrl: newsArticle.imageUrl,
      authorId: newsArticle.authorId,
      createdAt: newsArticle.createdAt,
      updatedAt: newsArticle.updatedAt,
    );
  }

  // 🟢 Metod för att skapa en kopia av ArticleModel med ändrade fält
  ArticleModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    int? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    imageUrl,
    authorId,
    createdAt,
    updatedAt,
  ];
}