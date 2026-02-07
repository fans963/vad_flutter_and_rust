import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vad/src/signals/page_controller_signal.dart';
import 'package:vad/src/util/drag_handler.dart';

class ToolPlate extends StatelessWidget {
  const ToolPlate({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = [
      const HomePanel(),
      const InfoPanel(),
      const ControlPanel(),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: toolPlateHeightSignal.value,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            GenericDragHandle(
              onDragUpdate: (double newHeight) {
                final screenHeight = MediaQuery.of(context).size.height;
                toolPlateHeightSignal.value = newHeight.clamp(
                  50.0,
                  screenHeight * 0.6,
                );
              },
              onDragStart: () {
                return toolPlateHeightSignal.value;
              },
            ),
            Expanded(
              child: PageView(
                controller: pageControllerSignal.value,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => pageIndexSignal.value = index,
                children: widgets,
              ),
            ),
          ],
        ),
        ),
      );
     
    });
  }
}

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/fan_avatar.png',
                  ),
                ),
                SizedBox(width: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage(
                    'assets/image/liu_avatar.jpg',
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            AutoSizeText(
              'Developer: fans963 & 🐂津哥',
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              minFontSize: 14,
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      'Project Repository: ',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      minFontSize: 12,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://github.com/fans963/vad_flutter_and_rust',
                        );
                        await launchUrl(url);
                      },
                      child: AutoSizeText(
                        'https://github.com/fans963/vad_flutter_and_rust',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                        maxLines: 1,
                        minFontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('信息', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('控制', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
