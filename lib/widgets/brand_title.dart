import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green,
            border: Border.all(color: const Color(0xFF89E219), width: 3),
          ),
          child: const Text(
            'B1',
            style: TextStyle(
              color: AppColors.canvas,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NETZWERK NEU',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
            Text(
              'Glossar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

class LoadingBrand extends StatelessWidget {
  const LoadingBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.green,
        border: Border.all(color: const Color(0xFF89E219), width: 4),
      ),
      child: const Text(
        'B1',
        style: TextStyle(
          color: AppColors.canvas,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
