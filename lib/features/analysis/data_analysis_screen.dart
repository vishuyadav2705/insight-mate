import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../shared/services/api_client.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';
import '../settings/settings_controller.dart';

class DataAnalysisScreen extends StatefulWidget {
  const DataAnalysisScreen({super.key});

  @override
  State<DataAnalysisScreen> createState() => _DataAnalysisScreenState();
}

class _DataAnalysisScreenState extends State<DataAnalysisScreen> {
  final TextEditingController _queryController = TextEditingController(
    text: "Analyze this data and display it as a line chart",
  );
  final TextEditingController _csvController = TextEditingController();
  
  String _selectedPreset = 'sales';
  bool _analyzing = false;

  // Preset Datasets
  static const Map<String, String> _presets = {
    'sales': "Month,Sales,Profit\nJan,12000,3000\nFeb,15000,4500\nMar,18000,5000\nApr,16000,4000\nMay,22000,7000\nJun,25000,8500",
    'expense': "Category,Expense\nFood,600\nRent,1200\nTransport,250\nUtilities,350\nEntertainment,400\nShopping,500",
    'fitness': "Day,Steps,SleepHours\nMon,8500,7.0\nTue,11000,8.0\nWed,9500,7.5\nThu,12500,8.5\nFri,7000,6.5\nSat,14000,9.0\nSun,10000,8.0",
  };

  // Result Analysis Data
  String? _aiSummary;
  List<Map<String, String>> _metrics = [];
  Map<String, dynamic>? _chartData;

  @override
  void initState() {
    super.initState();
    _csvController.text = _presets[_selectedPreset]!;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _analyzeData() async {
    final csvContent = _csvController.text.trim();
    final userQuery = _queryController.text.trim();
    if (csvContent.isEmpty || userQuery.isEmpty) return;

    setState(() {
      _analyzing = true;
      _aiSummary = null;
      _metrics.clear();
      _chartData = null;
    });

    final settings = context.read<SettingsController>();
    final key = settings.aiProvider == 'gemini' ? settings.geminiApiKey : settings.openaiApiKey;

    final prompt = """
You are an expert Data Analyst & Visualization engine.
Analyze the following CSV dataset and fulfill the user query:

--- DATASET ---
$csvContent

--- USER QUERY ---
$userQuery

Your output MUST be a valid JSON object only (do NOT wrap it in ```json ... ``` markdown blocks, just return raw JSON).
The JSON MUST follow this schema structure:
{
  "summary": "Detailed textual breakdown of trends, key insights and what the data represents",
  "metrics": [
    { "label": "Key Stat Label (e.g. Total Sales)", "value": "Computed Stat Value (e.g. \$108,000)" },
    { "label": "Key Stat Label 2", "value": "Computed Value 2" }
  ],
  "chart": {
    "type": "line", // must be exactly "line", "bar", or "pie"
    "title": "Title of the chart",
    "labels": ["Jan", "Feb", "Mar"], // X-axis labels (or category slices for pie)
    "series": [
      {
        "name": "Series Name (e.g. Sales)",
        "values": [12000.0, 15000.0, 18000.0] // list of double numbers, matching labels list length
      }
    ]
  }
}
""";

    try {
      final reply = await ApiClient().chat(
        messages: [
          {'role': 'user', 'content': prompt}
        ],
        provider: settings.aiProvider,
        apiKey: key,
      );

      // Extract JSON content from reply
      String jsonText = reply.trim();
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.replace(/^```json\s*/, '').replace(/```$/, '').trim();
      }

      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
      
      setState(() {
        _aiSummary = parsed['summary'] as String?;
        
        final mList = parsed['metrics'] as List?;
        if (mList != null) {
          _metrics = mList.map((e) {
            final m = e as Map;
            return {
              'label': m['label']?.toString() ?? '',
              'value': m['value']?.toString() ?? '',
            };
          }).toList();
        }

        _chartData = parsed['chart'] as Map<String, dynamic>?;
        _analyzing = false;
      });

      // Save to history
      if (mounted && _aiSummary != null) {
        context.read<HistoryService>().add(HistoryItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: HistoryType.chat,
          title: 'Data Analysis: ${_chartData?['title'] ?? 'Insight'}',
          detail: _aiSummary!,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          extra: {
            'chartTitle': _chartData?['title'] ?? 'Insight',
            'chartType': _chartData?['type'] ?? 'line',
          },
        ));
      }
    } catch (err) {
      setState(() {
        _aiSummary = "Error during analysis. Please verify your API Key and formatting.\nDetails: $err";
        _analyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preset Buttons and Input Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Choose Dataset', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPresetChip('sales', 'Sales Trend', Icons.trending_up),
                        const SizedBox(width: 8),
                        _buildPresetChip('expense', 'Expenses', Icons.pie_chart),
                        const SizedBox(width: 8),
                        _buildPresetChip('fitness', 'Fitness Activity', Icons.directions_run),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _csvController,
                      maxLines: 5,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'CSV Data',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('2. Prompt for Insight', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        hintText: "e.g. Show sales trends as line chart",
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.psychology),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _analyzing ? null : _analyzeData,
                        icon: _analyzing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_analyzing ? 'Analyzing...' : 'Generate AI Insights & Charts'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Chart Rendering
            if (_chartData != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _chartData!['title'] ?? 'Data Visualization',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 8),
                          child: _buildChartWidget(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Metrics Cards
            if (_metrics.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _metrics.length,
                itemBuilder: (context, index) {
                  final m = _metrics[index];
                  return Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['label'] ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(m['value'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Text Summary Card
            if (_aiSummary != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('AI Analyst Report', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        _aiSummary!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String key, String label, IconData icon) {
    final active = _selectedPreset == key;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: active ? Colors.white : Colors.grey[700]),
      label: Text(label),
      selected: active,
      selectedColor: Theme.of(context).colorScheme.primary,
      textColor: active ? Colors.white : Colors.grey[800],
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedPreset = key;
            _csvController.text = _presets[key]!;
            
            // Adjust default query for selected preset type
            if (key == 'expense') {
              _queryController.text = "Show expense breakdown as a pie chart";
            } else if (key == 'fitness') {
              _queryController.text = "Compare weekly step counts in a bar chart";
            } else {
              _queryController.text = "Analyze this data and display it as a line chart";
            }
          });
        }
      },
    );
  }

  Widget _buildChartWidget() {
    final type = _chartData?['type']?.toString().toLowerCase() ?? 'line';
    final labels = List<String>.from(_chartData?['labels'] ?? []);
    final series = _chartData?['series'] as List? ?? [];
    
    if (labels.isEmpty || series.isEmpty) {
      return const Center(child: Text('Insufficient chart data'));
    }

    if (type == 'pie') {
      final values = List<double>.from(series.first['values']?.map((e) => (e as num).toDouble()) ?? []);
      return PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: List.generate(values.length, (i) {
            final double value = values[i];
            final String label = i < labels.length ? labels[i] : '';
            final color = Colors.primaries[i % Colors.primaries.length];
            return PieChartSectionData(
              color: color,
              value: value,
              title: '$label\n${value.toStringAsFixed(0)}',
              radius: 60,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }),
        ),
      );
    }

    if (type == 'bar') {
      final values = List<double>.from(series.first['values']?.map((e) => (e as num).toDouble()) ?? []);
      final name = series.first['name']?.toString() ?? 'Values';
      
      return BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(labels[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }),
        ),
      );
    }

    // Default to Line Chart
    final lineBars = series.map((s) {
      final sMap = s as Map;
      final values = List<double>.from(sMap['values']?.map((e) => (e as num).toDouble()) ?? []);
      final color = Colors.primaries[series.indexOf(s) % Colors.primaries.length];
      
      return LineChartBarData(
        spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
        isCurved: true,
        color: color,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.15),
        ),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(labels[idx], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!)),
        ),
        lineBarsData: lineBars,
      ),
    );
  }
}
extension TextStyleColor on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
}
