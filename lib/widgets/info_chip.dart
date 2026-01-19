import 'package:flutter/material.dart';

import 'package:ubsohbet/app_data.dart';

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: withOpacity(kCoral, 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: withOpacity(kMidnight, 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: withOpacity(kMidnight, 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
