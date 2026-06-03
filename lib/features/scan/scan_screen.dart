import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';
import '../../shared/services/api_client.dart';
import '../settings/settings_controller.dart';

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

  void _showProductDetails(String code) {
    _controller.stop();
    setState(() {
      _paused = true;
      _code = code;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final settings = context.read<SettingsController>();
        final key = settings.aiProvider == 'gemini' ? settings.geminiApiKey : settings.openaiApiKey;
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiClient().barcodeLookup(code, apiKey: key),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Running product lookup & AI analysis...'),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 12),
                    Text('Lookup Failed', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  ],
                );
              }
              
              final data = snapshot.data!;
              final name = data['name'] ?? 'Unknown Product';
              final brand = data['brand'] ?? 'Unknown Brand';
              final imageUrl = data['imageUrl'] ?? '';
              final ingredients = data['ingredients'] ?? 'N/A';
              final analysis = data['analysis'] ?? {};
              final summary = analysis['summary'] ?? 'No analysis available';
              final rating = (analysis['rating'] as num?)?.toDouble() ?? 0.0;
              final suitability = List<String>.from(analysis['suitability'] ?? []);
              final alternatives = List<String>.from(analysis['alternatives'] ?? []);
              final nutrition = data['nutrition'] as Map<String, dynamic>? ?? {};

              // Save to history
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<HistoryService>().add(HistoryItem(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  type: HistoryType.scan,
                  title: name,
                  detail: '$brand - Health rating $rating/10',
                  timestampMs: DateTime.now().millisecondsSinceEpoch,
                  extra: {
                    'code': code,
                    'productName': name,
                    'brand': brand,
                    'rating': rating,
                    'summary': summary,
                  },
                ));
              });

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.qr_code_2, size: 40),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text(brand, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Barcode: $code', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Insight Health Score', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: rating >= 7 ? Colors.green[100] : (rating >= 4 ? Colors.orange[100] : Colors.red[100]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$rating / 10.0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rating >= 7 ? Colors.green[800] : (rating >= 4 ? Colors.orange[800] : Colors.red[800]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('AI Nutritionist Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(summary, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (suitability.isNotEmpty) ...[
                    Text('Dietary Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suitability.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (nutrition.isNotEmpty && nutrition['energy'] != null && nutrition['energy'] != 0) ...[
                    Text('Nutrition Table (per 100g)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                          },
                          border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey[100]!)),
                          children: [
                            TableRow(children: [
                              const Padding(padding: EdgeInsets.all(8), child: Text('Energy (Calories)')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${nutrition['energy']} kcal', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),
                            TableRow(children: [
                              const Padding(padding: EdgeInsets.all(8), child: Text('Proteins')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${nutrition['proteins']}g', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),
                            TableRow(children: [
                              const Padding(padding: EdgeInsets.all(8), child: Text('Carbohydrates')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${nutrition['carbs']}g', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),
                            TableRow(children: [
                              const Padding(padding: EdgeInsets.all(8), child: Text('Sugars')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${nutrition['sugar']}g', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),
                            TableRow(children: [
                              const Padding(padding: EdgeInsets.all(8), child: Text('Fats')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('${nutrition['fat']}g', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (alternatives.isNotEmpty) ...[
                    Text('AI Suggested Alternatives', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...alternatives.map((alt) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0.5,
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(alt),
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],

                  ExpansionTile(
                    title: const Text('Ingredients Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(ingredients, style: const TextStyle(color: Colors.grey, height: 1.4)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) async {
      await _controller.start();
      setState(() => _paused = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final value = barcodes.first.rawValue;
                  if (value == null) return;
                  if (!_paused) {
                    _showProductDetails(value);
                  }
                },
              ),
              // Camera Overlay Guideline
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
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
                    _code == null ? 'Position barcode inside framing' : 'Last Scanned: $_code',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
