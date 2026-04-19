import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../theme/app_palette.dart';
import 'widgets/profile_action_button.dart';


// ─── Pagrindinis puslapis ────────────────────────────────────────

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final List<AssetItem> _assets = [];

  double get _totalValue => totalAssetValue(_assets);

  void _addAsset() async {
    final result = await showModalBottomSheet<AssetItem>(
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
    final result = await showModalBottomSheet<AssetItem>(
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
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Ištrinti?', style: TextStyle(color: text)),
        content: Text(
          'Ar tikrai norite ištrinti „${_assets[index].name}"?',
          style: TextStyle(color: subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Atšaukti',
                style: TextStyle(color: subtext)),
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
    final background = AppPalette.background(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    final categories = AssetCategory.values;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text(
          'Turtas & Investicijos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [ProfileActionButton()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAsset,
        backgroundColor: AppPalette.accentTeal,
        child: const Icon(Icons.add),
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
                    Icon(Icons.account_balance_outlined,
                        size: 64, color: subtext),
                    const SizedBox(height: 12),
                    Text(
                      'Nėra turto įrašų.\nSpauskite + norėdami pridėti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtext, fontSize: 14),
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
        gradient: AppPalette.heroGradient,
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
  final List<AssetItem> assets;
  const _DistributionChart({required this.assets});

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    final total = assets.fold(0.0, (s, a) => s + a.value);
    final sums = <AssetCategory, double>{
      for (final cat in AssetCategory.values) cat: 0.0,
    };
    for (final a in assets) {
      sums[a.category] = (sums[a.category] ?? 0) + a.value;
    }
    final nonEmpty = sums.entries.where((e) => e.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pasiskirstymas',
              style: TextStyle(
                  color: text,
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
                      style: TextStyle(
                          color: subtext, fontSize: 12)),
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
  final AssetCategory category;
  final List<AssetItem> items;
  final void Function(AssetItem) onEdit;
  final void Function(AssetItem) onDelete;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtext = AppPalette.secondaryText(context);

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
                      TextStyle(color: subtext, fontSize: 13)),
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
  final AssetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
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
                    style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(item.category.label,
                    style: TextStyle(
                        color: subtext, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${item.value.toStringAsFixed(2)} €',
            style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: subtext, size: 18),
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
  final AssetItem? existing;
  const _AddAssetSheet({this.existing});

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late AssetCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _valueCtrl = TextEditingController(
        text: widget.existing?.value.toStringAsFixed(2) ?? '');
    _selectedCategory =
        widget.existing?.category ?? AssetCategory.grynieji;
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
      AssetItem(
        name: name,
        value: value,
        category: _selectedCategory,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final background = AppPalette.background(context);

    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Redaguoti turtą' : 'Pridėti turtą',
              style: TextStyle(
                  color: text,
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
              children: AssetCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat.label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: cat.color,
                  backgroundColor: background,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : subtext),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accentTeal,
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
    final surface = AppPalette.surface(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subtext),
        prefixIcon: Icon(icon, color: subtext, size: 20),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}