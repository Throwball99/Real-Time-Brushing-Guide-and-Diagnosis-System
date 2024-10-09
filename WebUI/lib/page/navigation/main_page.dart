import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smartmirror_web_ui/firestore_provider.dart';
import 'package:weather_pack/weather_pack.dart';

import '../../theme.dart';
import '../../widget/ClockWidget.dart';
import '../../widget/ToothShape.dart';
import '../../widget/WaveWidget.dart';

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = useState<WeatherCurrent?>(null);

    final timeLineValue = ref.watch(timeLineProvider);

    useEffect(() {
      Future<void> weather() async {
        const api = 'YOUR_API_KEY';
        final wService = WeatherService(api, language: WeatherLanguage.korean);
        final WeatherCurrent currently = await wService.currentWeatherByLocation(
            latitude: 37.38, longitude: 126.80);
        weatherState.value = currently;
      }
      weather();

      return;
    }, []);

    Widget getWeatherIcon(String weatherIcon) {
      return Image.asset(
        ImagePathWeather.getPathWeatherIcon(weatherIcon),
        filterQuality: FilterQuality.high,
        package: ImagePathWeather.packageName,
      );
    }

    double kelvinToCelsius(double kelvin) {
      return kelvin - 273.15;
    }

    return timeLineValue.when(
      data: (dates) {
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                  width: double.maxFinite,
                                  height: 200,
                                  child: Center(child: ClockWidget()),
                              ),
                            ),
                            weatherState.value == null
                                ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40))
                                : SizedBox(
                              width: 200,
                              height: 200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  weatherState.value?.weatherIcon == null
                                      ? LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40)
                                      : getWeatherIcon(weatherState.value?.weatherIcon ?? ''),
                                  Text('${kelvinToCelsius(weatherState.value?.temp ?? 273).toStringAsFixed(1)}°C',
                                      style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                                  Text('${weatherState.value?.humidity}%', style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'NEXON Lv2 Gothic')),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedWave(
                        height: 180,
                        speed: 1.0,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedWave(
                        height: 120,
                        speed: 0.9,
                        offset: pi,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedWave(
                        height: 220,
                        speed: 1.2,
                        offset: pi / 2,
                      ),
                    ),
                  ),
                ],
              )
            ),
          ],
        );
      },
      loading: () => Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40)),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}