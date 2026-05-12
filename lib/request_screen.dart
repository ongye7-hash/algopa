import 'package:flutter/material.dart';
import 'db.dart';
import 'error.dart';

class RequestScreen extends StatefulWidget {
  final String? prefillName;
  const RequestScreen({super.key, this.prefillName});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _contactCtrl = TextEditingController();
  String? _category;
  bool _submitting = false;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phoneRegex = RegExp(r'^010-?\d{4}-?\d{4}$');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return '매장명을 입력해주세요';
    if (s.length < 2) return '매장명은 최소 2자 이상';
    return null;
  }

  String? _validateContact(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (_emailRegex.hasMatch(s) || _phoneRegex.hasMatch(s)) return null;
    return '이메일 또는 010-xxxx-xxxx 형식';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await submitBrandRequest(
        brandName: _nameCtrl.text,
        category: _category,
        contact: _contactCtrl.text,
      );
      if (!mounted) return;
      _showCompletedDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeError(e)),
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: _submit,
          ),
        ),
      );
    }
  }

  void _showCompletedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('요청 접수됐습니다'),
        content: const Text(
          '24시간 내 검토 후 추가 여부 알려드릴게요.\n'
          '연락처 남기셨으면 알림 드립니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매장 추가 요청')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: widget.prefillName == null ||
                  widget.prefillName!.isEmpty,
              decoration: const InputDecoration(
                labelText: '매장명 *',
                hintText: '예: 본죽',
                border: OutlineInputBorder(),
              ),
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '카테고리 (선택)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— 선택 안 함 —',
                      style: TextStyle(color: Colors.grey)),
                ),
                ...kBrandCategories.map(
                  (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: '연락처 (선택)',
                hintText: '이메일 또는 010-xxxx-xxxx',
                helperText: '추가 완료 시 알림 드립니다',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _validateContact,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('요청 보내기'),
            ),
          ],
        ),
      ),
    );
  }
}
