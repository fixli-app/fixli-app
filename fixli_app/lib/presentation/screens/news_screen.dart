// lib/presentation/screens/news_screen.dart

import 'package:fixli_app/presentation/providers/news_provider.dart';
import 'dart:io';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // För datumformatering

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyheter'),
      ),
      body: newsAsyncValue.when(
        loading: () => const ShimmerListPlaceholder(itemCount: 5), // Visar en laddningsindikator
        error: (error, stack) => Center(child: Text('Kunde inte ladda nyheter: $error')),
        data: (articles) {
          if (articles.isEmpty) {
            return const EmptyStateWidget(
              title: 'Inga nyheter just nu',
              subtitle: 'Här kommer vi publicera spännande uppdateringar från Fixli!',
            );
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    // Navigera till en detaljvy för nyhetsartikeln
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(articleId: article.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.imageUrl != null) ...[
                          Image.file(
                            File(article.imageUrl!),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          article.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(article.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ArticleDetailScreen(articleId: article.id),
                                ),
                              );
                            },
                            child: const Text('Läs mer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// En enkel skärm för att visa detaljer om en artikel
class ArticleDetailScreen extends ConsumerWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsyncValue = ref.watch(singleArticleProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyhetsdetaljer'),
      ),
      body: articleAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Kunde inte ladda artikel: $error')),
        data: (article) {
          if (article == null) {
            return const Center(child: Text('Artikeln hittades inte.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(article.imageUrl!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 70, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Publicerad: ${DateFormat('yyyy-MM-dd HH:mm').format(article.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                if (article.updatedAt != null && !article.updatedAt!.isAtSameMomentAs(article.createdAt))
                  Text(
                    'Senast uppdaterad: ${DateFormat('yyyy-MM-dd HH:mm').format(article.updatedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                const Divider(height: 32),
                Text(
                  article.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}