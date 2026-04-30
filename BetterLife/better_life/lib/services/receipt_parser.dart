import '../models/scanned_receipt_result.dart';

class ReceiptParser {
  static const supportedImageExtensions = {'jpg', 'jpeg', 'png', 'heic'};

  static ScannedReceiptResult parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ScannedReceiptResult(
      merchantName: _extractMerchantName(lines),
      totalAmount: _extractTotalAmount(lines),
      date: _extractDate(rawText),
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  static bool isSupportedImageFile(String pathOrName) {
    final cleanValue = pathOrName.split('?').first.toLowerCase();
    final match = RegExp(r'\.([a-z0-9]+)$').firstMatch(cleanValue);
    if (match == null) {
      return false;
    }

    return supportedImageExtensions.contains(match.group(1));
  }

  static String? _extractMerchantName(List<String> lines) {
    for (final line in lines.take(8)) {
      final normalized = _normalize(line);
      final looksLikeMetadata =
          normalized.contains('pvm') ||
          normalized.contains('kodas') ||
          normalized.contains('cekis') ||
          normalized.contains('kvitas') ||
          normalized.contains('kasa') ||
          normalized.contains('nr') ||
          normalized.contains('data');

      if (!looksLikeMetadata &&
          !_lineContainsDate(line) &&
          _amountsIn(line).isEmpty) {
        return line;
      }
    }

    return lines.isEmpty ? null : lines.first;
  }

  static double? _extractTotalAmount(List<String> lines) {
    final finalTotalCandidates = <_AmountCandidate>[];
    final subtotalCandidates = <_AmountCandidate>[];
    final fallbackCandidates = <_AmountCandidate>[];
    final discountCandidates = <_AmountCandidate>[];

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final amounts = _amountsIn(line);
      if (amounts.isEmpty) {
        continue;
      }

      final normalized = _normalize(line);
      final isDiscountLine = _isDiscountLine(normalized);
      final totalPriority = _totalKeywordPriority(normalized);

      for (var amountIndex = 0; amountIndex < amounts.length; amountIndex++) {
        final candidate = _AmountCandidate(
          amount: amounts[amountIndex],
          lineIndex: lineIndex,
          amountIndex: amountIndex,
          priority: totalPriority,
        );

        if (isDiscountLine && !_isSubtotalBeforeDiscountLine(normalized)) {
          discountCandidates.add(candidate);
          continue;
        }

        if (_isTaxLine(normalized)) {
          continue;
        }

        if (totalPriority >= 3) {
          finalTotalCandidates.add(candidate);
        } else if (totalPriority > 0) {
          subtotalCandidates.add(candidate);
        } else if (!_lineContainsDate(line) && !isDiscountLine) {
          fallbackCandidates.add(candidate);
        }
      }
    }

    if (finalTotalCandidates.isNotEmpty) {
      return _bestCandidate(finalTotalCandidates).amount;
    }

    if (subtotalCandidates.isNotEmpty) {
      final subtotal = _bestCandidate(subtotalCandidates);
      if (discountCandidates.isNotEmpty) {
        final lastDiscountLine = discountCandidates
            .map((candidate) => candidate.lineIndex)
            .reduce((a, b) => a > b ? a : b);

        if (subtotal.lineIndex < lastDiscountLine) {
          final discountTotal = discountCandidates.fold<double>(
            0,
            (sum, candidate) => sum + candidate.amount,
          );
          final discountedTotal = subtotal.amount - discountTotal;
          if (discountedTotal > 0) {
            return double.parse(discountedTotal.toStringAsFixed(2));
          }
        }
      }

      return subtotal.amount;
    }

    if (fallbackCandidates.isNotEmpty) {
      return _bestCandidate(fallbackCandidates).amount;
    }

    return null;
  }

  static DateTime? _extractDate(String rawText) {
    final yearFirst = RegExp(r'\b(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})\b');
    final yearFirstMatch = yearFirst.firstMatch(rawText);
    if (yearFirstMatch != null) {
      return _safeDate(
        int.parse(yearFirstMatch.group(1)!),
        int.parse(yearFirstMatch.group(2)!),
        int.parse(yearFirstMatch.group(3)!),
      );
    }

    final dayFirst = RegExp(r'\b(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{2,4})\b');
    final dayFirstMatch = dayFirst.firstMatch(rawText);
    if (dayFirstMatch != null) {
      var year = int.parse(dayFirstMatch.group(3)!);
      if (year < 100) {
        year += 2000;
      }

      return _safeDate(
        year,
        int.parse(dayFirstMatch.group(2)!),
        int.parse(dayFirstMatch.group(1)!),
      );
    }

    return null;
  }

  static List<double> _amountsIn(String line) {
    final amountPattern = RegExp(
      r'(^|[^\d])(\d{1,3}(?:[ \u00A0]\d{3})*[,.]\d{2}|\d+[,.]\d{2})(?!\d)',
    );

    return amountPattern
        .allMatches(line)
        .map((match) => match.group(2)!)
        .map(
          (value) =>
              value.replaceAll(RegExp(r'[ \u00A0]'), '').replaceAll(',', '.'),
        )
        .map(double.tryParse)
        .whereType<double>()
        .where((value) => value > 0 && value < 10000)
        .toList();
  }

  static int _totalKeywordPriority(String normalizedLine) {
    if (normalizedLine.contains('moketi') ||
        normalizedLine.contains('moketa') ||
        normalizedLine.contains('sumoketa') ||
        normalizedLine.contains('apmoketa') ||
        normalizedLine.contains('galutine') ||
        normalizedLine.contains('is viso') ||
        normalizedLine.contains('total') ||
        normalizedLine.contains('kortele') ||
        normalizedLine.contains('grynais')) {
      return 4;
    }

    if (normalizedLine.contains('viso')) {
      return 3;
    }

    if (normalizedLine.contains('suma') || normalizedLine.contains('amount')) {
      return 2;
    }

    return 0;
  }

  static _AmountCandidate _bestCandidate(List<_AmountCandidate> candidates) {
    return candidates.reduce((current, next) {
      if (next.priority != current.priority) {
        return next.priority > current.priority ? next : current;
      }

      if (next.lineIndex != current.lineIndex) {
        return next.lineIndex > current.lineIndex ? next : current;
      }

      if (next.amountIndex != current.amountIndex) {
        return next.amountIndex > current.amountIndex ? next : current;
      }

      return next.amount > current.amount ? next : current;
    });
  }

  static bool _isDiscountLine(String normalizedLine) {
    return normalizedLine.contains('nuolaid') ||
        normalizedLine.contains('discount') ||
        normalizedLine.contains('akcij') ||
        normalizedLine.contains('sutaup');
  }

  static bool _isSubtotalBeforeDiscountLine(String normalizedLine) {
    return normalizedLine.contains('suma be nuolaid') ||
        normalizedLine.contains('pries nuolaid') ||
        normalizedLine.contains('prekiu suma');
  }

  static bool _isTaxLine(String normalizedLine) {
    return normalizedLine.contains('pvm') ||
        normalizedLine.contains('vat') ||
        normalizedLine.contains('mokesc');
  }

  static bool _lineContainsDate(String line) {
    return RegExp(r'\b\d{4}[.\-/]\d{1,2}[.\-/]\d{1,2}\b').hasMatch(line) ||
        RegExp(r'\b\d{1,2}[.\-/]\d{1,2}[.\-/]\d{2,4}\b').hasMatch(line);
  }

  static DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ą', 'a')
        .replaceAll('č', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ė', 'e')
        .replaceAll('į', 'i')
        .replaceAll('š', 's')
        .replaceAll('ų', 'u')
        .replaceAll('ū', 'u')
        .replaceAll('ž', 'z');
  }
}

class _AmountCandidate {
  final double amount;
  final int lineIndex;
  final int amountIndex;
  final int priority;

  const _AmountCandidate({
    required this.amount,
    required this.lineIndex,
    required this.amountIndex,
    required this.priority,
  });
}
