import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/scanned_receipt_result.dart';
import '../services/receipt_ocr_service.dart';
import '../services/receipt_parser.dart';
import '../theme/app_palette.dart';

const receiptScanFailedMessage =
    'Nepavyko nuskenuoti čekio. Patikrinkite, ar nuotrauka aiški, ir bandykite dar kartą.';
const receiptDataNotRecognizedMessage =
    'Nepavyko atpažinti čekio duomenų. Galite bandyti dar kartą arba suvesti išlaidą rankiniu būdu.';

class ReceiptScannerOutcome {
  final ScannedReceiptResult? result;
  final bool openManualEntry;

  const ReceiptScannerOutcome.scanned(this.result) : openManualEntry = false;

  const ReceiptScannerOutcome.manualEntry()
    : result = null,
      openManualEntry = true;
}

enum _ReceiptScannerState { idle, processing, success, error }

class ReceiptScannerPage extends StatefulWidget {
  final ReceiptOcrService? receiptOcrService;
  final ImagePicker? imagePicker;

  const ReceiptScannerPage({
    super.key,
    this.receiptOcrService,
    this.imagePicker,
  });

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  late final ReceiptOcrService _receiptOcrService;
  late final ImagePicker _imagePicker;
  late final bool _ownsService;

  _ReceiptScannerState _state = _ReceiptScannerState.idle;
  ScannedReceiptResult? _result;
  String? _errorMessage;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.receiptOcrService == null;
    _receiptOcrService = widget.receiptOcrService ?? ReceiptOcrService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  @override
  void dispose() {
    if (_ownsService) {
      _receiptOcrService.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_state == _ReceiptScannerState.processing) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (!mounted || image == null) {
        return;
      }

      await _processImage(image);
    } catch (_) {
      if (mounted) {
        _showError(receiptScanFailedMessage);
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    final fileName = image.name.isNotEmpty ? image.name : image.path;
    if (!ReceiptParser.isSupportedImageFile(fileName)) {
      _showError(
        'Nepalaikomas failo formatas. Pasirinkite jpg, jpeg, png arba heic.',
      );
      return;
    }

    setState(() {
      _state = _ReceiptScannerState.processing;
      _selectedFileName = fileName;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _receiptOcrService.scanImage(
        image.path,
        fileName: fileName,
      );

      if (!mounted) {
        return;
      }

      if (result.rawText.trim().isEmpty) {
        _showError(receiptScanFailedMessage);
        return;
      }

      if (!result.hasRecognizedExpenseData) {
        _showError(receiptDataNotRecognizedMessage);
        return;
      }

      setState(() {
        _state = _ReceiptScannerState.success;
        _result = result;
        _errorMessage = null;
      });
    } on ReceiptScanException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        error.reason == ReceiptScanFailureReason.invalidFormat
            ? 'Nepalaikomas failo formatas. Pasirinkite jpg, jpeg, png arba heic.'
            : receiptScanFailedMessage,
      );
    } catch (_) {
      if (mounted) {
        _showError(receiptScanFailedMessage);
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _state = _ReceiptScannerState.error;
      _errorMessage = message;
      _result = null;
    });
  }

  void _retry() {
    setState(() {
      _state = _ReceiptScannerState.idle;
      _errorMessage = null;
      _result = null;
      _selectedFileName = null;
    });
  }

  void _openManualEntry() {
    Navigator.pop(context, const ReceiptScannerOutcome.manualEntry());
  }

  void _confirmScannedReceipt() {
    final result = _result;
    if (result == null) {
      return;
    }

    Navigator.pop(context, ReceiptScannerOutcome.scanned(result));
  }

  @override
  Widget build(BuildContext context) {
    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Čekio skenavimas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.accentGreen.withValues(
                    alpha: .16,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppPalette.accentGreen,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pasirinkite čekio nuotrauką',
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nufotografuokite čekį arba pasirinkite jau turimą nuotrauką.',
                  style: TextStyle(color: subtext),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('receipt-camera-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _state == _ReceiptScannerState.processing
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Fotografuoti'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('receipt-gallery-button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _state == _ReceiptScannerState.processing
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Iš galerijos'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_state == _ReceiptScannerState.processing)
            _ProcessingState(fileName: _selectedFileName)
          else if (_state == _ReceiptScannerState.success && _result != null)
            _SuccessState(
              result: _result!,
              onConfirm: _confirmScannedReceipt,
              onRetry: _retry,
            )
          else if (_state == _ReceiptScannerState.error)
            _ErrorState(
              message: _errorMessage ?? receiptScanFailedMessage,
              onRetry: _retry,
              onManualEntry: _openManualEntry,
            ),
        ],
      ),
    );
  }
}

class _ProcessingState extends StatelessWidget {
  final String? fileName;

  const _ProcessingState({this.fileName});

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Čekis apdorojamas...',
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 6),
            Text(
              fileName!,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtext),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  final ScannedReceiptResult result;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const _SuccessState({
    required this.result,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final date = result.date;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppPalette.accentGreen.withValues(alpha: .16),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppPalette.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Čekio duomenys atpažinti',
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReceiptDataRow(
            label: 'Pavadinimas',
            value: result.merchantName ?? 'Neatpažinta',
          ),
          _ReceiptDataRow(
            label: 'Suma',
            value: result.totalAmount != null
                ? '€${result.totalAmount!.toStringAsFixed(2)}'
                : 'Neatpažinta',
          ),
          _ReceiptDataRow(
            label: 'Data',
            value: date != null
                ? DateFormat('dd.MM.yyyy').format(date)
                : 'Bus naudojama šiandienos data',
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: subtext,
            iconColor: subtext,
            title: Text(
              'Atpažintas tekstas',
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(result.rawText, style: TextStyle(color: subtext)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accentGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: onConfirm,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Tikrinti ir išsaugoti'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Skenuoti dar kartą'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onManualEntry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade400.withValues(alpha: .16),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Bandyti dar kartą'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accentGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onManualEntry,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Suvesti ranka'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptDataRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptDataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: subtext)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: text, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
