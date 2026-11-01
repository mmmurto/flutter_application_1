import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';

class CustomerEntryPage extends StatelessWidget {
  const CustomerEntryPage({super.key});

  @override
  Widget build(BuildContext context) => ContentShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.qr_code_scanner,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Open a restaurant menu',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Scan the QR code supplied by a verified restaurant. The code identifies the restaurant location and table securely.',
          style: TextStyle(fontSize: 17, height: 1.45),
        ),
        const SizedBox(height: 24),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only restaurant-approved information will be published.',
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
