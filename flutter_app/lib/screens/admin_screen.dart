import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/auth_client.dart';
import '../services/player_service.dart';
import 'login_screen.dart';
import 'account_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.api});
  final AccountApi? api;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final api = widget.api ?? AccountApi();
  int tab = 0;
  int stageFilter = 0;
  String search = '';
  bool loading = false;
  bool showArchived = false;
  List<dynamic>? questions;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (AuthSession.role == 'Admin') load();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.call('admin/questions');
      if (mounted) {
        setState(() {
          questions = data as List;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    if (busy) return;
    setState(() => busy = true);
    final service = PlayerService();
    try {
      await service.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Chưa thể đăng xuất: $e')));
      }
    } finally {
      service.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Widget metric(String label, String value, IconData icon) => Container(
    width: 150,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E6EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4D61A8)),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        Text(label),
      ],
    ),
  );

  Future<void> edit([Map<String, dynamic>? question]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuestionEditor(question: question)),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> remove(Map<String, dynamic> question) async {
    try {
      final impact = await api.call('admin/questions/${question['id']}/impact');
      if (!mounted) return;
      if ((impact['attempts'] as int) > 0) {
        await resolve(question, impact);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: Text(
          '${question['content']}\n\nCâu đã được dùng trong lượt chơi sẽ không thể xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await api.call('admin/questions/${question['id']}', method: 'DELETE');
      if (mounted) await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resolve(Map<String, dynamic> question, dynamic impact) async {
    String mode = 'retire';
    String answer =
        question['correctionOption'] as String? ??
        question['correctOption'] as String;
    String reasonText = '';
    final form = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Xử lý câu hỏi đã sử dụng'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${impact['attempts']} lượt liên quan • ${impact['completed']} lượt đã hoàn thành.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chỉ bù quyền lợi: không trừ EXP, không khóa lại ải hay thu hồi huy hiệu.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'retire',
                          child: Text('Ngừng dùng, giữ lịch sử'),
                        ),
                        DropdownMenuItem(
                          value: 'correct',
                          child: Text('Sửa đáp án, chấm bù'),
                        ),
                        DropdownMenuItem(
                          value: 'void',
                          child: Text('Hủy câu lỗi, tính đúng'),
                        ),
                      ],
                      onChanged: (v) => update(() => mode = v!),
                    ),
                    if (mode == 'correct')
                      DropdownButtonFormField<String>(
                        initialValue: answer,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án đúng mới',
                        ),
                        items: ['A', 'B', 'C', 'D']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => answer = v!,
                      ),
                    if (mode == 'correct')
                      const Text(
                        'Tạo bản thay thế cho lượt mới. Lượt cũ chỉ được tăng quyền lợi.',
                      ),
                    if (mode == 'void')
                      const Text(
                        'Tính câu lỗi là đúng, hoàn phí gợi ý. Lịch sử đánh dấu câu đã hủy.',
                      ),
                    if (mode != 'correct' &&
                        (impact['activeQuestions'] as int) <=
                            (impact['requiredQuestions'] as int))
                      const Text(
                        'Kho đang vừa đủ hoặc thiếu câu. Hãy thêm câu thay thế để có thể bắt đầu lượt mới.',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    TextFormField(
                      onChanged: (value) => reasonText = value.trim(),
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Lý do xử lý',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 3
                          ? 'Nhập ít nhất 3 ký tự.'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Xác nhận xử lý'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final result = await api.call(
        'admin/questions/${question['id']}/resolve',
        method: 'POST',
        body: {
          'mode': mode,
          'reason': reasonText,
          if (mode == 'correct') 'correctOption': answer,
        },
      );
      if (mounted) {
        await load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xử lý ${result['attempts']} lượt, cộng bù ${result['exp']} EXP.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthSession.role != 'Admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản trị')),
        body: const Center(child: Text('Chỉ quản trị viên được truy cập.')),
      );
    }
    final all = questions ?? [];
    final filtered = all
        .where(
          (q) =>
              (stageFilter == 0 || q['stageId'] == stageFilter) &&
              (showArchived || q['isArchived'] != true) &&
              '${q['content']}'.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF202D4A),
        foregroundColor: Colors.white,
        title: const Text(
          'English Quest • Quản trị',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Câu hỏi',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Tài khoản',
          ),
        ],
      ),
      floatingActionButton: tab != 1
          ? null
          : FloatingActionButton.extended(
              onPressed: busy ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm câu'),
            ),
      body: Column(
        children: [
          if (busy || loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
          Expanded(
            child: tab == 2
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                        color: Color(0xFF202D4A),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tài khoản quản trị',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Quản lý nội dung học tập và bảo mật tài khoản.',
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: const Text('Đổi mật khẩu'),
                              trailing: const Icon(Icons.chevron_right),
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
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const PasswordScreen(recovery: true),
                                ),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Đăng xuất'),
                              onTap: busy ? null : logout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : error != null && questions == null
                ? Center(
                    child: TextButton(
                      onPressed: load,
                      child: const Text('Thử tải lại'),
                    ),
                  )
                : questions == null
                ? const Center(child: CircularProgressIndicator())
                : tab == 0
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'Trung tâm quản lý',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202D4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Theo dõi kho nội dung và cập nhật câu hỏi cho người học.',
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          metric(
                            'Tổng câu hỏi',
                            '${all.length}',
                            Icons.library_books_outlined,
                          ),
                          metric(
                            'Ngân hàng Boss',
                            '${all.where((q) => q['stageId'] == 4).length}',
                            Icons.shield_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Nội dung theo ải',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 1; i <= 4; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: Icon(
                                i == 4 ? Icons.shield : Icons.folder_outlined,
                              ),
                              title: Text(i == 4 ? 'Boss' : 'Ải $i'),
                              subtitle: Text(
                                '${all.where((q) => q['stageId'] == i).length} câu hỏi',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => setState(() {
                                stageFilter = i;
                                tab = 1;
                              }),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          stageFilter = 0;
                          tab = 1;
                        }),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Quản lý tất cả câu hỏi'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Tìm nội dung câu hỏi…',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (value) =>
                                  setState(() => search = value),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (int i = 0; i <= 4; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(
                                          i == 0
                                              ? 'Tất cả'
                                              : i == 4
                                              ? 'Boss'
                                              : 'Ải $i',
                                        ),
                                        selected: stageFilter == i,
                                        onSelected: (_) =>
                                            setState(() => stageFilter = i),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${filtered.length} câu hỏi'),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Hiện câu đã ngừng / đã hủy'),
                              value: showArchived,
                              onChanged: (value) =>
                                  setState(() => showArchived = value),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('Không có câu hỏi phù hợp.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  96,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final q = Map<String, dynamic>.from(
                                    filtered[i],
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Card(
                                      child: ListTile(
                                        title: Text('${q['content']}'),
                                        subtitle: Text(
                                          'Ải ${q['stageId']} • Đáp án ${q['correctionOption'] ?? q['correctOption']}\n${q['isVoided'] == true
                                              ? 'Đã hủy câu lỗi'
                                              : q['isArchived'] == true
                                              ? 'Đã ngừng sử dụng'
                                              : 'Đang sử dụng'}',
                                        ),
                                        onTap: busy || q['isArchived'] == true
                                            ? null
                                            : () => edit(q),
                                        trailing: IconButton(
                                          tooltip: 'Xóa / Xử lý câu lỗi',
                                          onPressed: busy
                                              ? null
                                              : () => remove(q),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class QuestionEditor extends StatefulWidget {
  const QuestionEditor({super.key, this.question});
  final Map<String, dynamic>? question;
  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  final api = AccountApi();
  final form = GlobalKey<FormState>();
  static const labels = {
    'content': 'Nội dung câu hỏi',
    'optionA': 'Đáp án A',
    'optionB': 'Đáp án B',
    'optionC': 'Đáp án C',
    'optionD': 'Đáp án D',
    'hint1': 'Gợi ý 1',
    'hint2': 'Gợi ý 2',
    'explanation': 'Giải thích',
  };
  late final Map<String, TextEditingController> fields;
  late int stage;
  late String answer;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    fields = {
      for (final key in labels.keys)
        key: TextEditingController(
          text: widget.question?[key] as String? ?? '',
        ),
    };
    stage = widget.question?['stageId'] as int? ?? 1;
    answer = widget.question?['correctOption'] as String? ?? 'A';
  }

  @override
  void dispose() {
    api.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = <String, dynamic>{
        'stageId': stage,
        'correctOption': answer,
        for (final e in fields.entries) e.key: e.value.text.trim(),
      };
      await api.call(
        'admin/questions${widget.question == null ? '' : '/${widget.question!['id']}'}',
        method: widget.question == null ? 'POST' : 'PUT',
        body: data,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.question == null ? 'Thêm câu hỏi' : 'Sửa câu hỏi'),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<int>(
            initialValue: stage,
            decoration: const InputDecoration(labelText: 'Ải'),
            items: [
              for (int i = 1; i <= 4; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(i == 4 ? 'Boss' : 'Ải $i'),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => stage = v!),
          ),
          ...labels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextFormField(
                controller: fields[e.key],
                enabled: !busy,
                minLines: 1,
                maxLines: 5,
                maxLength: e.key.startsWith('option') ? 1000 : null,
                decoration: InputDecoration(
                  labelText: e.value,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (e.key == 'content' || e.key.startsWith('option')) &&
                        (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập thông tin.'
                    : null,
              ),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: answer,
            decoration: const InputDecoration(labelText: 'Đáp án đúng'),
            items: [
              'A',
              'B',
              'C',
              'D',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: busy ? null : (v) => setState(() => answer = v!),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Đang lưu…' : 'Lưu câu hỏi'),
          ),
        ],
      ),
    ),
  );
}
