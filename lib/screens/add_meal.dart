import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yakkit_calorie_tracker/models/food_item.dart';
import 'package:yakkit_calorie_tracker/services/food_data_service.dart';

class AddMealPage extends StatefulWidget {
  final int mealIndex;
  final List<FoodItem> recentlyAdded;

  const AddMealPage({
    Key? key,
    required this.mealIndex,
    required this.recentlyAdded,
  }) : super(key: key);

  @override
  _AddMealPageState createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<FoodItem> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = _searchController.text;
      if (q.length < 2) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await FoodDataService().searchFoodItems(q);
        final Map<String, int> nameCounts = {};
        final filtered = <FoodItem>[];
        for (var item in results) {
          final key = item.name.trim().toLowerCase();
          final count = nameCounts[key] ?? 0;
          if (count < 3) {
            filtered.add(item);
            nameCounts[key] = count + 1;
          }
        }
        if (!mounted) return;
        setState(() => _searchResults = filtered);
      } catch (_) {
        setState(() => _searchResults = []);
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ["Kahvalti", "Ogle Yemegi", "Aksam Yemegi", "Atistirmalik"];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[widget.mealIndex]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ne arıyorsun?',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Yakın Zaman’da', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (ctx, i) => _buildTile(_searchResults[i]),
              )
                  : widget.recentlyAdded.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Son Eklenenler', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.recentlyAdded.length,
                      itemBuilder: (ctx, i) => _buildTile(widget.recentlyAdded[i]),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount: _defaultSuggestions.length,
                itemBuilder: (ctx, i) => _buildTile(_defaultSuggestions[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Yeni Yiyecek Ekle',
        onPressed: _showAddFoodDialog,
      ),
    );
  }

  final List<FoodItem> _defaultSuggestions = [
    FoodItem(id: 0, name: 'Simit', calories: 110),
    FoodItem(id: 0, name: 'Hamburger', calories: 300),
    FoodItem(id: 0, name: 'Patates Kizartmasi', calories: 250),
  ];

  Widget _buildTile(FoodItem item) {
    return ListTile(
      title: Text(item.name),
      trailing: Text('${item.calories} kcal'),
      onTap: () => Navigator.pop(context, item),
    );
  }

  void _showAddFoodDialog() {
    final _nameCtrl = TextEditingController();
    final _calCtrl = TextEditingController();
    final _carbCtrl = TextEditingController();
    final _protCtrl = TextEditingController();
    final _fatCtrl = TextEditingController();
    final _fibrCtrl = TextEditingController();
    final _sugCtrl = TextEditingController();

    String _normalizeNumber(String input) {
      return input.trim().replaceAll(',', '.');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Yiyecek Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ad')),
              TextField(
                controller: _calCtrl,
                decoration: const InputDecoration(labelText: 'Kalori (100g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _carbCtrl,
                decoration: const InputDecoration(labelText: 'Karbonhidrat (g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _protCtrl,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _fatCtrl,
                decoration: const InputDecoration(labelText: 'Yağ (g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _fibrCtrl,
                decoration: const InputDecoration(labelText: 'Lif (g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: _sugCtrl,
                decoration: const InputDecoration(labelText: 'Şeker (g)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              // 1) Alan doluluk kontrolü
              if (_nameCtrl.text.trim().isEmpty ||
                  _calCtrl.text.trim().isEmpty ||
                  _carbCtrl.text.trim().isEmpty ||
                  _protCtrl.text.trim().isEmpty ||
                  _fatCtrl.text.trim().isEmpty ||
                  _fibrCtrl.text.trim().isEmpty ||
                  _sugCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                );
                return;
              }

              // 2) Numeric parse kontrolü, nokta ve virgül kabul edilir
              final cal = double.tryParse(_normalizeNumber(_calCtrl.text));
              final carb = double.tryParse(_normalizeNumber(_carbCtrl.text));
              final prot = double.tryParse(_normalizeNumber(_protCtrl.text));
              final fat = double.tryParse(_normalizeNumber(_fatCtrl.text));
              final fibr = double.tryParse(_normalizeNumber(_fibrCtrl.text));
              final sug = double.tryParse(_normalizeNumber(_sugCtrl.text));
              if (cal == null || carb == null || prot == null || fat == null || fibr == null || sug == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen geçerli sayı girin.')),
                );
                return;
              }

              Navigator.pop(ctx);

              try {
                final newItem = await FoodDataService().createFoodItem(
                  name: _nameCtrl.text.trim(),
                  calories100g: cal,
                  carbs100g: carb,
                  proteins100g: prot,
                  fat100g: fat,
                  fiber100g: fibr,
                  sugars100g: sug,
                );
                // Debug: ID'nin dolu geldiğini kontrol edin
                print("⚙️ Created FoodItem id=${newItem.id}");
                if (!mounted) return;
                setState(() => _searchResults.insert(0, newItem));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${newItem.name} başarıyla eklendi!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ekleme hatası: $e')),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
