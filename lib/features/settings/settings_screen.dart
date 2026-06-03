import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _geminiKeyController;
  late TextEditingController _openaiKeyController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<SettingsController>();
    _geminiKeyController = TextEditingController(text: controller.geminiApiKey);
    _openaiKeyController = TextEditingController(text: controller.openaiApiKey);
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _openaiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Mode', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_6)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {controller.themeMode},
                      onSelectionChanged: (s) => controller.setThemeMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AI Config Section
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Engine Config', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: controller.aiProvider,
                    decoration: const InputDecoration(
                      labelText: 'Active AI Provider',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (Recommended)')),
                      DropdownMenuItem(value: 'openai', child: Text('OpenAI GPT-4o')),
                      DropdownMenuItem(value: 'echo', child: Text('Local Echo (Mock)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        controller.setAiProvider(val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Gemini Key Input
                  if (controller.aiProvider == 'gemini') ...[
                    TextField(
                      controller: _geminiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'Enter AIzaSy...',
                        helperText: 'Saved securely on your device. Leave empty to use server default.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      onChanged: (val) => controller.setGeminiApiKey(val.trim()),
                    ),
                  ],

                  // OpenAI Key Input
                  if (controller.aiProvider == 'openai') ...[
                    TextField(
                      controller: _openaiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'OpenAI API Key',
                        hintText: 'Enter sk-...',
                        helperText: 'Saved securely on your device. Leave empty to use server default.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      onChanged: (val) => controller.setOpenaiApiKey(val.trim()),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Cloud Sync Section
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: SwitchListTile(
                title: Text('Cloud Database Sync', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: const Text('Back up and sync analysis history with MongoDB Server'),
                secondary: const Icon(Icons.cloud_sync_outlined),
                value: controller.syncToCloud,
                onChanged: (val) {
                  controller.setSyncToCloud(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
