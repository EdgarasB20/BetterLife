import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scanned_receipt_result.dart';
import 'receipt_parser.dart';

enum ReceiptScanFailureReason { invalidFormat, scanFailed }

class ReceiptScanException implements Exception {
  final ReceiptScanFailureReason reason;
  final Object? cause;

  const ReceiptScanException(this.reason, {this.cause});

  @override
  String toString() {
    return 'ReceiptScanException($reason, cause: $cause)';
  }
}

class ReceiptOcrService {
  final TextRecognizer _textRecognizer;
  final bool _ownsRecognizer;

  ReceiptOcrService({TextRecognizer? textRecognizer})
    : _textRecognizer =
          textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
      _ownsRecognizer = textRecognizer == null;

  Future<ScannedReceiptResult> scanImage(
    String imagePath, {
    String? fileName,
  }) async {
    final valueForValidation = fileName?.isNotEmpty == true
        ? fileName!
        : imagePath;
    if (!ReceiptParser.isSupportedImageFile(valueForValidation)) {
      throw const ReceiptScanException(ReceiptScanFailureReason.invalidFormat);
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return ReceiptParser.parse(recognizedText.text, imagePath: imagePath);
    } catch (error) {
      throw ReceiptScanException(
        ReceiptScanFailureReason.scanFailed,
        cause: error,
      );
    }
  }

  Future<void> dispose() async {
    if (_ownsRecognizer) {
      await _textRecognizer.close();
    }
  }
}
