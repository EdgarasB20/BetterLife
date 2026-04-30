import 'package:better_life/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptParser', () {
    test('extracts merchant, total amount, date and raw text', () {
      const rawText = '''
MAXIMA LT
PVM kodas LT123456
2026-04-18
Prekes 8,20
IŠ VISO 12,34
''';

      final result = ReceiptParser.parse(rawText, imagePath: 'receipt.jpg');

      expect(result.merchantName, 'MAXIMA LT');
      expect(result.totalAmount, 12.34);
      expect(result.date, DateTime(2026, 4, 18));
      expect(result.rawText, rawText);
      expect(result.imagePath, 'receipt.jpg');
      expect(result.hasRecognizedExpenseData, isTrue);
    });

    test('keeps result safe when required amount is missing', () {
      final result = ReceiptParser.parse('Neryškus čekio tekstas');

      expect(result.totalAmount, isNull);
      expect(result.date, isNull);
      expect(result.hasRecognizedExpenseData, isFalse);
    });

    test('uses final payable total instead of subtotal before discount', () {
      const rawText = '''
MAXIMA LT
Prekių suma 20,00
Nuolaida -3,50
IŠ VISO 16,50
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.totalAmount, 16.50);
    });

    test('calculates discounted total when final total line is missing', () {
      const rawText = '''
RIMI
Prekių suma 20,00
Nuolaida -3,50
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.totalAmount, 16.50);
    });

    test('validates supported image formats', () {
      expect(ReceiptParser.isSupportedImageFile('cekis.jpg'), isTrue);
      expect(ReceiptParser.isSupportedImageFile('cekis.JPEG'), isTrue);
      expect(ReceiptParser.isSupportedImageFile('cekis.png'), isTrue);
      expect(ReceiptParser.isSupportedImageFile('cekis.heic'), isTrue);
      expect(ReceiptParser.isSupportedImageFile('cekis.pdf'), isFalse);
    });
  });
}
