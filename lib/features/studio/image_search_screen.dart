import 'package:flutter/material.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  String? _imagePath;
  final List<String> _results = <String>[];
  bool _loading = false;

  Future<void> _pickAndSearch() async {
    setState(() {
      _loading = true;
      _results.clear();
      _imagePath = 'local://picked-image.jpg';
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    setState(() {
      _results.addAll(List<String>.generate(
        12,
        (i) => 'https://picsum.photos/seed/mock_$i/200/200',
      ));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _pickAndSearch,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Image & Search'),
              ),
              const SizedBox(width: 12),
              if (_imagePath != null) Text('Selected: $_imagePath'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('No results yet'))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_results[index], fit: BoxFit.cover),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


