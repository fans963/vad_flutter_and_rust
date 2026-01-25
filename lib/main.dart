import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vad/src/rust/frb_generated.dart';
import 'package:vad/src/signals/page_controller_signal.dart';
import 'package:vad/src/ui/chart_widget.dart';
import 'package:vad/src/ui/fps_counter.dart';
import 'package:vad/src/ui/pick_file_button.dart';
import 'package:vad/src/ui/title_bar.dart';
import 'package:vad/src/ui/tool_plate.dart';
import 'package:vad/src/util/util.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  if (isDesktop) {
    await trayManager.setIcon('assets/image/icon.png');
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1500, 1000),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

const Color primarySeedColor = Color(0xFF4B77C2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(ColorScheme colorScheme) {
    return FlexThemeData.light(
      colorScheme: colorScheme,
      useMaterial3: true,
      splashFactory: InkSplash.splashFactory,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.surface,
      subThemesData: const FlexSubThemesData(defaultRadius: 12.0),
      textTheme: _createTextTheme('MapleMonoNFCN'),
    );
  }

  ThemeData _buildDarkTheme(ColorScheme colorScheme) {
    return FlexThemeData.dark(
      colorScheme: colorScheme,
      useMaterial3: true,
      splashFactory: InkSplash.splashFactory,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.surface,
      subThemesData: const FlexSubThemesData(defaultRadius: 12.0),
      darkIsTrueBlack: true,
      textTheme: _createTextTheme('MapleMonoNFCN'),
    );
  }

  TextTheme _createTextTheme(String fontFamily) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily),
      displayMedium: TextStyle(fontFamily: fontFamily),
      displaySmall: TextStyle(fontFamily: fontFamily),
      headlineLarge: TextStyle(fontFamily: fontFamily),
      headlineMedium: TextStyle(fontFamily: fontFamily),
      headlineSmall: TextStyle(fontFamily: fontFamily),
      titleLarge: TextStyle(fontFamily: fontFamily),
      titleMedium: TextStyle(fontFamily: fontFamily),
      titleSmall: TextStyle(fontFamily: fontFamily),
      bodyLarge: TextStyle(fontFamily: fontFamily),
      bodyMedium: TextStyle(fontFamily: fontFamily),
      bodySmall: TextStyle(fontFamily: fontFamily),
      labelLarge: TextStyle(fontFamily: fontFamily),
      labelMedium: TextStyle(fontFamily: fontFamily),
      labelSmall: TextStyle(fontFamily: fontFamily),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightColorScheme;
        final ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: primarySeedColor);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: primarySeedColor,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'vad',
          theme: _buildTheme(lightColorScheme),
          darkTheme: _buildDarkTheme(darkColorScheme),
          themeMode: ThemeMode.system,
          home: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? darkColorScheme.surface
                : lightColorScheme.surface,
            body: Stack(
              children: [
                Column(
                  children: [
                    if (isDesktop) const TitleBar(),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(),
                        child: const ChartWidget(),
                      ),
                    ),
                    const ToolPlate(),
                  ],
                ),
                Positioned(
                  top: isDesktop ? 45 : 10,
                  right: 10,
                  child: const FpsCounter(),
                ),
              ],
            ),
            floatingActionButton: const PickFileButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: Watch((context) {
              return BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
                  BottomNavigationBarItem(icon: Icon(Icons.info), label: '信息'),
                  BottomNavigationBarItem(icon: Icon(Icons.edit), label: '控制'),
                ],
                currentIndex: pageIndexSignal.value,
                onTap: (index) {
                  pageControllerSignal.value.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutQuart,
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}
