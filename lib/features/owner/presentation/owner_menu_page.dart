import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../staff/presentation/staff_access_page.dart';
import '../data/owner_menu_repository.dart';
import '../domain/managed_menu.dart';

/// Authenticated restaurant workspace for one restaurant.
///
/// Shows the restaurant's own menu exactly as stored, including categories and
/// items that are hidden from the public. Editing is not implemented yet; the
/// database still refuses client writes to these tables.
class OwnerMenuPage extends StatefulWidget {
  const OwnerMenuPage({
    required this.restaurantSlug,
    required this.authController,
    required this.ownerMenuRepository,
    super.key,
  });

  final String restaurantSlug;
  final AuthController? authController;
  final OwnerMenuRepository? ownerMenuRepository;

  @override
  State<OwnerMenuPage> createState() => _OwnerMenuPageState();
}

class _OwnerMenuPageState extends State<OwnerMenuPage> {
  Future<ManagedMenu?>? _menu;

  @override
  void initState() {
    super.initState();
    widget.authController?.addListener(_handleSessionChange);
    if (widget.authController?.isSignedIn ?? false) {
      _menu = _load();
    }
  }

  @override
  void dispose() {
    widget.authController?.removeListener(_handleSessionChange);
    super.dispose();
  }

  void _handleSessionChange() {
    final signedIn = widget.authController?.isSignedIn ?? false;
    if (signedIn && _menu == null) {
      setState(() {
        _menu = _load();
      });
    } else if (!signedIn && _menu != null) {
      setState(() {
        _menu = null;
      });
    }
  }

  Future<ManagedMenu?> _load() async {
    final repository = widget.ownerMenuRepository;
    if (repository == null) return null;
    return repository.fetchManagedMenu(widget.restaurantSlug);
  }

  void _retry() {
    setState(() {
      _menu = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.authController;
    if (controller == null) {
      // No backend configured: keep the same fail-closed boundary as /owner.
      return const StaffAccessPage(area: StaffArea.owner, authController: null);
    }
    if (!controller.isSignedIn) {
      return StaffAccessPage(area: StaffArea.owner, authController: controller);
    }

    final menuFuture = _menu;
    if (menuFuture == null) {
      return const _OwnerShell(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return FutureBuilder<ManagedMenu?>(
      future: menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _OwnerShell(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return _OwnerShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Menu could not be loaded',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _retry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final menu = snapshot.data;
        if (menu == null) {
          return _OwnerShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  'No access to this restaurant',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account is not a member of this restaurant, so its '
                  'menu is not visible.',
                  style: TextStyle(fontSize: 17, height: 1.45),
                ),
              ],
            ),
          );
        }

        return _OwnerShell(child: _ManagedMenuView(menu: menu));
      },
    );
  }
}

class _OwnerShell extends StatelessWidget {
  const _OwnerShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ContentShell(child: child);
}

class _ManagedMenuView extends StatelessWidget {
  const _ManagedMenuView({required this.menu});

  final ManagedMenu menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = menu.categories.fold(
      0,
      (total, category) => total + category.items.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(menu.name, style: theme.textTheme.headlineMedium),
            ),
            Chip(label: Text(menu.publicationLabel)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$itemCount items in ${menu.categories.length} categories'
          '${menu.hiddenItemCount > 0 ? ' · ${menu.hiddenItemCount} hidden from guests' : ''}',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Editing is not available yet. This view shows exactly what '
                    'guests would see after the restaurant is published.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (menu.categories.isEmpty)
          const Text('No menu categories yet.', style: TextStyle(fontSize: 17)),
        for (final category in menu.categories) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (!category.isActive) const Chip(label: Text('Hidden')),
            ],
          ),
          const SizedBox(height: 4),
          if (category.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No dishes in this category.'),
            ),
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!item.isAvailable) ...[
                              const SizedBox(width: 8),
                              const Chip(label: Text('Hidden from guests')),
                            ],
                          ],
                        ),
                        if (item.description case final description?) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 15, height: 1.4),
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
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
