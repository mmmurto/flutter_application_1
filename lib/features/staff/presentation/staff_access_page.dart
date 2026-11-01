import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';

enum StaffArea { owner, kitchen }

class StaffAccessPage extends StatelessWidget {
  const StaffAccessPage({required this.area, super.key});
  final StaffArea area;

  @override
  Widget build(BuildContext context) {
    final isKitchen = area == StaffArea.kitchen;
    return ContentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isKitchen ? Icons.soup_kitchen_outlined : Icons.store_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isKitchen ? 'Kitchen access' : 'Restaurant management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'A verified staff account and restaurant permission are required.',
            style: TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Authentication and role-based access are being prepared.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
