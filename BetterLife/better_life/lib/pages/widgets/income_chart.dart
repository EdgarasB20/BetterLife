import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/income.dart';
import '../../theme/app_palette.dart';

enum IncomePeriod { week, month, sixMonths, year }

extension IncomePeriodX on IncomePeriod {
  String get label {
    switch (this) {
      case IncomePeriod.week:
        return '1W';
      case IncomePeriod.month:
        return '1M';
      case IncomePeriod.sixMonths:
        return '6M';
      case IncomePeriod.year:
        return '1Y';
    }
  }
}

class IncomeChart extends StatelessWidget {
  const IncomeChart({
    super.key,
    required this.incomes,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.textColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  final List<Income> incomes;
  final IncomePeriod selectedPeriod;
  final ValueChanged<IncomePeriod> onPeriodSelected;
  final Color textColor;
  final Color borderColor;
  final Color surfaceColor;

  List<DateTime> _chartBuckets(DateTime now) {
    switch (selectedPeriod) {
      case IncomePeriod.week:
        final firstDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return List.generate(7, (index) => firstDay.add(Duration(days: index)));
      case IncomePeriod.month:
        final firstDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        return List.generate(
          30,
          (index) => firstDay.add(Duration(days: index)),
        );
      case IncomePeriod.sixMonths:
        return List.generate(6, (index) {
          final month = now.month - 5 + index;
          return DateTime(now.year, month, 1);
        });
      case IncomePeriod.year:
        return List.generate(12, (index) {
          final month = now.month - 11 + index;
          return DateTime(now.year, month, 1);
        });
    }
  }

  String _bucketLabel(DateTime date) {
    if (selectedPeriod == IncomePeriod.week ||
        selectedPeriod == IncomePeriod.month) {
      return DateFormat('dd').format(date);
    }

    const monthLabels = [
      'Sau',
      'Vas',
      'Kov',
      'Bal',
      'Geg',
      'Bir',
      'Lie',
      'Rgp',
      'Rgs',
      'Spl',
      'Lap',
      'Grd',
    ];
    return monthLabels[date.month - 1];
  }

  String _tooltipLabel(DateTime date) {
    if (selectedPeriod == IncomePeriod.week ||
        selectedPeriod == IncomePeriod.month) {
      return DateFormat('dd.MM.yyyy').format(date);
    }
    return _bucketLabel(date);
  }

  List<double> _prepareChartValues(List<Income> incomes, DateTime now) {
    final buckets = _chartBuckets(now);
    final totals = <String, double>{};

    for (final bucket in buckets) {
      final key =
          selectedPeriod == IncomePeriod.week ||
              selectedPeriod == IncomePeriod.month
          ? DateFormat('yyyy-MM-dd').format(bucket)
          : DateFormat('yyyy-MM').format(bucket);
      totals[key] = 0;
    }

    for (final income in incomes) {
      final key =
          selectedPeriod == IncomePeriod.week ||
              selectedPeriod == IncomePeriod.month
          ? DateFormat('yyyy-MM-dd').format(income.date)
          : DateFormat(
              'yyyy-MM',
            ).format(DateTime(income.date.year, income.date.month, 1));
      if (totals.containsKey(key)) {
        totals[key] = totals[key]! + income.amount;
      }
    }

    // Calculate cumulative values
    final values = buckets.map((bucket) {
      final key =
          selectedPeriod == IncomePeriod.week ||
              selectedPeriod == IncomePeriod.month
          ? DateFormat('yyyy-MM-dd').format(bucket)
          : DateFormat('yyyy-MM').format(bucket);
      return totals[key] ?? 0;
    }).toList();

    // Convert to cumulative (running total)
    double cumulative = 0;
    for (int i = 0; i < values.length; i++) {
      cumulative += values[i];
      values[i] = cumulative;
    }

    return values;
  }

  Widget _buildPeriodButton(IncomePeriod period) {
    final isSelected = selectedPeriod == period;
    return ChoiceChip(
      label: Text(period.label),
      selected: isSelected,
      selectedColor: AppPalette.accentPurple,
      backgroundColor: surfaceColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : textColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => onPeriodSelected(period),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = _chartBuckets(now);
    final values = _prepareChartValues(incomes, now);
    final maxRaw = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxRaw <= 0 ? 1 : maxRaw).toDouble();
    final yInterval = maxY / 4;

    final spots = List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pajamų pokytis',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              selectedPeriod.label,
              style: TextStyle(color: AppPalette.secondaryText(context)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 260,
          child: maxRaw == 0
              ? Center(
                  child: Text(
                    'Nėra pajamų šiame laikotarpyje',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPalette.secondaryText(context)),
                  ),
                )
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: spots.isEmpty ? 0 : spots.length - 1,
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      /*getDrawingHorizontalLine: (value) => FlLine(
                  color: borderColor.withOpacity(0.18),
                  strokeWidth: 1,
                ),*/
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: yInterval,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}',
                            style: TextStyle(color: textColor, fontSize: 11),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= buckets.length) {
                              return const SizedBox.shrink();
                            }

                            final bool showLabel;
                            if (selectedPeriod == IncomePeriod.week) {
                              showLabel = true;
                            } else if (selectedPeriod == IncomePeriod.month) {
                              showLabel =
                                  index % 5 == 0 || index == buckets.length - 1;
                            } else {
                              showLabel = true;
                            }
                            if (!showLabel) return const SizedBox.shrink();

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                _bucketLabel(buckets[index]),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => surfaceColor,
                        tooltipRoundedRadius: 12,
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final index = spot.x.toInt();
                            final bucket = buckets[index];
                            return LineTooltipItem(
                              '${_tooltipLabel(bucket)}\n${spot.y.toStringAsFixed(2)} €',
                              TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: borderColor),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 2.5,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppPalette.accentPurple.withOpacity(0.18),
                        ),
                        color: AppPalette.accentPurple,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodButton(IncomePeriod.week),
            _buildPeriodButton(IncomePeriod.month),
            _buildPeriodButton(IncomePeriod.sixMonths),
            _buildPeriodButton(IncomePeriod.year),
          ],
        ),
      ],
    );
  }
}
