import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';
import '../data/menu_repository.dart';
import '../domain/restaurant_menu.dart';

/// Public table menu reached from a printed QR code.
///
/// Only restaurant-approved, published data is rendered. The table token is
/// kept for the future table-session exchange; it is not resolved here because
/// table QR credentials are deliberately not publicly readable.
class RestaurantMenuPage extends StatefulWidget {
  const RestaurantMenuPage({
    required this.restaurantSlug,
    required this.tableToken,
    required this.menuRepository,
    super.key,
  });

  final String restaurantSlug;
  final String tableToken;
  final MenuRepository? menuRepository;

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  late Future<RestaurantMenu?> _menu;

  @override
  void initState() {
    super.initState();
    _menu = _load();
  }

  Future<RestaurantMenu?> _load() async {
    final repository = widget.menuRepository;
    if (repository == null) return null;
    return repository.fetchPublishedMenu(widget.restaurantSlug);
  }

  void _retry() {
    setState(() {
      _menu = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.menuRepository == null) {
      return const _MessageView(
        icon: Icons.cloud_off,
        title: 'Service is not configured',
        body: 'The application cannot securely validate this QR code yet.',
        footer: 'Please ask restaurant staff for assistance.',
      );
    }

    return FutureBuilder<RestaurantMenu?>(
      future: _menu,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingView();
        }
        if (snapshot.hasError) {
          return _MessageView(
            icon: Icons.error_outline,
            title: 'Menu could not be loaded',
            body: 'Check your connection and try again.',
            footer: 'If this keeps happening, ask restaurant staff for help.',
            action: FilledButton.tonal(
              onPressed: _retry,
              child: const Text('Try again'),
            ),
          );
        }

        final menu = snapshot.data;
        if (menu == null || !menu.hasItems) {
          return const _MessageView(
            icon: Icons.restaurant_menu,
            title: 'Menu unavailable',
            body: 'No verified, published menu was found for this QR code.',
            footer: 'Please ask restaurant staff for assistance.',
          );
        }
        return _MenuView(menu: menu, onRefresh: _retry);
      },
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView({required this.menu, required this.onRefresh});

  final RestaurantMenu menu;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(menu.name, style: theme.textTheme.headlineMedium),
          if (menu.description case final description?) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 17, height: 1.45),
            ),
          ],
          if (menu.address case final address?) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          for (final category in menu.categories)
            if (category.items.isNotEmpty) ...[
              _CategorySection(category: category),
              const SizedBox(height: 24),
            ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ordering and payment at the table are not available yet. Please order with restaurant staff.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh menu',
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

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final MenuCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in category.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.description case final description?) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ],
                      if (item.isVegetarian || item.isSpicy) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (item.isVegetarian) 'Vegetarian',
                            if (item.isSpicy) 'Spicy',
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const ContentShell(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading menu…', style: TextStyle(fontSize: 17)),
        ],
      ),
    ),
  );
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.body,
    required this.footer,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final String footer;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ContentShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(fontSize: 17, height: 1.45)),
        const SizedBox(height: 16),
        Text(footer, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (action case final action?) ...[const SizedBox(height: 24), action],
      ],
    ),
  );
}
