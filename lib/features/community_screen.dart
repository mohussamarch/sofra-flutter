import 'package:flutter/material.dart';

import '../ui/design.dart';
import 'common.dart';

/// "مجتمع سفرة": sharing tables and recipes with other households. Not built
/// yet; the page says so plainly instead of showing invented posts.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) => const ScreenBody(
    children: [
      SizedBox(height: 8),
      Surface(
        child: Column(
          children: [
            Icon(Icons.diversity_3_outlined, size: 44, color: Sofra.green),
            SizedBox(height: 12),
            Text(
              'مجتمع سفرة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'هنا هتشارك سفرتك ووصفاتك مع بيوت تانية، وتشوف هم بيطبخوا إيه. لسه بنبنيه.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Sofra.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
