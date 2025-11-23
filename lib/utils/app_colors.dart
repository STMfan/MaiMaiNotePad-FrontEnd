import 'package:flutter/material.dart';

/// 应用程序颜色工具类
/// 提供统一的颜色访问方法，减少代码重复
class AppColors {
  AppColors._();

  /// 获取文本主色调
  /// 用于主要文本内容
  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// 获取极透明文本颜色
  /// alpha: 0.1 - 用于背景色
  static Color onSurfaceWithOpacity01(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
  }

  /// 获取半透明文本颜色
  /// alpha: 0.5 - 用于次要文本
  static Color onSurfaceWithOpacity05(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
  }

  /// 获取较透明文本颜色
  /// alpha: 0.7 - 用于描述文本
  static Color onSurfaceWithOpacity07(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
  }

  /// 获取禁用状态颜色
  /// 用于禁用状态文本和图标
  static Color disabled(BuildContext context) {
    return Theme.of(context).disabledColor;
  }

  /// 获取主色调
  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取成功色
  static Color success(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// 获取错误色
  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// 获取警告色
  static Color warning(BuildContext context) {
    return Colors.orange;
  }
}

/// 便捷的静态方法，便于直接访问常用颜色
class ColorsUtil {
  ColorsUtil._();

  /// 获取常用颜色 - 简化为直接调用
  static Color surface(BuildContext context) => 
      Theme.of(context).colorScheme.surface;
      
  static Color surfaceVariant(BuildContext context) => 
      Theme.of(context).colorScheme.surfaceContainerHighest;
      
  static Color outline(BuildContext context) => 
      Theme.of(context).colorScheme.outline;
}