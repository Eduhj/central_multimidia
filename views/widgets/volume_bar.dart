import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'big_button.dart';

class VolumeBar extends StatelessWidget {
  const VolumeBar(
      {super.key,
      required this.value,
      required this.onDown,
      required this.onUp});

  final int value;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BigButton(
            width: 72,
            height: 60,
            onPressed: onDown,
            child: const Icon(Icons.volume_down, size: 34)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value%',
                  style:
                      const TextStyle(fontSize: 18, color: AppColors.textDim)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 12,
                  backgroundColor: AppColors.surfaceHigh,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        BigButton(
            width: 72,
            height: 60,
            onPressed: onUp,
            child: const Icon(Icons.volume_up, size: 34)),
      ],
    );
  }
}
