import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class HealthHistoryScreen extends StatelessWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = LocalStorage.instance.readKyc();
    return Scaffold(
      appBar: AppBar(title: const Text('Health History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: history == null
            ? const Center(child: Text('No history available'))
            : ListView(
                children: history.entries
                    .map<Widget>((e) => ListTile(
                          title: Text(e.key.toString()),
                          subtitle: Text(e.value.toString()),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}


