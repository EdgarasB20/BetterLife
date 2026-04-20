import 'package:flutter_test/flutter_test.dart';
import 'package:better_life/models/asset.dart';

AssetItem assetItem(String name, double value, AssetCategory category) =>
    AssetItem(name: name, value: value, category: category);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════
  // AssetItem konstruktorius
  // ══════════════════════════════════════════════════════════════
  group('AssetItem konstruktorius', () {
    test('išsaugo laukus teisingai', () {
      final a = assetItem('Butas', 80000, AssetCategory.nt);
      expect(a.name, 'Butas');
      expect(a.value, 80000);
      expect(a.category, AssetCategory.nt);
    });

    test('createdAt nustatomas automatiškai kai nenurodytas', () {
      final before = DateTime.now();
      final a = assetItem('X', 1, AssetCategory.kita);
      final after = DateTime.now();
      expect(
        a.createdAt.isAfter(before) || a.createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        a.createdAt.isBefore(after) || a.createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('createdAt gali būti perduodamas rankiniu būdu', () {
      final date = DateTime(2024, 6, 15);
      final a = AssetItem(
          name: 'Senas', value: 500, category: AssetCategory.santaupos,
          createdAt: date);
      expect(a.createdAt, date);
    });

    test('vertė gali būti 0', () {
      final a = assetItem('Nulinis', 0, AssetCategory.grynieji);
      expect(a.value, 0.0);
    });

    test('vertė gali būti didelis skaičius', () {
      final a = assetItem('Namas', 999999.99, AssetCategory.nt);
      expect(a.value, closeTo(999999.99, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // totalAssetValue
  // ══════════════════════════════════════════════════════════════
  group('totalAssetValue', () {
    test('0.0 tuščiam sąrašui', () {
      expect(totalAssetValue([]), 0.0);
    });

    test('teisingai sumuoja vieną elementą', () {
      expect(totalAssetValue([assetItem('A', 500, AssetCategory.grynieji)]),
          500.0);
    });

    test('teisingai sumuoja kelis elementus', () {
      final assets = [
        assetItem('A', 100, AssetCategory.grynieji),
        assetItem('B', 250, AssetCategory.santaupos),
        assetItem('C', 650, AssetCategory.nt),
      ];
      expect(totalAssetValue(assets), closeTo(1000, 0.001));
    });

    test('teisingai sumuoja skirtingas kategorijas', () {
      final assets = [
        assetItem('X', 333.33, AssetCategory.kita),
        assetItem('Y', 666.67, AssetCategory.nt),
      ];
      expect(totalAssetValue(assets), closeTo(1000, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // categorySums
  // ══════════════════════════════════════════════════════════════
  group('categorySums', () {
    test('visos kategorijos pradeda nuo 0', () {
      final sums = categorySums([]);
      for (final cat in AssetCategory.values) {
        expect(sums[cat], 0.0);
      }
    });

    test('teisingai priskiria elementus kategorijoms', () {
      final assets = [
        assetItem('Grynieji 1', 100, AssetCategory.grynieji),
        assetItem('Grynieji 2', 200, AssetCategory.grynieji),
        assetItem('Santaupos', 500, AssetCategory.santaupos),
      ];
      final sums = categorySums(assets);
      expect(sums[AssetCategory.grynieji], closeTo(300, 0.001));
      expect(sums[AssetCategory.santaupos], closeTo(500, 0.001));
      expect(sums[AssetCategory.nt], 0.0);
      expect(sums[AssetCategory.kita], 0.0);
    });

    test('categorySums suma lygi totalAssetValue', () {
      final assets = [
        assetItem('A', 150, AssetCategory.grynieji),
        assetItem('B', 350, AssetCategory.nt),
        assetItem('C', 200, AssetCategory.kita),
      ];
      final sums = categorySums(assets);
      final sumOfSums = sums.values.fold(0.0, (a, b) => a + b);
      expect(sumOfSums, closeTo(totalAssetValue(assets), 0.001));
    });

    test('NT kategorija sumuojama teisingai', () {
      final assets = [
        assetItem('Butas', 120000, AssetCategory.nt),
        assetItem('Garažas', 15000, AssetCategory.nt),
      ];
      final sums = categorySums(assets);
      expect(sums[AssetCategory.nt], closeTo(135000, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Kategorijų pasiskirstymo procentai
  // ══════════════════════════════════════════════════════════════
  group('Pasiskirstymo procentai', () {
    test('teisingai apskaičiuojami procentai', () {
      final assets = [
        assetItem('A', 500, AssetCategory.grynieji),
        assetItem('B', 500, AssetCategory.santaupos),
      ];
      final total = totalAssetValue(assets);
      final sums = categorySums(assets);
      final pctGrynieji = sums[AssetCategory.grynieji]! / total * 100;
      final pctSantaupos = sums[AssetCategory.santaupos]! / total * 100;
      expect(pctGrynieji, closeTo(50.0, 0.001));
      expect(pctSantaupos, closeTo(50.0, 0.001));
    });

    test('viena kategorija – 100%', () {
      final assets = [assetItem('Viskas', 1000, AssetCategory.kita)];
      final total = totalAssetValue(assets);
      final sums = categorySums(assets);
      final pct = sums[AssetCategory.kita]! / total * 100;
      expect(pct, closeTo(100.0, 0.001));
    });

    test('procentai sumuojasi į 100', () {
      final assets = [
        assetItem('A', 300, AssetCategory.grynieji),
        assetItem('B', 400, AssetCategory.nt),
        assetItem('C', 300, AssetCategory.santaupos),
      ];
      final total = totalAssetValue(assets);
      final sums = categorySums(assets);
      final totalPct =
          sums.values.fold(0.0, (s, v) => s + (v / total * 100));
      expect(totalPct, closeTo(100.0, 0.001));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Sąrašo manipuliacija (simuliuoja _AssetsPageState)
  // ══════════════════════════════════════════════════════════════
  group('Sąrašo manipuliacija', () {
    test('pridėjimas padidina sąrašą', () {
      final assets = <AssetItem>[];
      assets.add(assetItem('Naujas', 100, AssetCategory.grynieji));
      expect(assets.length, 1);
    });

    test('ištrynimas pagal indeksą veikia', () {
      final assets = [
        assetItem('A', 100, AssetCategory.grynieji),
        assetItem('B', 200, AssetCategory.santaupos),
        assetItem('C', 300, AssetCategory.nt),
      ];
      assets.removeAt(1); // pašalinti 'B'
      expect(assets.length, 2);
      expect(assets.any((a) => a.name == 'B'), isFalse);
    });

    test('pakeitimas pagal indeksą veikia', () {
      final assets = [
        assetItem('Senas', 500, AssetCategory.kita),
      ];
      assets[0] = assetItem('Naujas', 750, AssetCategory.santaupos);
      expect(assets[0].name, 'Naujas');
      expect(assets[0].value, 750);
    });

    test('totalAssetValue atsinaujina po ištrynimo', () {
      final assets = [
        assetItem('A', 1000, AssetCategory.nt),
        assetItem('B', 500, AssetCategory.grynieji),
      ];
      assets.removeAt(0);
      expect(totalAssetValue(assets), closeTo(500, 0.001));
    });
  });
}
