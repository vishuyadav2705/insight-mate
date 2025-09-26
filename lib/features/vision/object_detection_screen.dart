import 'package:flutter/material.dart';

class ObjectDetectionScreen extends StatelessWidget {
  const ObjectDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.visibility, size: 80),
          SizedBox(height: 12),
          Text('Object Detection placeholder'),
        ],
      ),
    );
  }
}


