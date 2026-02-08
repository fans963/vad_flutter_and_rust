import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:show_fps/show_fps.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/rust/frb_generated.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
import 'package:vad/src/signals/page_controller_signal.dart';
import 'package:vad/src/signals/support_audio_format_signal.dart';
import 'package:vad/src/ui/chart_widget.dart';
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

const Color primarySeedColor = Colors.blue;

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
          home: ShowFPS(
            alignment: Alignment.topLeft,
            child: Scaffold(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? darkColorScheme.surface
                  : lightColorScheme.surface,
              body: DropRegion(
                formats: supportAudioFormatSignalForDrag.value,
                onDropOver: (DropOverEvent event) {
                  return DropOperation.copy;
                },
                onPerformDrop: (PerformDropEvent event) async {
                  for (final item in event.session.items) {
                    final reader = item.dataReader;
                    if (reader != null) {
                      final formats = reader.getFormats(
                        supportAudioFormatSignalForDrag.value,
                      );
                      for (final format in formats) {
                        if (format is FileFormat) {
                          reader.getFile(format, (file) async {
                            final fileName = file.fileName;
                            if (fileName != null) {
                              final ext = fileName
                                  .split('.')
                                  .last
                                  .toLowerCase();
                              if (supportAudioFormatSignal.value.contains(
                                ext,
                              )) {
                                debugPrint('读取到文件路径: $fileName');
                                await audioProcessorEngine.addFile(
                                  fileName,
                                  await file.readAll(),
                                  format: ext,
                                );
                                audioProcessorEngine.engine().then((
                                  engine,
                                ) async {
                                  await engine.addChart(
                                    filePath: fileName,
                                    dataType: DataType.spectrum,
                                  );
                                  await engine.addChart(
                                    filePath: fileName,
                                    dataType: DataType.energy,
                                  );
                                  await engine.addChart(
                                    filePath: fileName,
                                    dataType: DataType.zeroCrossingRate,
                                  );
                                });
                              }
                            }
                          });
                        }
                      }
                    }
                  }
                },
                child: Stack(
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
                  ],
                ),
              ),
              floatingActionButton: const PickFileButton(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              bottomNavigationBar: Watch((context) {
                return NavigationBar(
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.home), label: '首页'),
                    NavigationDestination(icon: Icon(Icons.info), label: '信息'),
                    NavigationDestination(icon: Icon(Icons.edit), label: '控制'),
                  ],
                  selectedIndex: pageIndexSignal.value,
                  onDestinationSelected: (index) {
                    pageControllerSignal.value.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutQuart,
                    );
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
