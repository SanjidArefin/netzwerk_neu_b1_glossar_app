import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_title.dart';

class GlossaryLoading extends StatelessWidget {
  const GlossaryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingBrand(),
            SizedBox(height: 22),
            CircularProgressIndicator(color: AppColors.green),
          ],
        ),
      ),
    );
  }
}

class GlossaryLoadError extends StatelessWidget {
  const GlossaryLoadError({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final muted = themeMuted(Theme.of(context));
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Glossardaten konnten nicht geladen werden.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyResults extends StatelessWidget {
  const EmptyResults({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = themeMuted(Theme.of(context));
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 36, color: muted),
          const SizedBox(height: 12),
          Text(
            'Keine passenden Woerter gefunden.',
            style: TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
