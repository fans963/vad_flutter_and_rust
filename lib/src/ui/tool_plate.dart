import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vad/src/provider/navigator_index_provider.dart';

class ToolPlate extends ConsumerWidget {
  const ToolPlate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWidgetIndex = ref.watch(navigatorIndexProvider);
    final widgets = [const HomePanel(),const InfoPanel(), const ControlPanel()];
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 300,
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
        child: widgets[activeWidgetIndex],
      ),
    );
  }
}

class HomePanel extends ConsumerWidget {
  const HomePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        Column(
          children: [
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/image/fan_avatar.png'),
                ),
                SizedBox(width: 16),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/image/liu_avatar.jpg'),
                ),
              ],
            ),
            SizedBox(height: 20),
            AutoSizeText(
              'Developer: fans963 & 🐂津哥',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      'Project Repository: ',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://github.com/fans963/vad_flutter_and_rust',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: AutoSizeText(
                        'https://github.com/fans963/vad_flutter_and_rust',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                        maxLines: 1,
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

class InfoPanel extends ConsumerWidget {
  const InfoPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text('信息', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text('控制', style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
