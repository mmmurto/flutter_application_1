import 'package:flutter/material.dart';

import '../../../core/widgets/content_shell.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../app/routes.dart';
import '../data/staff_restaurant_repository.dart';
import '../domain/staff_restaurant.dart';

enum StaffArea { owner, kitchen }

/// Entry point for restaurant staff.
///
/// When Supabase is not configured the page fails closed. When it is
/// configured, staff see a password sign-in form; the app never offers
/// self-registration, because staff accounts are created by the platform or the
/// restaurant owner.
class StaffAccessPage extends StatelessWidget {
  const StaffAccessPage({
    required this.area,
    required this.authController,
    this.restaurantRepository,
    super.key,
  });

  final StaffArea area;
  final AuthController? authController;
  final StaffRestaurantRepository? restaurantRepository;

  @override
  Widget build(BuildContext context) {
    final controller = authController;
    if (controller == null) {
      return _UnconfiguredView(area: area);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.isSignedIn
          ? _StaffHome(
              area: area,
              controller: controller,
              restaurantRepository: restaurantRepository,
            )
          : _SignInForm(area: area, controller: controller),
    );
  }
}

class _UnconfiguredView extends StatelessWidget {
  const _UnconfiguredView({required this.area});

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

class _SignInForm extends StatefulWidget {
  const _SignInForm({required this.area, required this.controller});

  final StaffArea area;
  final AuthController controller;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKitchen = widget.area == StaffArea.kitchen;
    final error = widget.controller.errorMessage;

    return ContentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isKitchen ? Icons.soup_kitchen_outlined : Icons.store_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isKitchen ? 'Kitchen sign in' : 'Restaurant sign in',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Use the staff account provided by your restaurant owner.',
            style: TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Enter your email.';
                      final at = email.indexOf('@');
                      if (at <= 0 || at == email.length - 1) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter your password.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.controller.isBusy ? null : _submit,
            child: widget.controller.isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
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
                      'Accounts are created by the restaurant owner. There is no public sign-up.',
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

class _StaffHome extends StatefulWidget {
  const _StaffHome({
    required this.area,
    required this.controller,
    required this.restaurantRepository,
  });

  final StaffArea area;
  final AuthController controller;
  final StaffRestaurantRepository? restaurantRepository;

  @override
  State<_StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<_StaffHome> {
  late Future<List<StaffRestaurant>> _restaurants;

  @override
  void initState() {
    super.initState();
    _restaurants = _load();
  }

  Future<List<StaffRestaurant>> _load() async {
    final repository = widget.restaurantRepository;
    if (repository == null) return const [];
    return repository.fetchMyRestaurants();
  }

  void _retry() {
    setState(() {
      _restaurants = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKitchen = widget.area == StaffArea.kitchen;
    final email = widget.controller.user?.email ?? 'signed-in account';
    final repository = widget.restaurantRepository;

    return ContentShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isKitchen ? Icons.soup_kitchen_outlined : Icons.store_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isKitchen ? 'Kitchen' : 'Restaurant management',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Signed in as $email.',
            style: const TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 24),
          Text(
            'Your restaurants',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (repository == null)
            const _StaffNotice(
              icon: Icons.construction_outlined,
              message:
                  'Restaurant tools are being built. Access is enforced by the '
                  'database on every request.',
            )
          else
            FutureBuilder<List<StaffRestaurant>>(
              future: _restaurants,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _StaffNotice(
                    icon: Icons.error_outline,
                    message:
                        'Your restaurant access could not be loaded. Check '
                        'your connection and try again.',
                    action: FilledButton.tonal(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                  );
                }

                final restaurants = snapshot.data ?? const <StaffRestaurant>[];
                if (restaurants.isEmpty) {
                  return const _StaffNotice(
                    icon: Icons.storefront_outlined,
                    message:
                        'This account has no active restaurant access yet. Ask '
                        'the platform owner to add you to a restaurant.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final restaurant in restaurants) ...[
                      _StaffRestaurantCard(restaurant: restaurant),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _StaffRestaurantCard extends StatelessWidget {
  const _StaffRestaurantCard({required this.restaurant});

  final StaffRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: () =>
            Navigator.of(context)
                .pushNamed(AppRoutes.ownerMenu(restaurant.slug)),
        trailing: const Icon(Icons.chevron_right),
        leading: Icon(Icons.storefront, color: theme.colorScheme.primary),
        title: Text(
          restaurant.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${restaurant.roleLabel} · ${restaurant.publicationLabel}',
        ),
      ),
    );
  }
}

class _StaffNotice extends StatelessWidget {
  const _StaffNotice({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
