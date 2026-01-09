import 'package:flutter/material.dart';
import 'package:vad/src/util/util.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        if (!isDesktop) return;
        await windowManager.startDragging();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'VAD // ENGINE',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const Spacer(),
            _TitleBarButton(
              icon: Icons.remove,
              onPressed: () async {
                if (!isDesktop) return;
                await windowManager.minimize();
              },
            ),
            _TitleBarButton(
              icon: Icons.crop_square,
              onPressed: () async {
                if (!isDesktop) return;
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _TitleBarButton(
              icon: Icons.close,
              isClose: true,
              onPressed: () async {
                if (!isDesktop) return;
                await windowManager.close();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isClose ? Colors.redAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
