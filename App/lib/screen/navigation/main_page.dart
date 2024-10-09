import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smartmirror_renewal/screen/graph_page.dart';
import 'package:smartmirror_renewal/screen/portable/connect_page.dart';

import '../../provider/firestore_provider.dart';
import '../../provider/portable_provider.dart';
import '../../theme.dart';
import '../chat_page.dart';

class MainPage extends HookConsumerWidget {
  MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastestCategory = ref.watch(latestCategoryProvider);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Scaffold(
        backgroundColor: BACKGROUND_COLOR,
        appBar: AppBar(
          backgroundColor: BACKGROUND_COLOR,
          title: Text("안녕하세요👋", style: APPBAR_FONT,),
          centerTitle: false,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('외출 모드를 활성화하시겠습니까?', style: TextStyle(fontFamily: 'SpoqaHanSansNeo', fontSize: 16, fontWeight: FontWeight.w600)),
                          content: Text('칫솔과 스마트 미러와의 블루투스 연결이 해제됩니다.', style: TextStyle(fontFamily: 'SpoqaHanSansNeo', fontSize: 16, fontWeight: FontWeight.w400)),
                          actions: <Widget>[
                            TextButton(
                              child: Text('취소'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: Text('확인'),
                              onPressed: () async {
                                await updatePortableStatus(true);
                                Navigator.pop(context);
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (c) => ConnectPage())
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.maxFinite,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: MAIN_COLOR,
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('외출모드로 전환', style: CONTANT_FONT_WHITE_BOLD,),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20,)
                        ],
                      ),
                    )
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.maxFinite,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: SUB_COLOR,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                  ),
                  child: lastestCategory.when(
                    data: (filteredData) {
                      if (filteredData == null || filteredData.isEmpty) {
                        return Center(
                          child: Text("데이터 로딩중...", style: CONTANT_FONT_WHITE_BOLD),
                        );
                      }

                      // 여전히 데이터가 13개인지 확인
                      if (filteredData.length < 13) {
                        return Center(
                          child: Text("데이터 로딩중...", style: CONTANT_FONT_WHITE_BOLD),
                        );
                      }

                      // filteredData로부터 BarChartGroupData 생성
                      List<BarChartGroupData> barGroups = filteredData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: double.parse(data['time'] ?? '0'),
                              color: MAIN_COLOR,
                              width: 5,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            BarChartRodData(
                              toY: double.parse(data['count'] ?? '0'),
                              color: Colors.white,
                              width: 5,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        );
                      }).toList();

                      // 최신 날짜로 DateTime 및 포맷팅
                      String latestDate = filteredData.first['dateField'];
                      DateTime dateTime = DateTime.parse(latestDate);
                      DateFormat dateFormatter = DateFormat('MM/dd HH:mm');
                      String latestDateString = dateFormatter.format(dateTime);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (c) => GraphPage(selectedDate: latestDate),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("최근 진단", style: CONTANT_FONT_WHITE_BOLD),
                                  Text(latestDateString, style: CONTANT_FONT_WHITE_THIN),
                                ],
                              ),
                              Container(
                                width: double.maxFinite,
                                height: 230,
                                child: BarChart(
                                  BarChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: getTitles,
                                          reservedSize: 38,
                                        ),
                                      ),
                                    ),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          return BarTooltipItem(
                                            rod.toY.round().toString(),
                                            TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    barGroups: barGroups,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text("오류 발생: $error")),
                  )
                ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (c) => ChatPage())
                    );
                  },
                  child: Container(
                    width: double.maxFinite,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.grey.shade100,
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xfff3e7e9), Color(0xffe3eeff)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text('챗봇에게 질문하기💬', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'SpoqaHanSansNeo')),
                            ],
                          ),
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Text('#양치 #치아 #이런게 궁금해요', style: TextStyle(color: MAIN_COLOR, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'SpoqaHanSansNeo')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
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