import 'package:flutter/foundation.dart';

bool get isDesktop {
  if (kIsWeb) {
    // 编译到 Web 时，它永远不是 Native Desktop
    return false;
  }
  
  // 仅在 Native 环境下才检查目标平台
  switch (defaultTargetPlatform) {
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return false;
  }
}