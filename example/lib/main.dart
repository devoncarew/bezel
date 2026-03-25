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
      title: 'Bezel Example',
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bezel Example')),
      body: const Center(
        child: Text('Device preview active in debug mode.'),
      ),
    );
  }
}
