import 'package:bezel/bezel.dart';
// ignore: implementation_imports
import 'package:bezel/src/devices/device_database.dart';
import 'package:flutter/material.dart';

// TODO: Have the currently selected device persist.

// TODO: Use neomorphism?

// TODO: Tell the app that we're on android or iOS (mock the platform)

void main() {
  Bezel.ensureInitialized();

  // TODO: Make this easier to configure.
  Bezel.controller?.setProfile(DeviceDatabase.findById('pixel_7a')!);

  runApp(const BezelExampleApp());
}

class BezelExampleApp extends StatelessWidget {
  const BezelExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Stellar',
      // theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _selectedIndex = 0;

  void _showDeviceInfo(BuildContext context) {
    final mq = MediaQuery.of(context);
    final platform = Theme.of(context).platform;
    final size = mq.size;
    final dpr = mq.devicePixelRatio;
    final padding = mq.padding;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow('Platform', platform.name),
            _InfoRow(
              'Screen size',
              '${size.width.toStringAsFixed(0)} × '
                  '${size.height.toStringAsFixed(0)} pt',
            ),
            _InfoRow('Device pixel ratio', dpr.toStringAsFixed(3)),
            _InfoRow(
              'Safe area',
              'top ${padding.top.toStringAsFixed(0)}, '
                  'bottom ${padding.bottom.toStringAsFixed(0)}, '
                  'left ${padding.left.toStringAsFixed(0)}, '
                  'right ${padding.right.toStringAsFixed(0)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDeviceInfo(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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

const _pages = [_DiscoverPage(), _FavouritesPage(), _ProfilePage()];

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
              leading: Icon(item.$1, color: theme.colorScheme.primary),
              title: Text(item.$2),
              subtitle: Text(item.$3),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}

const _discoveries = [
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

class _FavouritesPage extends StatelessWidget {
  const _FavouritesPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 64),
          SizedBox(height: 16),
          Text('No favourites yet'),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Cosmonaut', style: TextStyle(fontSize: 20))),
        const SizedBox(height: 32),
        for (final item in _profileItems)
          ListTile(leading: Icon(item.$1), title: Text(item.$2)),
      ],
    );
  }
}

const _profileItems = [
  (Icons.notifications_outlined, 'Notifications'),
  (Icons.dark_mode_outlined, 'Appearance'),
  (Icons.language, 'Language'),
  (Icons.help_outline, 'Help & feedback'),
];

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
