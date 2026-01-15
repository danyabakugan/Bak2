import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MarketplaceTabsScreen(),
    );
  }
}

class MarketplaceTabsScreen extends StatefulWidget {
  const MarketplaceTabsScreen({super.key});

  @override
  State<MarketplaceTabsScreen> createState() => _MarketplaceTabsScreenState();
}

class _MarketplaceTabsScreenState extends State<MarketplaceTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picker App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'WB'),
            Tab(text: 'Ozon'),
            Tab(text: 'Yandex'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BatchList(marketplace: 'WB'),
          BatchList(marketplace: 'Ozon'),
          BatchList(marketplace: 'YandexMarket'),
        ],
      ),
    );
  }
}

class BatchList extends StatefulWidget {
  final String marketplace;
  const BatchList({super.key, required this.marketplace});

  @override
  State<BatchList> createState() => _BatchListState();
}

class _BatchListState extends State<BatchList> {
  List<dynamic> batches = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_url') ?? 'https://your-app.replit.app';
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/picker/batches?marketplace=${widget.marketplace}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          batches = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load batches: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (batches.isEmpty) return const Center(child: Text('No open batches'));

    return RefreshIndicator(
      onRefresh: fetchBatches,
      child: ListView.builder(
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(batch['title'] ?? 'Batch #${batch['id']}'),
              subtitle: Text(batch['createdAt']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BatchLinesScreen(batchId: batch['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BatchLinesScreen extends StatefulWidget {
  final int batchId;
  const BatchLinesScreen({super.key, required this.batchId});

  @override
  State<BatchLinesScreen> createState() => _BatchLinesScreenState();
}

class _BatchLinesScreenState extends State<BatchLinesScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLines();
  }

  Future<void> fetchLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_url') ?? 'https://your-app.replit.app';
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/picker/batches/${widget.batchId}/lines'),
      );

      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> confirmLine(String groupId, int lineId, int qty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_url') ?? 'https://your-app.replit.app';

      final response = await http.post(
        Uri.parse('$baseUrl/api/picker/batches/${widget.batchId}/lines/$lineId/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'qty': qty}),
      );

      if (response.statusCode == 200) {
        fetchLines(); // Refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> closeBatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('api_url') ?? 'https://your-app.replit.app';

      final response = await http.post(
        Uri.parse('$baseUrl/api/picker/batches/${widget.batchId}/close'),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (data == null) return const Scaffold(body: Center(child: Text("Error loading")));

    final groups = data!['groups'] as List;

    return Scaffold(
      appBar: AppBar(title: Text(data!['batch']['title'])),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isDone = group['isFullyConfirmed'];
                final remaining = group['totalQty'] - group['confirmedQty'];
                
                return Card(
                  color: isDone ? Colors.green.shade50 : null,
                  child: ListTile(
                    title: Text('${group['title']}'),
                    subtitle: Text(
                      group['kind'] == 'Other' 
                        ? 'SKU: ${group['sku']}' 
                        : 'Size: ${group['size']} / ${group['color']}'
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Text('${group['confirmedQty']} / ${group['totalQty']}', 
                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                         if (!isDone)
                           IconButton(
                             icon: const Icon(Icons.check_circle_outline),
                             onPressed: () {
                               // Assuming first lineId for simplicity in this example
                               // Real implementation might distribute confirmation across lines
                               final lineId = group['lineIds'][0];
                               confirmLine(group['groupId'], lineId, remaining);
                             },
                           )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: closeBatch,
              child: const Text("Close Batch"),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('api_url') ?? '';
  }

  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', _urlController.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'API Base URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveUrl, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
