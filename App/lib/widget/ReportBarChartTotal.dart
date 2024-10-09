import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smartmirror_renewal/theme.dart';

import '../provider/firestore_provider.dart';

class ReportBarChartTotal extends HookConsumerWidget {
  final String selectedDate;
  final String option;

  ReportBarChartTotal({
    required this.selectedDate,
    required this.option,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(allCategoriesProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      width: double.maxFinite,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],

      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex:6, child: Center(child: Text('윗니'))),
              Expanded(flex:3, child: Center(child: Text('앞니'))),
              Expanded(flex:4, child: Center(child: Text('뒷니'))),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: allCategories.when(
              data: (categoriesJson) {
                // 선택 데이터로 필터링
                List<Map<String, dynamic>> filteredData = categoriesJson.where((data) {
                  return data['id'] == selectedDate;
                }).toList();

                List<BarChartGroupData> barGroups = filteredData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: option == 'time' ? double.parse(data['time'] ?? '0') : double.parse(data['count'] ?? '0'),
                        color: index >= 9
                            ? TOOTH_SUB_COLOR
                            : index >= 6
                                ? SUB_COLOR
                                : MAIN_COLOR,
                        width: 7,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  );
                }).toList();

                return BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: FlGridData(
                      show: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: getTitles,
                          reservedSize: 38,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => Center(
                child: LoadingAnimationWidget.staggeredDotsWave(color: MAIN_COLOR, size: 40),
              ),
              error: (error, stackTrace) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w500,
      fontFamily: 'SpoqaHanSansNeo',
      fontSize: 8,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('좌측\n상단', style: style);
        break;
      case 1:
        text = const Text('중앙\n상단', style: style);
        break;
      case 2:
        text = const Text('우측\n상단', style: style);
        break;
      case 3:
        text = const Text('좌측\n하단', style: style);
        break;
      case 4:
        text = const Text('중앙\n하단', style: style);
        break;
      case 5:
        text = const Text('우측\n하단', style: style);
        break;
      case 6:
        text = const Text('좌측', style: style);
        break;
      case 7:
        text = const Text('중앙', style: style);
        break;
      case 8:
        text = const Text('우측', style: style);
        break;
      case 9:
        text = const Text('좌측\n상단', style: style);
        break;
      case 10:
        text = const Text('우측\n상단', style: style);
        break;
      case 11:
        text = const Text('좌측\n하단', style: style);
        break;
      case 12:
        text = const Text('우측\n하단', style: style);
        break;

      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }
}
