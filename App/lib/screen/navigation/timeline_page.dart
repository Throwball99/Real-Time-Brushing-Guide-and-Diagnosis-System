import 'dart:math';

import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:smartmirror_renewal/screen/graph_page.dart';
import 'package:smartmirror_renewal/theme.dart';
import 'dart:math' as math;

import '../../provider/firestore_provider.dart';

class TimeLinePage extends HookConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(allCategoriesProvider);
    var settingDate = useState(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Scaffold(
        backgroundColor: BACKGROUND_COLOR,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: BACKGROUND_COLOR,
          title: Text("타임라인🗓️", style: APPBAR_FONT),
          centerTitle: false,
          elevation: 0,
        ),
        body: Column(
          children: [
            EasyDateTimeLine(
              locale: "ko",
              initialDate: DateTime.now(),
              onDateChange: (selectedDate) {
                settingDate.value = DateFormat('yyyy-MM-dd').format(selectedDate);
              },
              headerProps: const EasyHeaderProps(
                showHeader: true,
                monthPickerType: MonthPickerType.switcher,
                dateFormatter: DateFormatter.fullDateMDY(),
              ),
              dayProps: const EasyDayProps(
                height: 70,
                dayStructure: DayStructure.dayStrDayNum,
                activeDayStyle: DayStyle(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: MAIN_COLOR,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: allCategories.when(
                data: (categoriesJson) {
                  // 중복된 ID 제거
                  Set<String> uniqueIds = categoriesJson.map((data) => data['id'] as String).toSet();

                  // 지정한 날짜로 데이터 필터링
                  List<String> filteredIds = uniqueIds
                      .where((id) => id.startsWith(settingDate.value))
                      .toList();

                  return filteredIds.isEmpty ? Column(
                    children: [
                      Lottie.asset('assets/images/empty.json'),
                      Text('데이터가 없습니다.', style: CONTANT_FONT_BLACK_BOLD),
                    ],
                  ) :
                  ListView.builder(
                    itemCount: filteredIds.length,
                    itemBuilder: (context, index) {
                      DateTime dateTime = DateTime.parse(filteredIds[index]);
                      DateFormat dateFormatter = DateFormat('HH시 mm분');
                      String latestDateString = dateFormatter.format(dateTime);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (c) => GraphPage(selectedDate: filteredIds[index],))
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            width: double.maxFinite,
                            height: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(latestDateString, style: CONTANT_FONT_BLACK_BOLD,),
                                Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20,)
                              ],
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.93, 0.07],
                                colors: [Colors.white, MAIN_COLOR],
                              ),
                            )
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        )
      ),
    );
  }
}