import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────────────

enum _AssetCategory { grynieji, santaupos, nt, kita }

extension _AssetCategoryExt on _AssetCategory {
  String get label {
    switch (this) {
      case _AssetCategory.grynieji:
        return 'Grynieji';
      case _AssetCategory.santaupos:
        return 'Santaupos';
      case _AssetCategory.nt:
        return 'NT';
      case _AssetCategory.kita:
        return 'Kita';
    }
  }

  IconData get icon {
    switch (this) {
      case _AssetCategory.grynieji:
        return Icons.payments_rounded;
      case _AssetCategory.santaupos:
        return Icons.savings_rounded;
      case _AssetCategory.nt:
        return Icons.home_work_rounded;
      case _AssetCategory.kita:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _AssetCategory.grynieji:
        return Colors.teal.shade400;
      case _AssetCategory.santaupos:
        return Colors.blue.shade400;
      case _AssetCategory.nt:
        return Colors.orange.shade400;
      case _AssetCategory.kita:
        return Colors.purple.shade300;
    }
  }
}

// ─── Modelis ─────────────────────────────────────────────────────

class _AssetItem {
  final String name;
  final double value;
  final _AssetCategory category;
  final DateTime createdAt;

  _AssetItem({
    required this.name,
    required this.value,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ─── Pagrindinis puslapis ────────────────────────────────────────

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final List<_AssetItem> _assets = [];

  double get _totalValue => _assets.fold(0, (sum, a) => sum + a.value);

  void _addAsset() async {
    final result = await showModalBottomSheet<_AssetItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAssetSheet(),
    );
    if (result != null) {
      setState(() => _assets.add(result));
    }
  }

  void _editAsset(int index) async {
    final result = await showModalBottomSheet<_AssetItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAssetSheet(existing: _assets[index]),
    );
    if (result != null) {
      setState(() => _assets[index] = result);
    }
  }

  void _deleteAsset(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('Ištrinti?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Ar tikrai norite ištrinti „${_assets[index].name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Atšaukti',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _assets.removeAt(index));
            },
            child: const Text('Ištrinti',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _AssetCategory.values;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        title: const Text(
          'Turtas & Investicijos',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAsset,
        backgroundColor: Colors.teal.shade400,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TotalValueCard(totalValue: _totalValue),
          const SizedBox(height: 20),
          if (_assets.isNotEmpty) ...[
            _DistributionChart(assets: _assets),
            const SizedBox(height: 20),
          ],
          ...categories.map((cat) {
            final items = _assets.where((a) => a.category == cat).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return _CategorySection(
              category: cat,
              items: items,
              onEdit: (item) => _editAsset(_assets.indexOf(item)),
              onDelete: (item) => _deleteAsset(_assets.indexOf(item)),
            );
          }),
          if (_assets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_outlined,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text(
                      'Nėra turto įrašų.\nSpauskite + norėdami pridėti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bendra vertė ────────────────────────────────────────────────

class _TotalValueCard extends StatelessWidget {
  final double totalValue;
  const _TotalValueCard({required this.totalValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bendra turto vertė',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${totalValue.toStringAsFixed(2)} €',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ─── Pasiskirstymo grafikas ───────────────────────────────────────

class _DistributionChart extends StatelessWidget {
  final List<_AssetItem> assets;
  const _DistributionChart({required this.assets});

  @override
  Widget build(BuildContext context) {
    final total = assets.fold(0.0, (s, a) => s + a.value);
    final sums = <_AssetCategory, double>{
      for (final cat in _AssetCategory.values) cat: 0.0,
    };
    for (final a in assets) {
      sums[a.category] = (sums[a.category] ?? 0) + a.value;
    }
    final nonEmpty = sums.entries.where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pasiskirstymas',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: nonEmpty.map((e) {
                  final pct = e.value / total;
                  return Expanded(
                    flex: (pct * 1000).round(),
                    child: Container(color: e.key.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: nonEmpty.map((e) {
              final pct = (e.value / total * 100).toStringAsFixed(1);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: e.key.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('${e.key.label} $pct%',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Kategorijų sekcija ───────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _AssetCategory category;
  final List<_AssetItem> items;
  final void Function(_AssetItem) onEdit;
  final void Function(_AssetItem) onDelete;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (s, a) => s + a.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 18),
              const SizedBox(width: 6),
              Text(category.label,
                  style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              Text('${total.toStringAsFixed(2)} €',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        ...items.map((item) => _AssetTile(
              item: item,
              onEdit: () => onEdit(item),
              onDelete: () => onDelete(item),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Turto eilutė ────────────────────────────────────────────────

class _AssetTile extends StatelessWidget {
  final _AssetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.category.icon,
                color: item.category.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(item.category.label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${item.value.toStringAsFixed(2)} €',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white38, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Pridėti / redaguoti turtą ────────────────────────────────────

class _AddAssetSheet extends StatefulWidget {
  final _AssetItem? existing;
  const _AddAssetSheet({this.existing});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late _AssetCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _valueCtrl = TextEditingController(
        text: widget.existing?.value.toStringAsFixed(2) ?? '');
    _selectedCategory =
        widget.existing?.category ?? _AssetCategory.grynieji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final value = double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || value == null) return;
    Navigator.pop(
      context,
      _AssetItem(
        name: name,
        value: value,
        category: _selectedCategory,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D27),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Redaguoti turtą' : 'Pridėti turtą',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildField(_nameCtrl, 'Pavadinimas', Icons.label_outline),
            const SizedBox(height: 12),
            _buildField(_valueCtrl, 'Vertė (€)', Icons.euro_rounded,
                isNumber: true),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _AssetCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: cat.color,
                  backgroundColor: const Color(0xFF0F1117),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white54),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Išsaugoti' : 'Pridėti',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF0F1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}