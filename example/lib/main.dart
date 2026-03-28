import 'package:bezel/bezel.dart';
import 'package:flutter/material.dart';

const List<(IconData, String, String)> _discoveries = [
  (Icons.whatshot, 'Betelgeuse', 'Red supergiant · 700 solar radii'),
  (Icons.brightness_7, 'Sirius', 'Brightest star in the night sky'),
  (Icons.blur_on, 'Andromeda', 'Nearest major galaxy · 2.5 Mly'),
  (Icons.grain, 'Orion Nebula', 'Stellar nursery · 1,344 light-years'),
  (Icons.circle, 'Proxima Centauri', 'Closest star · 4.24 light-years'),
  (Icons.nights_stay, 'Pleiades', 'Open cluster · Seven Sisters'),
  (Icons.tornado, 'Pillars of Creation', 'Eagle Nebula · 6,500 light-years'),
  (Icons.air, 'Sagittarius A*', 'Milky Way central black hole'),
  (Icons.flare, 'Eta Carinae', 'Hypergiant · 5 million solar luminosities'),
];

void main() {
  Bezel.configure();

  runApp(const BezelExampleApp());
}

class BezelExampleApp extends StatefulWidget {
  const BezelExampleApp({super.key});

  @override
  State<BezelExampleApp> createState() => _BezelExampleAppState();
}

class _BezelExampleAppState extends State<BezelExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: _HomePage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.isDark, required this.onToggleTheme});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(icon: Icon(Icons.adaptive.more), onPressed: () {}),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      drawer: const _DeviceInfoDrawer(),
      body: const _DiscoverPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favourites'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DeviceInfoDrawer extends StatelessWidget {
  const _DeviceInfoDrawer();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final mq = MediaQuery.of(context);

    final size = mq.size;
    final dpr = mq.devicePixelRatio;
    final padding = mq.padding;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(
              'Device info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _InfoRow('Platform', platform.name),
                _InfoRow(
                  'Screen size',
                  '${size.width.toStringAsFixed(0)} x '
                      '${size.height.toStringAsFixed(0)} pt',
                ),
                _InfoRow('Device pixel ratio', dpr.toStringAsFixed(3)),
                _InfoRow(
                  'Safe area (LTRB)',
                  '${padding.left.toStringAsFixed(0)}, '
                      '${padding.top.toStringAsFixed(0)}, '
                      '${padding.right.toStringAsFixed(0)}, '
                      '${padding.bottom.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in _discoveries)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                size: 48,
                item.$1,
                color: theme.colorScheme.primary,
              ),
              title: Text(item.$2),
              subtitle: Text(item.$3),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _DetailPage(item: item),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.item});

  final (IconData, String, String) item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, name, description) = item;
    return Scaffold(
      appBar: AppBar(
        // Flutter's AppBar automatically inserts a BackButton here, which uses
        // Icons.adaptive.arrow_back — a left-chevron on iOS and a left-arrow on
        // Android — so the back affordance matches the emulated platform.
        title: Text(name),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Icon(icon, size: 96, color: theme.colorScheme.primary),
            Text(name, style: theme.textTheme.headlineSmall),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
