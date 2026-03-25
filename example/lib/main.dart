import 'package:bezel/bezel.dart';
// ignore: implementation_imports
import 'package:bezel/src/devices/device_database.dart';
import 'package:flutter/material.dart';

void main() {
  Bezel.ensureInitialized();

  Bezel.controller?.setProfile(DeviceDatabase.findById('pixel_7a')!);

  runApp(const BezelExampleApp());
}

class BezelExampleApp extends StatelessWidget {
  const BezelExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const _HomePage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar'),
        centerTitle: true,
        actions: [
          const IconButton(icon: Icon(Icons.search), onPressed: null),
          PopupMenuButton(
            itemBuilder: (_) => const [
              PopupMenuItem(child: Text('Sort by name')),
              PopupMenuItem(child: Text('Sort by distance')),
              PopupMenuItem(child: Text('Settings')),
            ],
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
