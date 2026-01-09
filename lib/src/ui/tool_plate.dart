import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vad/src/provider/navigator_index_provider.dart';
import 'package:vad/src/util/drag_handler.dart';

class ToolPlate extends ConsumerWidget {
  const ToolPlate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWidgetIndex = ref.watch(navigatorIndexProvider);
    final currentHeight = ref.watch(toolPlateHeightProvider);

    final widgets = [
      const HomePanel(),
      const InfoPanel(),
      const ControlPanel(),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      height: currentHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          GenericDragHandle(
            onDragUpdate: (double newHeight) {
              final screenHeight = MediaQuery.of(context).size.height;
              ref
                  .read(toolPlateHeightProvider.notifier)
                  .updateHeight(newHeight.clamp(30.0, screenHeight * 0.8));
            },
            onDragStart: () {
              return ref.read(toolPlateHeightProvider);
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: widgets[activeWidgetIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePanel extends ConsumerWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Avatar(image: 'assets/image/fan_avatar.png', label: 'fans963'),
              const SizedBox(width: 48),
              _Avatar(image: 'assets/image/liu_avatar.jpg', label: '🐂津哥'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'CORE DEVELOPERS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  'ENGINEERED BY FANS & LIU',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _LinkButton(
            label: 'SOURCE REPOSITORY',
            url: 'https://github.com/fans963/vad_flutter_and_rust',
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String image;
  final String label;

  const _Avatar({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundImage: AssetImage(image),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;

  const _LinkButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          await launchUrl(uri);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.code, size: 16, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoPanel extends ConsumerWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              'SIGNAL METRICS',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'REAL-TIME ANALYSIS ACTIVE',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'ENGINE CONFIG',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ADJUST PARAMETERS BELOW',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
