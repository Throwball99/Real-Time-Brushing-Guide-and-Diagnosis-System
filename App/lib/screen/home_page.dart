import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:smartmirror_renewal/theme.dart';

import 'navigation/main_page.dart';
import 'navigation/setting_page.dart';
import 'navigation/timeline_page.dart';
import 'navigation/toothCheck_page.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _selectedIndex = useState(0);

    useEffect(() {   //initial Funtion, 페이지가 처음 생성될 때 호출됨
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp
      ]);
      if (_selectedIndex.value == 0) {
        print("HomePage is selected");
      } else if (_selectedIndex.value == 1) {
        print("TimeLinePage is selected");
      } else if (_selectedIndex.value == 2) {
        print("ToothCheckPage is selected");
      } else if (_selectedIndex.value == 3) {
        print("SettingPage is selected");
      } else {
        print("Unknown page is selected");
      }
      // clean up function, 페이지가 dispose될 때 호출됨
      return () => print("Cleaning up MyPage");
    }, [_selectedIndex.value]);

    final _pageOptions = [
      MainPage(),
      TimeLinePage(),
      ToothCheckPage(),
      SettingPage(),
    ];

    void _onItemTapped(int index) {
      _selectedIndex.value = index;
    }

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      extendBody: true,
      body: Center(
        child: _pageOptions.elementAt(_selectedIndex.value),
      ),
      bottomNavigationBar: CrystalNavigationBar(
        currentIndex: _selectedIndex.value,
        marginR: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        height: 10,
        selectedItemColor: MAIN_COLOR,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white.withOpacity(0.3),
        onTap: _onItemTapped,
        items: [
          CrystalNavigationBarItem(
            icon: Bootstrap.house,
            unselectedIcon: Bootstrap.house,
            selectedColor: MAIN_COLOR,
          ),
          CrystalNavigationBarItem(
            icon: Bootstrap.calendar2,
            unselectedIcon: Bootstrap.calendar2,
            selectedColor: MAIN_COLOR,
          ),
          CrystalNavigationBarItem(
            icon: Bootstrap.clipboard_check,
            unselectedIcon: Bootstrap.clipboard_check,
            selectedColor: MAIN_COLOR,
          ),
          CrystalNavigationBarItem(
            icon: Bootstrap.gear,
            unselectedIcon: Bootstrap.gear,
            selectedColor: MAIN_COLOR,
          ),
        ],
      ),
    );
  }
}