import 'package:bezel/bezel.dart';
import 'package:flutter/material.dart';

void main() {
  Bezel.ensureInitialized();

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
              'Safe area (LTRB)',
              '${padding.left.toStringAsFixed(0)}, '
                  '${padding.top.toStringAsFixed(0)}, '
                  '${padding.right.toStringAsFixed(0)}, '
                  '${padding.bottom.toStringAsFixed(0)}',
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
      body: _pages[0],
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

const _pages = [_DiscoverPage()];

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
              // isThreeLine: true,
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
