// lib/presentation/screens/category_detail_screen.dart

import 'dart:io';
import 'package:fixli_app/presentation/providers/ad_provider.dart';
import 'package:fixli_app/presentation/providers/auth_provider.dart';
import 'package:fixli_app/presentation/screens/ad_radius_filter_screen.dart';
import 'package:fixli_app/presentation/widgets/detail_dialogs.dart';
import 'package:fixli_app/presentation/widgets/empty_state_widget.dart';
import 'package:fixli_app/presentation/widgets/shimmer_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adCategoryFilterProvider.notifier).state = widget.categoryName;
      ref.read(showAdListProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(filteredAdsProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = (user?.name.toLowerCase() == 'admin');
    final cities = ref.watch(adUniqueCitiesProvider);
    final selectedCity = ref.watch(adCityFilterProvider);
    final radiusCenter = ref.watch(adRadiusCenterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Sök på titel, stad, etc...', prefixIcon: Icon(Icons.search)),
                    onChanged: (value) { ref.read(adSearchQueryProvider.notifier).state = value; },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.travel_explore, color: radiusCenter != null ? Colors.white : Colors.black54),
                        label: Text('Avstånd', style: TextStyle(color: radiusCenter != null ? Colors.white : Colors.black87)),
                        backgroundColor: radiusCenter != null ? Colors.teal : Colors.grey.shade300,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdRadiusFilterScreen()));
                        },
                      ),
                      const SizedBox(width: 10),
                      if (cities.length > 1)
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_city, color: Colors.teal),
                              const SizedBox(width: 10),
                              Flexible(
                                child: DropdownButton<String>(
                                  value: selectedCity, isExpanded: true,
                                  items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (value) { if (value != null) { ref.read(adCityFilterProvider.notifier).state = value; } },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (radiusCenter != null)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      child: const Text('Nollställ avståndsfilter'),
                      onPressed: () => ref.read(adRadiusCenterProvider.notifier).state = null,
                    ),
                ],
              ),
            ),
          ),
          adsAsync.when(
            loading: () => const SliverToBoxAdapter(child: ShimmerListPlaceholder()),
            error: (err, st) => SliverToBoxAdapter(child: Center(child: Text('Fel: $err'))),
            data: (ads) {
              if (ads.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    title: 'Inga annonser',
                    subtitle: 'Det finns inga utvalda företag som matchar dina filter.',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, index) {
                    final ad = ads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => showAdDetailDialog(context, ad),
                        child: Row(
                          children: [
                            // 🟢 Visar logotypen om den finns, annars en platshållare
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: ad.logoPath != null
                                  ? Image.file(File(ad.logoPath!), fit: BoxFit.cover)
                                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.business_center_outlined, color: Colors.grey, size: 40)),
                            ),
                            // Textinnehållet
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ad.city,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    if(isAdmin)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => ref.read(adListProvider.notifier).deleteAd(ad.id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: ads.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}