import 'package:dynamic_color/dynamic_color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vad/src/provider/navigator_index_provider.dart';
import 'package:vad/src/rust/api/audio_processor.dart';
import 'package:vad/src/rust/api/util.dart';
import 'package:vad/src/rust/frb_generated.dart';
import 'package:vad/src/ui/chart_widget.dart';
import 'package:vad/src/ui/pick_file_button.dart';
import 'package:vad/src/ui/title_bar.dart';
import 'package:vad/src/ui/tool_plate.dart';
import 'package:vad/src/util.dart';
import 'package:window_manager/window_manager.dart';

class AudioChartData {
  final ChartData? audioData;
  final ChartData? fftData;
  AudioChartData({this.audioData, this.fftData});
}
 
 
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

  runApp(ProviderScope(child: const MyApp()));
}

const Color primarySeedColor = Color(0xFF4B77C2);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(ColorScheme colorScheme) {
    return FlexThemeData.light(
      colorScheme: colorScheme,
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.surface,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12.0,
        useTextTheme: true,
      ),
    );
  }

  ThemeData _buildDarkTheme(ColorScheme colorScheme) {
    return FlexThemeData.dark(
      colorScheme: colorScheme,
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.surface,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12.0,
        useTextTheme: true,
      ),
      darkIsTrueBlack: true, 
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ? darkColorScheme.background
                : lightColorScheme.background,
            body: Column(
              children: [
                if (isDesktop) const TitleBar(),
                Expanded(child: ListView(children: const [ChartWidget()])),
                const ToolPlate(),
              ],
            ),
            floatingActionButton: const PickFileButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
                BottomNavigationBarItem(icon: Icon(Icons.info), label: '信息'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '控制',
                ),
              ],
              currentIndex: ref.watch(navigatorIndexProvider),
              onTap: (index) {
                ref.read(navigatorIndexProvider.notifier).setIndex(index);
              },
            ),
          ),
        );
      },
    );
  }
}
