// lib/presentation/screens/admin_news_screen.dart

import 'dart:io';
import 'package:fixli_app/data/models/article_model.dart';
import 'package:fixli_app/presentation/providers/news_provider.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // För att välja bilder
import 'package:intl/intl.dart';

class AdminNewsScreen extends ConsumerWidget {
  const AdminNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hantera Nyheter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigera till en skärm/dialog för att skapa en ny artikel
              _showArticleForm(context, ref);
            },
            tooltip: 'Skapa ny artikel',
          ),
        ],
      ),
      body: newsAsyncValue.when(
        loading: () => const ShimmerListPlaceholder(itemCount: 5),
        error: (error, stack) => Center(child: Text('Kunde inte ladda nyheter: $error')),
        data: (articles) {
          if (articles.isEmpty) {
            return const EmptyStateWidget(
              title: 'Inga nyheter att hantera',
              subtitle: 'Använd plusknappen för att skapa din första nyhetsartikel.',
            );
          }
          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: article.imageUrl != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.file(
                      File(article.imageUrl!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                    ),
                  )
                      : const Icon(Icons.article, size: 40, color: Colors.grey),
                  title: Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Skapad: ${DateFormat('yyyy-MM-dd').format(article.createdAt)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () {
                          _showArticleForm(context, ref, article: article);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(context, ref, article);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showArticleForm(BuildContext context, WidgetRef ref, {ArticleModel? article}) {
    final TextEditingController titleController = TextEditingController(text: article?.title);
    final TextEditingController contentController = TextEditingController(text: article?.content);
    File? selectedImage;
    bool deleteExistingImage = false; // Flagga för att indikera om befintlig bild ska tas bort

    // State för den aktuella bildens sökväg (om den finns och inte ska tas bort)
    String? currentImageUrl = article?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder( // Använd StatefulBuilder för att hantera state inuti bottom sheet
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article == null ? 'Skapa ny artikel' : 'Redigera artikel',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Rubrik'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(labelText: 'Innehåll'),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),

                      // Bildhantering
                      if (currentImageUrl != null && !deleteExistingImage) ...[
                        Text('Befintlig bild:', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Image.file(
                          File(currentImageUrl!),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100, width: 100, color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Ta bort befintlig bild'),
                          onPressed: () {
                            setModalState(() {
                              deleteExistingImage = true;
                              selectedImage = null; // Se till att ingen ny bild är vald samtidigt
                            });
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                      ],
                      if (selectedImage != null) ...[
                        Text('Ny bild vald:', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Image.file(
                          selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Ångra bildval'),
                          onPressed: () {
                            setModalState(() {
                              selectedImage = null;
                            });
                          },
                        ),
                      ] else if (currentImageUrl == null || deleteExistingImage) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Välj bild'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setModalState(() {
                                selectedImage = File(pickedFile.path);
                                deleteExistingImage = false; // Om en ny bild väljs, ta inte bort den gamla
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Avbryt'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final content = contentController.text.trim();

                              if (title.isEmpty || content.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Rubrik och innehåll får inte vara tomma.')),
                                );
                                return;
                              }

                              final newsNotifier = ref.read(newsListProvider.notifier);
                              bool success;

                              if (article == null) {
                                success = await newsNotifier.createArticle(
                                  title: title,
                                  content: content,
                                  imageFile: selectedImage,
                                );
                              } else {
                                success = await newsNotifier.updateArticle(
                                  id: article.id,
                                  title: title,
                                  content: content,
                                  imageUrl: currentImageUrl, // Skicka med befintlig URL
                                  imageFile: selectedImage,
                                  deleteExistingImage: deleteExistingImage,
                                );
                              }

                              if (success) {
                                Navigator.pop(context); // Stäng modalen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(article == null ? 'Artikel skapad!' : 'Artikel uppdaterad!'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Kunde inte spara artikel. Försök igen.'),
                                  ),
                                );
                              }
                            },
                            child: Text(article == null ? 'Skapa' : 'Spara'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // Extra padding längst ner
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ArticleModel article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Radera artikel?'),
        content: Text('Är du säker på att du vill radera "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Stäng dialogrutan
              await ref.read(newsListProvider.notifier).deleteArticle(article.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Artikel raderad!')),
              );
            },
            child: const Text('Radera', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}