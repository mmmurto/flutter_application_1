import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';
import '../../discovery/data/restaurant_directory_repository.dart';
import '../../discovery/domain/restaurant_summary.dart';

/// Customer entry: browse approved restaurants, search, and filter by budget.
class CustomerEntryPage extends StatefulWidget {
  const CustomerEntryPage({required this.directoryRepository, super.key});

  final RestaurantDirectoryRepository? directoryRepository;

  @override
  State<CustomerEntryPage> createState() => _CustomerEntryPageState();
}

class _CustomerEntryPageState extends State<CustomerEntryPage> {
  static const _budgetOptions = <double?>[null, 5, 10, 15, 25];

  final _searchController = TextEditingController();
  late Future<List<RestaurantSummary>> _restaurants;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _restaurants = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<RestaurantSummary>> _load() async {
    final repository = widget.directoryRepository;
    if (repository == null) return const [];
    return repository.fetchPublishedRestaurants();
  }

  void _retry() {
    setState(() {
      _restaurants = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text('Find a restaurant', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            'Browse approved restaurants and their published menus. Scan the '
            'QR code on your table to open that restaurant’s menu directly.',
            style: TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search restaurants',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Budget per person',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _budgetOptions)
                ChoiceChip(
                  label: Text(
                    option == null
                        ? 'Any budget'
                        : 'Up to ${option.toInt()} \u20BC',
                  ),
                  selected: _maxPrice == option,
                  onSelected: (_) => setState(() => _maxPrice = option),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Shows restaurants with at least one published dish within your '
            'budget.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (widget.directoryRepository == null)
            const _Notice(
              icon: Icons.cloud_off,
              title: 'Service is not configured',
              body:
                  'Restaurant listings are unavailable until the app is started '
                  'with Supabase configuration.',
            )
          else
            FutureBuilder<List<RestaurantSummary>>(
              future: _restaurants,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _Notice(
                    icon: Icons.error_outline,
                    title: 'Restaurants could not be loaded',
                    body: 'Check your connection and try again.',
                    action: FilledButton.tonal(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  );
                }

                final all = snapshot.data ?? const <RestaurantSummary>[];
                if (all.isEmpty) {
                  return const _Notice(
                    icon: Icons.storefront_outlined,
                    title: 'No approved restaurants yet',
                    body:
                        'Restaurants appear here only after the owner approves '
                        'their published menu.',
                  );
                }

                final visible = filterRestaurants(
                  all,
                  query: _searchController.text,
                  maxPrice: _maxPrice,
                );
                if (visible.isEmpty) {
                  return const _Notice(
                    icon: Icons.search_off,
                    title: 'No restaurants match',
                    body: 'Try a different search or a higher budget.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final restaurant in visible) ...[
                      _RestaurantCard(restaurant: restaurant),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/r/${restaurant.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.storefront, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (restaurant.description case final description?) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ],
                    if (restaurant.address case final address?) ...[
                      const SizedBox(height: 8),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      restaurant.formattedFromPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.4)),
            if (action case final action?) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
