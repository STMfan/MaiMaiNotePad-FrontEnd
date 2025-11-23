import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;
  String? _passwordStrengthMessage;
  Color? _passwordStrengthColor;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  // 验证码倒计时
  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    // 验证邮箱格式
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入邮箱地址')),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('邮箱格式不正确')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.sendVerificationCode(_emailController.text.trim());

    if (success && mounted) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已发送，请查收邮箱')),
      );
    } else if (mounted) {
      final errorMessage = userProvider.errorMessage ?? '发送验证码失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // 邮箱格式验证
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // 密码强度验证（中等强度：至少8位，包含数字、大小写字母、符号中的两种）
  String? _validatePasswordStrength(String password, String username, String email) {
    if (password.length < 8) {
      return '密码长度至少需要8位';
    }

    // 检查是否包含数字、大写字母、小写字母、符号
    bool hasDigit = RegExp(r'[0-9]').hasMatch(password);
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    int typeCount = 0;
    if (hasDigit) typeCount++;
    if (hasUpper) typeCount++;
    if (hasLower) typeCount++;
    if (hasSpecial) typeCount++;

    if (typeCount < 2) {
      return '密码强度不足，需要包含数字、大小写字母、符号中的至少两种';
    }

    // 弱密码检测：检查是否包含用户名或邮箱
    if (username.isNotEmpty && password.toLowerCase().contains(username.toLowerCase())) {
      return '密码不能包含用户名';
    }

    if (email.isNotEmpty) {
      final emailPrefix = email.split('@')[0];
      if (emailPrefix.isNotEmpty && password.toLowerCase().contains(emailPrefix.toLowerCase())) {
        return '密码不能包含邮箱前缀';
      }
    }

    // 常见弱密码检测（强匹配）
    final commonWeakPasswords = [
      'password',
      '12345678',
      '123456789',
      '1234567890',
      'qwerty123',
      'abc123456',
      'password123',
      'admin123456',
      '123456789a',
      'a123456789',
    ];

    for (var weakPassword in commonWeakPasswords) {
      if (password.toLowerCase() == weakPassword.toLowerCase()) {
        return '密码过于简单，请使用更复杂的密码';
      }
    }

    return null; // 密码强度合格
  }

  // 注册
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        verificationCode: _verificationCodeController.text.trim(),
      );

      if (success && mounted) {
        // 注册成功，跳转到登录页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册成功，请登录'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRouter.login);
      } else if (mounted) {
        // 注册失败，保留已输入的信息（除了密码和验证码）
        _passwordController.clear();
        _confirmPasswordController.clear();
        _verificationCodeController.clear();
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
                      if (value.length < 3 || value.length > 20) {
                        return '用户名长度应在3-20个字符之间';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return '用户名只能包含字母、数字和下划线';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 邮箱输入框
                  CustomTextField(
                    controller: _emailController,
                    labelText: '邮箱',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱地址';
                      }
                      if (!_isValidEmail(value)) {
                        return '邮箱格式不正确';
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
                    onChanged: (value) {
                      // 实时验证密码强度
                      setState(() {
                        _passwordStrengthMessage = _validatePasswordStrength(
                          value,
                          _usernameController.text.trim(),
                          _emailController.text.trim(),
                        );
                        if (_passwordStrengthMessage == null) {
                          _passwordStrengthColor = Colors.green;
                          _passwordStrengthMessage = '密码强度合格';
                        } else {
                          _passwordStrengthColor = Colors.orange;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      final strengthError = _validatePasswordStrength(
                        value,
                        _usernameController.text.trim(),
                        _emailController.text.trim(),
                      );
                      return strengthError;
                    },
                  ),
                  // 密码强度提示
                  if (_passwordStrengthMessage != null && _passwordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _passwordStrengthMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _passwordStrengthColor ?? Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 确认密码输入框
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: '确认密码',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 验证码输入框和发送按钮
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _verificationCodeController,
                          labelText: '验证码',
                          prefixIcon: Icons.verified_user,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return '验证码应为6位数字';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          return SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: (_countdown > 0 || userProvider.isLoading)
                                  ? null
                                  : _sendVerificationCode,
                              child: _countdown > 0
                                  ? Text('${_countdown}秒')
                                  : const Text('发送验证码'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 注册按钮
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: userProvider.isLoading ? null : _register,
                          child: userProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('注册'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 已有账号链接
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已有账号？'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRouter.login);
                        },
                        child: const Text('去登录'),
                      ),
                    ],
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









