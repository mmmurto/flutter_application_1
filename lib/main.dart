import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  runApp(const DemoQrMenuApp());
}

class DemoQrMenuApp extends StatelessWidget {
  const DemoQrMenuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Demo QR Menu',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFF8EA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: _Palette.green,
            primary: _Palette.green,
            surface: const Color(0xFFFFF8EA),
          ),
        ),
        home: const DemoAppShell(),
      );
}

class DemoAppShell extends StatefulWidget {
  const DemoAppShell({super.key});

  @override
  State<DemoAppShell> createState() => _DemoAppShellState();
}

class _DemoAppShellState extends State<DemoAppShell> {
  int _index = 0;
  final _pages = const [QrMenuPage(), RestaurantDashboard(), KitchenScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCE8D5),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Customer Menu'),
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.soup_kitchen_outlined), selectedIcon: Icon(Icons.soup_kitchen), label: 'Kitchen'),
          ],
        ),
      );
}

class QrMenuPage extends StatefulWidget {
  const QrMenuPage({super.key});

  @override
  State<QrMenuPage> createState() => _QrMenuPageState();
}

class _QrMenuPageState extends State<QrMenuPage> {
  static const categories = ['Popular', 'Starters', 'Main Dishes', 'Drinks', 'Desserts'];
  static const dishes = [
    _Dish('Demo Herb Bowl', 'Fresh greens, grains and lemon dressing', 11.50, 'Veg', Icons.spa_outlined, Color(0xFF7D9C6E)),
    _Dish('Sample Flame Grill', 'Charred vegetables with house seasoning', 16.00, 'Spicy', Icons.local_fire_department_outlined, Color(0xFFD2704A)),
    _Dish('Demo Citrus Pasta', 'Creamy sauce, herbs and citrus zest', 14.50, 'Veg', Icons.restaurant_outlined, Color(0xFFE1AB54)),
    _Dish('Placeholder Cooler', 'Sparkling fruit drink with fresh mint', 6.00, 'Veg', Icons.local_drink_outlined, Color(0xFF68A8A0)),
    _Dish('Sample Berry Tart', 'Crisp pastry with a sweet berry filling', 8.50, 'Veg', Icons.cake_outlined, Color(0xFFA76A7B)),
  ];

  String _category = 'Popular';
  String _language = 'EN';
  int _count = 0;
  double _total = 0;

  void _add(_Dish dish) => setState(() {
        _count++;
        _total += dish.price;
      });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width >= 720 ? 32.0 : 20.0;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 112),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),
                        const SizedBox(height: 18),
                        _cover(),
                        const SizedBox(height: 24),
                        const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _Palette.green)),
                        const SizedBox(height: 12),
                        _categoryChips(),
                        const SizedBox(height: 24),
                        const Text('Demo picks', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _Palette.green)),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, box) {
                            final columns = box.maxWidth >= 650 ? 2 : 1;
                            final cardWidth = (box.maxWidth - (columns - 1) * 16) / columns;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: dishes.map((dish) => SizedBox(width: cardWidth, child: _MenuCard(dish: dish, onAdd: () => _add(dish)))).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _cartBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          const Expanded(child: Text('DEMO QR MENU', style: TextStyle(letterSpacing: 1.5, fontSize: 13, fontWeight: FontWeight.w900, color: _Palette.green))),
          _languageSelector(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFE7E6D5), borderRadius: BorderRadius.circular(16)),
            child: const Text('T5', style: TextStyle(color: _Palette.green, fontWeight: FontWeight.w900)),
          ),
        ],
      );

  Widget _languageSelector() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7DDCE))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['AZ', 'EN', 'RU'].map((language) {
            final selected = language == _language;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _language = language),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: selected ? _Palette.green : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                child: Text(language, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? Colors.white : _Palette.green)),
              ),
            );
          }).toList(),
        ),
      );

  Widget _cover() => Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFF1D5941), _Palette.green], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            Positioned(right: -18, top: -28, child: _coverDecor(112, const Color(0xFF4B7A5B))),
            Positioned(right: 64, bottom: -44, child: _coverDecor(125, const Color(0xFF315F49))),
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 66, height: 66, decoration: BoxDecoration(color: const Color(0xFFFFF8EA), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.restaurant_menu, color: _Palette.green, size: 31)),
              const SizedBox(height: 10),
              const Text('Demo Restaurant', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Table 5  \u00b7  QR Menu', style: TextStyle(color: Color(0xFFDCE8D5), fontWeight: FontWeight.w600)),
            ])),
          ],
        ),
      );

  Widget _coverDecor(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _categoryChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final selected = category == _category;
            return Padding(
              padding: const EdgeInsets.only(right: 9),
              child: ChoiceChip(
                label: Text(category), selected: selected, showCheckmark: false,
                onSelected: (_) => setState(() => _category = category),
                selectedColor: _Palette.green, backgroundColor: Colors.white,
                side: BorderSide(color: selected ? _Palette.green : const Color(0xFFE7DDCE)),
                labelStyle: TextStyle(color: selected ? Colors.white : _Palette.green, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            );
          }).toList(),
        ),
      );

  Widget _cartBar() => Container(
        color: _Palette.coral,
        padding: const EdgeInsets.fromLTRB(20, 13, 20, 18),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _Palette.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Row(children: [
                    Stack(clipBehavior: Clip.none, children: [
                      const Icon(Icons.shopping_bag_outlined),
                      if (_count > 0) Positioned(right: -10, top: -10, child: CircleAvatar(radius: 9, backgroundColor: _Palette.coral, child: Text('$_count', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)))),
                    ]),
                    const SizedBox(width: 12),
                    const Text('View order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${_total.toStringAsFixed(2)} \u20bc', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.dish, required this.onAdd});
  final _Dish dish;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x120E3929), blurRadius: 14, offset: Offset(0, 6))]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 78, height: 78, decoration: BoxDecoration(shape: BoxShape.circle, color: dish.color.withValues(alpha: .18)), child: Icon(dish.icon, size: 39, color: dish.color)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(dish.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Palette.green))), _Badge(label: dish.badge)]),
            const SizedBox(height: 5),
            Text(dish.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF66726A), height: 1.28, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [Text('${dish.price.toStringAsFixed(2)} \u20bc', style: const TextStyle(color: _Palette.green, fontSize: 16, fontWeight: FontWeight.w900)), const Spacer(), FilledButton(onPressed: onAdd, style: FilledButton.styleFrom(backgroundColor: _Palette.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: const Text('Add to order'))]),
          ])),
        ]),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final spicy = label == 'Spicy';
    final color = spicy ? _Palette.coral : const Color(0xFF4B805B);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(spicy ? Icons.local_fire_department : Icons.eco, color: color, size: 12), const SizedBox(width: 3), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10))]));
  }
}

class _Dish {
  const _Dish(this.name, this.description, this.price, this.badge, this.icon, this.color);
  final String name;
  final String description;
  final double price;
  final String badge;
  final IconData icon;
  final Color color;
}

class RestaurantDashboard extends StatelessWidget {
  const RestaurantDashboard({super.key});

  static const _popular = [
    ('Demo Herb Bowl', '18 orders', Icons.spa_outlined),
    ('Sample Flame Grill', '14 orders', Icons.local_fire_department_outlined),
    ('Demo Citrus Pasta', '11 orders', Icons.restaurant_outlined),
  ];

  static const _orders = [
    ('#D-1047', 'Table 3', 'New', '32.50'),
    ('#D-1046', 'Table 7', 'Preparing', '48.00'),
    ('#D-1045', 'Table 2', 'Ready', '21.50'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('DEMO ADMIN VIEW', style: TextStyle(letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w900, color: _Palette.coral)),
              const SizedBox(height: 7),
              const Text('Demo Restaurant Dashboard', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: _Palette.green)),
              const SizedBox(height: 5),
              const Text('Today at a glance \u00b7 placeholder data only', style: TextStyle(color: Color(0xFF68736A))),
              const SizedBox(height: 22),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _MetricCard(label: 'Today’s sales', value: '\u20bc1,240', icon: Icons.payments_outlined, wide: wide),
                _MetricCard(label: 'Today’s orders', value: '47', icon: Icons.receipt_long_outlined, wide: wide),
                _MetricCard(label: 'Average order', value: '\u20bc26.40', icon: Icons.bar_chart_outlined, wide: wide),
              ]),
              const SizedBox(height: 28),
              const Text('Quick actions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _Palette.green)),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, box) {
                final columns = box.maxWidth >= 600 ? 4 : 2;
                final actionWidth = (box.maxWidth - (columns - 1) * 10) / columns;
                const actions = [
                  ('Manage Menu', Icons.menu_book_outlined), ('Tables & QR Codes', Icons.qr_code_2_outlined),
                  ('Orders', Icons.receipt_long_outlined), ('Reports', Icons.insights_outlined),
                ];
                return Wrap(spacing: 10, runSpacing: 10, children: actions.map((action) => SizedBox(width: actionWidth, child: _ActionButton(label: action.$1, icon: action.$2))).toList());
              }),
              const SizedBox(height: 28),
              const Text('Popular items', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _Palette.green)),
              const SizedBox(height: 10),
              _panel(children: _popular.map((item) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: const Color(0xFFE8EFE1), child: Icon(item.$3, color: _Palette.green)), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800, color: _Palette.green)), trailing: Text(item.$2, style: const TextStyle(color: Color(0xFF68736A), fontWeight: FontWeight.w700)))).toList()),
              const SizedBox(height: 25),
              const Text('Recent demo orders', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _Palette.green)),
              const SizedBox(height: 10),
              _panel(children: _orders.map((order) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.$1, style: const TextStyle(fontWeight: FontWeight.w900, color: _Palette.green)), Text(order.$2, style: const TextStyle(color: Color(0xFF68736A), fontSize: 13))])), _OrderStatus(label: order.$3), const SizedBox(width: 10), Text('\u20bc${order.$4}', style: const TextStyle(fontWeight: FontWeight.w800, color: _Palette.green))]))).toList()),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) => Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x100E3929), blurRadius: 14, offset: Offset(0, 6))]), child: Column(children: children));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.wide});
  final String label;
  final String value;
  final IconData icon;
  final bool wide;
  @override
  Widget build(BuildContext context) => SizedBox(width: wide ? 296 : (MediaQuery.sizeOf(context).width - 52) / 2, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x100E3929), blurRadius: 12, offset: Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _Palette.coral), const SizedBox(height: 13), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _Palette.green)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Color(0xFF68736A), fontWeight: FontWeight.w600))])));
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: () {}, icon: Icon(icon, size: 19), label: Text(label, textAlign: TextAlign.center), style: OutlinedButton.styleFrom(foregroundColor: _Palette.green, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), side: const BorderSide(color: Color(0xFFD7E0D2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = switch (label) { 'New' => _Palette.coral, 'Preparing' => const Color(0xFFD19228), _ => const Color(0xFF4B805B) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)));
  }
}

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final List<_KitchenOrder> _orders = [
    _KitchenOrder('D-1051', 'T2', ['Demo herb bowl', 'Placeholder cooler'], '04 min', 17.50, _KitchenStatus.newOrder),
    _KitchenOrder('D-1052', 'T8', ['Sample flame grill', 'Demo flatbread'], '07 min', 23.00, _KitchenStatus.newOrder),
    _KitchenOrder('D-1049', 'T5', ['Demo citrus pasta', 'Sparkling water'], '12 min', 20.50, _KitchenStatus.preparing),
    _KitchenOrder('D-1050', 'T1', ['Sample berry tart', 'Demo tea'], '09 min', 14.00, _KitchenStatus.preparing),
    _KitchenOrder('D-1048', 'T6', ['Demo veggie platter', 'Placeholder cooler'], '16 min', 25.50, _KitchenStatus.ready),
  ];

  void _advance(_KitchenOrder order) => setState(() {
        if (order.status == _KitchenStatus.newOrder) {
          order.status = _KitchenStatus.preparing;
        } else if (order.status == _KitchenStatus.preparing) {
          order.status = _KitchenStatus.ready;
        }
      });

  @override
  Widget build(BuildContext context) => SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final compact = box.maxWidth < 720;
          return Column(children: [
            _kitchenHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: compact ? Axis.vertical : Axis.horizontal,
                child: compact
                    ? Column(children: _KitchenStatus.values.map((status) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _statusColumn(status, box.maxWidth - 32, false))).toList())
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: _KitchenStatus.values.map((status) => Padding(padding: const EdgeInsets.only(right: 16), child: _statusColumn(status, 330, true))).toList()),
              ),
            ),
          ]);
        }),
      );

  Widget _kitchenHeader() => Container(
        color: _Palette.green,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          const Icon(Icons.soup_kitchen, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(child: Text('Kitchen Display', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _Palette.coral, borderRadius: BorderRadius.circular(14)), child: const Text('Demo data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
        ]),
      );

  Widget _statusColumn(_KitchenStatus status, double width, bool fixedHeight) {
    final orders = _orders.where((order) => order.status == status).toList();
    final color = _statusColor(status);
    return SizedBox(
      width: width,
      height: fixedHeight ? 600 : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .32))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(_statusName(status), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 7), Text('${orders.length}', style: TextStyle(color: color, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 12),
          if (orders.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No demo orders', style: TextStyle(color: Color(0xFF66726A))))),
          ...orders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _KitchenOrderCard(order: order, color: color, onAdvance: () => _advance(order)))),
        ]),
      ),
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  const _KitchenOrderCard({required this.order, required this.color, required this.onAdvance});
  final _KitchenOrder order;
  final Color color;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x180A251B), blurRadius: 9, offset: Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('#${order.number}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _Palette.green)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF0F0E5), borderRadius: BorderRadius.circular(9)), child: Text(order.table, style: const TextStyle(fontWeight: FontWeight.w900, color: _Palette.green)))]),
          const SizedBox(height: 10),
          ...order.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF405047))))),
          const Divider(height: 22),
          Row(children: [Icon(Icons.timer_outlined, size: 17, color: color), const SizedBox(width: 5), Text(order.elapsed, style: TextStyle(color: color, fontWeight: FontWeight.w900)), const Spacer(), Text('${order.total.toStringAsFixed(2)} \u20bc', style: const TextStyle(color: _Palette.green, fontWeight: FontWeight.w900))]),
          if (order.status != _KitchenStatus.ready) ...[
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: onAdvance, style: FilledButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: Text(order.status == _KitchenStatus.newOrder ? 'Start preparing' : 'Mark ready'))),
          ],
        ]),
      );
}

enum _KitchenStatus { newOrder, preparing, ready }

class _KitchenOrder {
  _KitchenOrder(this.number, this.table, this.items, this.elapsed, this.total, this.status);
  final String number;
  final String table;
  final List<String> items;
  final String elapsed;
  final double total;
  _KitchenStatus status;
}

String _statusName(_KitchenStatus status) => switch (status) { _KitchenStatus.newOrder => 'New', _KitchenStatus.preparing => 'Preparing', _KitchenStatus.ready => 'Ready' };

Color _statusColor(_KitchenStatus status) => switch (status) { _KitchenStatus.newOrder => const Color(0xFFE88727), _KitchenStatus.preparing => const Color(0xFF2876C8), _KitchenStatus.ready => const Color(0xFF39834C) };

abstract final class _Palette {
  static const green = Color(0xFF173F30);
  static const coral = Color(0xFFE4744F);
}
