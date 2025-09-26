import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            onPressed: history.items.isEmpty
                ? null
                : () => context.read<HistoryService>().clear(),
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: history.items.isEmpty
          ? const Center(child: Text('No history yet'))
          : ListView.separated(
              itemCount: history.items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final item = history.items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  background: Container(color: Colors.redAccent),
                  onDismissed: (_) => context.read<HistoryService>().remove(item.id),
                  child: ListTile(
                    leading: Icon(_iconFor(item.type)),
                    title: Text(item.title),
                    subtitle: Text(item.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      DateTime.fromMillisecondsSinceEpoch(item.timestampMs).toLocal().toIso8601String().split('T').first,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

IconData _iconFor(HistoryType type) {
  switch (type) {
    case HistoryType.chat:
      return Icons.chat;
    case HistoryType.scan:
      return Icons.qr_code;
    case HistoryType.generation:
      return Icons.image;
    case HistoryType.imageSearch:
      return Icons.search;
  }
}


