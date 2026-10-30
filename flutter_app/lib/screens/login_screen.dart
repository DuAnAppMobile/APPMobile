import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/primary_button.dart';
import '../widgets/rpg_shell.dart';
import '../widgets/quest_mascot.dart';
import 'home_screen.dart';
import 'account_screen.dart';
import 'university_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.playerService});

  final PlayerService? playerService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _register = false;
  bool _hidePassword = true;
  late final PlayerService _playerService;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playerService = widget.playerService ?? PlayerService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _playerService.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên tài khoản.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,32}$').hasMatch(name)) {
      setState(
        () => _errorMessage = 'Tài khoản cần 3–32 chữ không dấu, số hoặc _.',
      );
      return;
    }
    final password = _passwordController.text;
    if (password.isEmpty ||
        password.length > 128 ||
        (_register &&
            (password.length < 10 ||
                !RegExp(r'[a-zA-Z]').hasMatch(password) ||
                !RegExp(r'[0-9]').hasMatch(password)))) {
      setState(
        () => _errorMessage =
            'Mật khẩu cần 10–128 ký tự, có chữ và số khi đăng ký.',
      );
      return;
    }
    if (_register && password != _confirmController.text) {
      setState(() => _errorMessage = 'Hai mật khẩu chưa khớp nhau.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Player player = await _playerService.authenticate(
        name,
        password,
        register: _register,
      );
      if (!mounted) return;
      final targetUniversityId = player.targetUniversityId;
      final targetUniversity = player.targetUniversity;
      if (targetUniversityId != null &&
          targetUniversity?.id != targetUniversityId) {
        throw const FormatException(
          'Không thể tải trường mục tiêu của người chơi.',
        );
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => targetUniversityId == null
              ? UniversitySelectionScreen(player: player)
              : HomeScreen(player: player, university: targetUniversity!),
        ),
      );
    } on PlayerServiceException catch (error) {
      if (mounted && error.isConnectionError) {
        await showNetworkErrorDialog(context, error.message);
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const QuestMascot(height: 160, compact: true),
                const SizedBox(height: 28),
                Text(
                  _register
                      ? 'Gia nhập hội ôm sách'
                      : 'Alime chờ bạn đăng nhập',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Khai tên cho Ếch Alime nào. Cùng hội ôm sách từ đây.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                const Align(
                  child: RpgBadge(
                    icon: Icons.bolt_rounded,
                    label: 'Hành trình của riêng bạn',
                    color: AppColors.exp,
                  ),
                ),
                const SizedBox(height: 30),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _register ? 'Tạo tài khoản mới' : 'Đăng nhập',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Đăng nhập cùng tài khoản để lấy lại tiến độ từ máy chủ. Không chia sẻ mật khẩu nhé.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Tên tài khoản',
                          hintText: 'Ví dụ: minh_alime',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: _register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_register) _login();
                        },
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const PasswordScreen(reset: true),
                                    ),
                                  ),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ),
                      if (_register) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmController,
                          enabled: !_isLoading,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          onSubmitted: (_) => _login(),
                          decoration: const InputDecoration(
                            labelText: 'Nhập lại mật khẩu',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mật khẩu 10–128 ký tự, có chữ và số. Chưa có chức năng khôi phục mật khẩu.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: _register ? 'Đăng ký và bắt đầu' : 'Đăng nhập',
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _errorMessage = null;
                                _passwordController.clear();
                                _confirmController.clear();
                              }),
                        child: Text(
                          _register
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
