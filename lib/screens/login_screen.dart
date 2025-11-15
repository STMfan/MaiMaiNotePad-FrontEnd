import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // 登录成功，导航到主页
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (!success && mounted) {
        // 获取详细的错误信息
        final errorMessage = userProvider.errorMessage ?? '登录失败';

        // 提取错误码用于显示
        String displayError = errorMessage;
        if (errorMessage.contains('错误码:')) {
          final parts = errorMessage.split(' - ');
          if (parts.isNotEmpty) {
            displayError = parts[0]; // 只显示错误码部分
          }
        }

        // 显示详细的错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '登录失败',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(displayError),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '详情',
              textColor: Colors.white,
              onPressed: () {
                // 显示完整的错误信息对话框
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('登录错误详情'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 解析错误码和错误信息
                            Builder(
                              builder: (context) {
                                final errorText = errorMessage;
                                String errorCode = '';
                                String errorDesc = errorText;
                                String errorType = '系统错误';

                                // 提取错误码 (格式: "错误码: XXX - 描述")
                                if (errorText.contains('错误码:')) {
                                  final parts = errorText.split('错误码: ');
                                  if (parts.length > 1) {
                                    final codeAndDesc = parts[1].split(' - ');
                                    if (codeAndDesc.isNotEmpty) {
                                      errorCode = codeAndDesc[0];
                                      if (codeAndDesc.length > 1) {
                                        errorDesc = codeAndDesc[1];
                                      }
                                    }
                                  }
                                }

                                // 识别特殊错误类型
                                if (errorText.contains('NoSuchMethodError')) {
                                  errorType = '数据格式错误';
                                  errorDesc = '服务器返回的数据格式不正确，请联系管理员';
                                } else if (errorText.contains(
                                  'Dynamic call failed',
                                )) {
                                  errorType = 'API响应错误';
                                  errorDesc = '服务器API响应异常，可能是用户数据不完整';
                                } else if (errorText.contains('null')) {
                                  errorType = '空值错误';
                                  errorDesc = '服务器返回了空值数据，请检查用户状态';
                                } else if (errorText.contains('401')) {
                                  errorType = '认证失败';
                                  errorDesc = '用户名或密码错误';
                                } else if (errorText.contains('403')) {
                                  errorType = '权限错误';
                                  errorDesc = '您没有访问权限';
                                } else if (errorText.contains('500')) {
                                  errorType = '服务器错误';
                                  errorDesc = '服务器内部错误，请稍后再试';
                                } else if (errorText.contains('网络')) {
                                  errorType = '网络错误';
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      '错误类型: $errorType',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (errorCode.isNotEmpty) ...[
                                      SelectableText(
                                        '错误码: $errorCode',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    SelectableText('错误描述: $errorDesc'),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '用户名: ${_usernameController.text.trim()}',
                            ),
                            const SizedBox(height: 8),
                            SelectableText('时间: ${DateTime.now().toString()}'),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                // 根据错误类型提供具体的解决方案
                                List<String> solutions = ['• 检查用户名和密码是否正确'];

                                if (errorMessage.contains(
                                      'NoSuchMethodError',
                                    ) ||
                                    errorMessage.contains(
                                      'Dynamic call failed',
                                    )) {
                                  solutions = [
                                    '• 联系管理员检查服务器API响应格式',
                                    '• 确认用户数据完整性',
                                    '• 检查数据库连接状态',
                                    '• 等待服务器修复后重试',
                                  ];
                                } else if (errorMessage.contains('401')) {
                                  solutions = [
                                    '• 确认用户名和密码是否正确',
                                    '• 检查是否区分大小写',
                                    '• 确认账户是否已激活',
                                    '• 尝试重置密码',
                                  ];
                                } else if (errorMessage.contains('403')) {
                                  solutions = [
                                    '• 确认账户权限状态',
                                    '• 联系管理员获取访问权限',
                                    '• 检查账户是否被禁用',
                                  ];
                                } else if (errorMessage.contains('500')) {
                                  solutions = [
                                    '• 等待几分钟后重试',
                                    '• 检查服务器状态页面',
                                    '• 联系管理员报告此问题',
                                  ];
                                } else if (errorMessage.contains('网络')) {
                                  solutions = [
                                    '• 检查网络连接状态',
                                    '• 尝试切换网络环境',
                                    '• 确认服务器地址是否正确',
                                    '• 检查防火墙设置',
                                  ];
                                } else {
                                  solutions.addAll([
                                    '• 检查网络连接',
                                    '• 确认服务器是否正常运行',
                                    '• 联系管理员获取帮助',
                                  ]);
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SelectableText(
                                      '可能的解决方案:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ...solutions.map(
                                      (solution) => SelectableText(solution),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('关闭'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo/logo.png', height: 120),
                  const SizedBox(height: 16),

                  // 应用名称
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 应用副标题
                  Text(
                    'MaiBot非官方内容分享站',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 用户名输入框
                  CustomTextField(
                    controller: _usernameController,
                    labelText: '用户名',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  CustomTextField(
                    controller: _passwordController,
                    labelText: '密码',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 记住我选项
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('记住我'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: userProvider.isLoading ? null : _login,
                          child: userProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('登录'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 关于按钮
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/about');
                    },
                    child: const Text('关于麦麦笔记本'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
