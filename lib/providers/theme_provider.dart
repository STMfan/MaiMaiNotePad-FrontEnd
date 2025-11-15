import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = false;
  MaterialColor _primaryColor = Colors.orange; // 新增：主题色 - 默认橙色

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  MaterialColor get primaryColor => _primaryColor; // 新增：主题色获取器

  // 初始化主题设置
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      // 新增：读取主题色设置 - 默认使用橙色（索引0）
      final primaryColorIndex = prefs.getInt('primaryColorIndex') ?? 0;
      _primaryColor = _getColorFromIndex(primaryColorIndex);
    } catch (e) {
      // 如果读取失败，使用默认主题
      _themeMode = ThemeMode.light;
      _primaryColor = Colors.orange; // 默认橙色主题
    }

    _isLoading = false;
    notifyListeners();
  }

  // 切换主题模式
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    } catch (e) {
      // 如果保存失败，不影响当前切换
      debugPrint('保存主题设置失败: $e');
    }
  }

  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    } catch (e) {
      debugPrint('保存主题设置失败: $e');
    }
  }

  // 新增：设置主题色
  Future<void> setPrimaryColor(MaterialColor color) async {
    if (_primaryColor == color) return;

    _primaryColor = color;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final colorIndex = _getIndexFromColor(color);
      await prefs.setInt('primaryColorIndex', colorIndex);
    } catch (e) {
      debugPrint('保存主题色设置失败: $e');
    }
  }

  // 新增：根据索引获取颜色 - 橙色作为默认（索引0）
  MaterialColor _getColorFromIndex(int index) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }

  // 新增：根据颜色获取索引 - 橙色作为默认（索引0）
  int _getIndexFromColor(MaterialColor color) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors.indexOf(color);
  }
}
