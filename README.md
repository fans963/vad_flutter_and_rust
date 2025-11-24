# vad

A new Flutter project.

## Linux 编译 tray_manager 报错解决方案

如果在 Linux 下编译 Flutter 项目并使用 tray_manager 插件时遇到如下错误：

```
error: 'app_indicator_new' is deprecated [-Werror,-Wdeprecated-declarations]
```

请在 `linux/flutter/ephemeral/.plugin_symlinks/tray_manager/linux/CMakeLists.txt` 添加如下编译参数：

```
target_compile_options(${PLUGIN_NAME} PRIVATE -Wno-error=deprecated-declarations)
```

这样可关闭废弃 API 报错，正常编译运行。
