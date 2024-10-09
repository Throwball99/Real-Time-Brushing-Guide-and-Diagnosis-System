import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../provider/firestore_provider.dart';
import '../theme.dart';
import '../widget/ReportBarChartTotal.dart';
import '../widget/ToothShape.dart';

class GraphPage extends HookConsumerWidget {
  GraphPage({required this.selectedDate});
  final String selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(allCategoriesProvider);
    final isCount = useState<bool>(false); // 치아 선택 시간/횟수 선택

    DateTime dateTime = DateTime.parse(selectedDate);
    DateFormat dateFormatter = DateFormat('MM/dd HH시 mm분');
    String latestDateString = dateFormatter.format(dateTime);

    final selectedText = useState<String>("양치 리포트");
    final isClicked = useState<bool>(false);

    // 애니메이션 컨트롤러 설정
    final animationController = useAnimationController(
      duration: Duration(seconds: 1),
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    // 클릭에 감지 트리거
    useEffect(() {
      animationController.reverse(from: 1.0);
      return null;
    }, [isClicked.value]);

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        title: Text(latestDateString, style: APPBAR_FONT),
        backgroundColor: Colors.white.withAlpha(100),
        elevation: 0.0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: kToolbarHeight + 50),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('치아 선택🦷', style: APPBAR_FONT),
                    CupertinoSwitch(
                      value: isCount.value,
                      trackColor: MAIN_COLOR,
                      activeColor: TOOTH_COUNT_COLOR5,
                      onChanged: (value) {
                        isCount.value = value;
                        if(isCount.value) {
                          selectedText.value = '불량 양치 지도';
                          isClicked.value = !isClicked.value;
                        } else {
                          selectedText.value = '양치 분포도';
                          isClicked.value = !isClicked.value;
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: SUB_COLOR.withOpacity(0.4),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: SUB_COLOR.withOpacity(0.4),
                      offset: Offset(0, -4),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: allCategories.when(
                  data: (categoriesJson) {

                    List<Map<String, dynamic>> filteredData = categoriesJson.where((data) {
                      return data['id'] == selectedDate;
                    }).toList();

                    if (filteredData.isEmpty) {
                      return Center(child: Text('No data for selected date'));
                    }

                    List<int> originalTimeList = filteredData.map((data) {
                      double time = double.parse(data['time']);
                      return time.toInt();
                    }).toList();

                    List<int> originalCountList = filteredData.map((data) {
                      double count = double.parse(data['count']);
                      return count.toInt();
                    }).toList();

                    return Column(
                      children: [
                        Container(
                          width: 350,
                          height: 120,
                          color: Colors.transparent,
                          child: TopToothShape(
                            timeList: originalTimeList, // 치아별 시간 데이터 1-5단계
                            countList: originalCountList, // 치아별 횟수 데이터 1-5단계
                            isCount: isCount.value,
                          ),
                        ),
                        FadeTransition(
                          opacity: animation,
                          child: Text(
                            selectedText.value,
                            style: TextStyle(fontSize: 30, color: SUB_COLOR, fontFamily: 'SpoqaHanSansNeo', fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          width: 350,
                          height: 120,
                          color: Colors.transparent,
                          child: DownToothShape(
                            timeList: originalTimeList,
                            countList: originalCountList,
                            isCount: isCount.value,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(color: MAIN_COLOR, size: 40),
                  ),
                  error: (error, stackTrace) => Center(child: Text('Error: $error')),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('리포트📝', style: APPBAR_FONT),
                    Text('#전체' ,style: TextStyle(color: MAIN_COLOR, fontFamily:'SpoqaHanSansNeo',fontSize: 16, fontWeight: FontWeight.w500))
                  ],
                ),
              ),
              ReportBarChartTotal(
                selectedDate: selectedDate,
                option: 'time',
              ),
              SizedBox(height: 20),
              ReportBarChartTotal(
                selectedDate: selectedDate,
                option: 'count',
              ),
            ],
          ),
        ),
      ),
    );
  }
}