// lib/presentation/widgets/shimmer_list_placeholder.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListPlaceholder extends StatelessWidget {
  final int itemCount;
  const ShimmerListPlaceholder({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      enabled: true,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  // 🟢 KORRIGERING: Ändrad från vit till grå
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 4.0),
                      Container(
                        width: double.infinity,
                        height: 16.0,
                        // 🟢 KORRIGERING: Ändrad från vit till grå
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        width: 150.0,
                        height: 12.0,
                        // 🟢 KORRIGERING: Ändrad från vit till grå
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}