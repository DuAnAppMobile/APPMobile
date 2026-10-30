import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/auth_client.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

const avatarChoices = {
  'default_avatar': '🐸',
  'frog_book': '📚',
  'frog_star': '🌟',
  'frog_boss': '👑',
  'frog_leaf': '🌿',
  'frog_fire': '🔥',
};

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.playerId, this.api});
  final int playerId;
  final AccountApi? api;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final api = widget.api ?? AccountApi();
  Map<String, dynamic>? profile;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      error = null;
      busy = true;
    });
    try {
      final value = await api.call('players/${widget.playerId}/profile');
      if (mounted) setState(() => profile = Map<String, dynamic>.from(value));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> avatar() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 18,
            children: avatarChoices.entries
                .map(
                  (e) => IconButton(
                    tooltip: e.key,
                    onPressed: () => Navigator.pop(context, e.key),
                    icon: Text(e.value, style: const TextStyle(fontSize: 32)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() => busy = true);
    try {
      await api.call(
        'players/${widget.playerId}/avatar',
        method: 'PUT',
        body: {'avatarId': value},
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Góc của bạn')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(onPressed: load, child: const Text('Thử lại')),
          ],
          if (profile != null) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
              ),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        avatarChoices[profile!['avatarId']] ?? '🐸',
                        style: const TextStyle(fontSize: 64),
                      ),
                      Text(
                        '${profile!['name']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('${profile!['totalExp']} EXP • Hội ôm sách'),
                      TextButton(
                        onPressed: busy ? null : avatar,
                        child: const Text('Đổi avatar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bộ sưu tập huy hiệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if ((profile!['badges'] as List).isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ếch đang chờ chiến tích đầu tiên của bạn. Vào ải thôi!',
                ),
              ),
            ...(profile!['badges'] as List).map(
              (b) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                  ),
                  title: Text('${b['name']}'),
                  subtitle: Text('${b['description']}'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Lịch sử làm bài'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(playerId: widget.playerId),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Đổi mật khẩu'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PasswordScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Tạo mã khôi phục'),
                  subtitle: const Text('Cất mã trước khi quên mật khẩu'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PasswordScreen(recovery: true),
                    ),
                  ),
                ),
                if (AuthSession.role == 'Admin')
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Quản lý câu hỏi'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.playerId, this.api});
  final int playerId;
  final AccountApi? api;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final api = widget.api ?? AccountApi();
  List<dynamic>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await api.call('players/${widget.playerId}/history');
      if (mounted) {
        setState(() {
          items = result as List;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dấu chân hành trình')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: error != null || items == null || items!.isEmpty
            ? 1
            : items!.length,
        itemBuilder: (context, index) {
          if (error != null) {
            return Column(
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Thử lại')),
              ],
            );
          }
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items!.isEmpty) {
            return const ListTile(
              leading: Icon(Icons.explore),
              title: Text('Chưa có lượt chơi hoàn thành'),
              subtitle: Text(
                'Hoàn thành một ải để ghi lại dấu chân đầu tiên nhé.',
              ),
            );
          }
          final item = items![index];
          final passed = item['status'] == 'Passed';
          final raw = '${item['playedAt']}';
          final date = DateTime.tryParse(
            raw.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(raw)
                ? raw
                : '${raw}Z',
          )?.toLocal();
          final dateText = date == null
              ? ''
              : '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          return Card(
            child: ListTile(
              leading: Icon(
                passed ? Icons.emoji_events : Icons.fitness_center,
                color: passed ? Colors.green : Colors.orange,
              ),
              title: Text(
                '${item['stageName']} • ${passed ? 'Đã qua' : 'Chưa đạt'}',
              ),
              subtitle: Text(
                '${item['correctCount']}/${item['totalQuestions']} câu đúng\n$dateText',
              ),
              isThreeLine: true,
              trailing: Text('+${item['expEarned']} EXP'),
            ),
          );
        },
      ),
    ),
  );
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, this.reset = false, this.recovery = false});
  final bool reset;
  final bool recovery;
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final api = AccountApi();
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      code = TextEditingController();
  bool busy = false;
  String? error, recoveryCode;
  @override
  void dispose() {
    api.dispose();
    for (final c in [name, current, password, confirm, code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.recovery) {
        final data = await api.call(
          'auth/recovery-code',
          method: 'POST',
          body: {'currentPassword': current.text},
        );
        if (mounted) setState(() => recoveryCode = data['code'] as String);
      } else {
        await api.call(
          'auth/${widget.reset ? 'reset-password' : 'change-password'}',
          method: 'POST',
          body: {
            'username': name.text.trim(),
            'code': code.text.trim(),
            'currentPassword': current.text,
            'newPassword': password.text,
          },
        );
        AuthSession.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã đổi mật khẩu. Hãy đăng nhập lại và tạo mã khôi phục mới.',
            ),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.recovery
            ? 'Mã khôi phục'
            : widget.reset
            ? 'Quên mật khẩu'
            : 'Đổi mật khẩu',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '🐸',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 64),
          ),
          if (widget.reset) ...[
            const Text(
              'Dùng mã đã tạo trong Hồ sơ → Tạo mã khôi phục. Nếu chưa từng tạo hoặc đã mất mã, bạn cần liên hệ người quản lý demo; app chưa hỗ trợ email khôi phục.',
            ),
            field(name, 'Tên tài khoản'),
            field(code, 'Mã khôi phục 64 ký tự'),
          ] else
            field(current, 'Mật khẩu hiện tại', secret: true),
          if (!widget.recovery) ...[
            field(
              password,
              'Mật khẩu mới',
              secret: true,
              validate: (v) =>
                  v != null &&
                      v.length >= 10 &&
                      v.length <= 128 &&
                      RegExp(r'[a-zA-Z]').hasMatch(v) &&
                      RegExp(r'\d').hasMatch(v)
                  ? null
                  : 'Cần 10–128 ký tự, có chữ và số.',
            ),
            field(
              confirm,
              'Nhập lại mật khẩu mới',
              secret: true,
              validate: (v) =>
                  v == password.text ? null : 'Hai mật khẩu chưa khớp.',
            ),
          ],
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : submit,
            child: Text(
              busy
                  ? 'Đang xử lý…'
                  : widget.recovery
                  ? 'Tạo mã mới'
                  : 'Lưu mật khẩu',
            ),
          ),
          if (recoveryCode != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cất mã này ở nơi riêng tư. Chỉ hiển thị lần này, dùng được một lần trong 90 ngày. Tạo mã mới sẽ hủy mã cũ; đổi mật khẩu cũng hủy mã.',
                    ),
                    const SizedBox(height: 12),
                    SelectableText(recoveryCode!),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    String? Function(String?)? validate,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: !secret,
      maxLength: secret ? 128 : 64,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validate ??
          (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập thông tin.' : null,
    ),
  );
}
