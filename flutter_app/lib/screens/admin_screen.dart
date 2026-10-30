import 'package:flutter/material.dart';

import '../services/account_service.dart';
import '../services/auth_client.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final api = AccountApi();
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
    }
  }

  Future<void> edit([Map<String, dynamic>? question]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuestionEditor(question: question)),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> remove(Map<String, dynamic> question) async {
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

  @override
  Widget build(BuildContext context) {
    if (AuthSession.role != 'Admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản trị')),
        body: const Center(child: Text('Chỉ quản trị viên được truy cập.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho câu hỏi'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm câu'),
      ),
      body: Column(
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
          Expanded(
            child: error != null && questions == null
                ? Center(
                    child: TextButton(
                      onPressed: load,
                      child: const Text('Thử tải lại'),
                    ),
                  )
                : questions == null
                ? const Center(child: CircularProgressIndicator())
                : questions!.isEmpty
                ? const Center(child: Text('Chưa có câu hỏi.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: questions!.length,
                    itemBuilder: (context, i) {
                      final q = Map<String, dynamic>.from(questions![i]);
                      return Card(
                        child: ListTile(
                          title: Text('${q['content']}'),
                          subtitle: Text(
                            'Ải ${q['stageId']} • Đáp án ${q['correctOption']}',
                          ),
                          onTap: busy ? null : () => edit(q),
                          trailing: IconButton(
                            tooltip: 'Xóa',
                            onPressed: busy ? null : () => remove(q),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
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
