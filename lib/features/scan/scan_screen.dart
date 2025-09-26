import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String? _code;
  bool _paused = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final value = barcodes.first.rawValue;
              if (value == null) return;
              setState(() => _code = value);
              context.read<HistoryService>().add(HistoryItem(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    type: HistoryType.scan,
                    title: 'Scan result',
                    detail: value,
                    timestampMs: DateTime.now().millisecondsSinceEpoch,
                  ));
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _code == null ? 'No code detected' : 'Detected: $_code',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    if (_paused) {
                      await _controller.start();
                    } else {
                      await _controller.stop();
                    }
                    setState(() => _paused = !_paused);
                  },
                  child: Text(_paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await _controller.toggleTorch();
                  },
                  child: const Text('Torch'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


