import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'navigation/brush_page.dart';
import '../firestore_provider.dart';
import 'navigation/finish_page.dart';
import 'navigation/main_page.dart';
import 'navigation/stage_page.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState<int>(0);
    final infoAsyncValue = ref.watch(infoProvider);

    useEffect(() {
      if (infoAsyncValue is AsyncData) {
        final Mode = infoAsyncValue.value?.mode;

        if (Mode == 1) { print("brush"); index.value = 1;}
        else if (Mode == 2) { print("finish"); index.value = 2;}
        else if (Mode == 3) { print("stagestart"); index.value = 3;}
        else if (Mode == 4) { print("stage1"); index.value = 4;}
        else if (Mode == 5) { print("stage2"); index.value = 5;}
        else if (Mode == 6) { print("stage3"); index.value = 6;}
        else if (Mode == 7) { print("stage4"); index.value = 7;}
        else if (Mode == 8) { print("stage5"); index.value = 8;}
        else if (Mode == 9) { print("stage6"); index.value = 9;}
        else if (Mode == 10) { print("stage7"); index.value = 10;}
        else if (Mode == 11) { print("stage8"); index.value = 11;}
        else if (Mode == 12) { print("stage9"); index.value = 12;}
        else if (Mode == 13) { print("stageend"); index.value = 13;}
        else if (Mode == 99) { print("testpage"); index.value = 99;}
        else {
          print("main");
          index.value = 0;
        }
      }

      // 클린업 함수
      return () => print("Cleaning up HomePage");
    }, [infoAsyncValue]);

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0.0, elevation: 0.0,),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: infoAsyncValue.when(
          data: (infoData) {
            return index.value == 1 ? BrushPage()
                : index.value == 2 ? FinishPage()
                : index.value == 3 ? StageStartPage()
                : index.value == 4 ? StagePage(activeStep: 1, instruction1: "좌측 상단 어금니를 닦으세요.", instruction2: "칫솔을 세워서 안쪽도 닦아주세요.", image1: "assets/stage/0.gif", image2: "assets/stage/0_inside.gif")
                : index.value == 5 ? StagePage(activeStep: 2, instruction1: "윗 앞니를 닦으세요.", instruction2: "칫솔을 세워서 앞니의 뒷면도 닦아주세요.", image1: "assets/stage/1.gif", image2: "assets/stage/1_inside.gif")
                : index.value == 6 ? StagePage(activeStep: 3, instruction1: "우측 상단 어금니를 닦으세요.", instruction2: "칫솔을 세워서 안쪽도 닦아주세요.", image1: "assets/stage/2.gif", image2: "assets/stage/2_inside.gif")
                : index.value == 7 ? StagePage(activeStep: 4, instruction1: "좌측 하단 어금니를 닦으세요.", instruction2: "칫솔을 세워서 안쪽도 닦아주세요.", image1: "assets/stage/3.gif", image2: "assets/stage/3_inside.gif")
                : index.value == 8 ? StagePage(activeStep: 5, instruction1: "아랫 앞니를 닦으세요.", instruction2: "칫솔을 세워서 앞니의 뒷면도 닦아주세요.", image1: "assets/stage/4.gif", image2: "assets/stage/4_inside.gif")
                : index.value == 9 ? StagePage(activeStep: 6, instruction1: "우측 하단 어금니를 닦으세요.", instruction2: "칫솔을 세워서 안쪽도 닦아주세요.", image1: "assets/stage/5.gif", image2: "assets/stage/5_inside.gif")
                : index.value == 10 ? StagePage(activeStep: 7, instruction1: "입을 오므리고 왼쪽 이를 닦아주세요.", instruction2: "원을 그리듯이 이의 측면을 닦아주세요.", image1: "assets/stage/6_up.gif", image2: "assets/stage/6_down.gif")
                : index.value == 11 ? StagePage(activeStep: 8, instruction1: "입을 오므려 앞니가 보이도록 하고 앞니를 닦아주세요.", instruction2: "원을 그리듯이 앞니를 닦아주세요.", image1: "assets/stage/7_up.gif", image2: "assets/stage/7_down.gif")
                : index.value == 12 ? StagePage(activeStep: 9, instruction1: "입을 오므리고 오른쪽 이를 닦아주세요.", instruction2: "원을 그리듯이 이의 측면을 닦아주세요.", image1: "assets/stage/8_up.gif", image2: "assets/stage/8_down.gif")
                : index.value == 13 ? StageEndPage()
                : MainPage();
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}