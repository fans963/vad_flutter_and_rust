import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vad/src/provider/navigator_index_provider.dart';
import 'package:vad/src/rust/api/util.dart';
import 'package:vad/src/rust/frb_generated.dart';
import 'package:vad/src/ui/chart_widget.dart';
import 'package:vad/src/ui/pick_file_button.dart';
import 'package:vad/src/ui/title_bar.dart';
import 'package:vad/src/ui/tool_plate.dart';
import 'package:vad/src/util/util.dart';
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
      splashFactory: InkSplash.splashFactory,
      surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.surface,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12.0,
      ),
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
      subThemesData: const FlexSubThemesData(
        defaultRadius: 12.0,
      ),
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
          themeMode: ThemeMode.system, // Default to dark for OLED aesthetic
          home: Scaffold(
            body: Column(
              children: [
                if (isDesktop) const TitleBar(),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: const ChartWidget(),
                  ),
                ),
                const ToolPlate(),
              ],
            ),
            floatingActionButton: const PickFileButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                elevation: 0,
                unselectedItemColor: Colors.white.withValues(alpha: 0.5),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics),
                    label: 'ANALYZE',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info_outline),
                    activeIcon: Icon(Icons.info),
                    label: 'METRICS',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.tune_outlined),
                    activeIcon: Icon(Icons.tune),
                    label: 'CONFIG',
                  ),
                ],
                currentIndex: ref.watch(navigatorIndexProvider),
                onTap: (index) {
                  ref.read(navigatorIndexProvider.notifier).setIndex(index);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
