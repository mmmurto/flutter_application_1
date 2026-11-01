import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';

class RestaurantMenuPage extends StatelessWidget {
  const RestaurantMenuPage({
    required this.restaurantSlug,
    required this.tableToken,
    required this.backendConfigured,
    super.key,
  });
  final String restaurantSlug;
  final String tableToken;
  final bool backendConfigured;

  @override
  Widget build(BuildContext context) => ContentShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          backendConfigured ? Icons.restaurant_menu : Icons.cloud_off,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          backendConfigured ? 'Menu unavailable' : 'Service is not configured',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          backendConfigured
              ? 'No verified, published menu was found for this QR code.'
              : 'The application cannot securely validate this QR code yet.',
          style: const TextStyle(fontSize: 17, height: 1.45),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please ask restaurant staff for assistance.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
