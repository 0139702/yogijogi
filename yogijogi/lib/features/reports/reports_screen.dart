import 'package:material_ui/material_ui.dart';

import 'report.dart';
import 'report_api.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ReportApi api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Report>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = widget.api.baseUrl == null
        ? Future.value(const [])
        : widget.api.list();
  }

  void _refresh() => setState(() => _reports = widget.api.list());

  Future<void> _edit([Report? report]) async {
    final saved = await showDialog<Report>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReportForm(api: widget.api, report: report),
    );
    if (saved != null && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.api.baseUrl == null) {
      return const Center(child: Text('제보를 보려면 API 주소를 설정해 주세요.'));
    }
    return Column(
      children: [
        const ListTile(
          title: Text('개발용 제보'),
          subtitle: Text('샘플 데이터만 사용해 주세요.'),
        ),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(onPressed: _refresh, child: const Text('새로고침')),
            FilledButton(onPressed: () => _edit(), child: const Text('제보 등록')),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<Report>>(
            future: _reports,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('제보를 불러오지 못했습니다.'));
              }
              final reports = snapshot.requireData;
              if (reports.isEmpty) {
                return const Center(child: Text('등록된 제보가 없습니다.'));
              }
              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final status = report.status == 'received'
                      ? '등록됨'
                      : report.status;
                  final source = report.source == 'user_report'
                      ? '사용자 제보'
                      : report.source;
                  return ListTile(
                    title: Text('${report.type} · ${report.location}'),
                    subtitle: Text(
                      '${report.description}\n$status · $source'
                      '\n발생 ${_displayTime(report.occurredAt)}'
                      ' · 갱신 ${_displayTime(report.updatedAt)}',
                    ),
                    trailing: IconButton(
                      tooltip: '제보 수정',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(report),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

String _displayTime(DateTime time) =>
    time.toLocal().toString().substring(0, 16);

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.api, this.report});

  final ReportApi api;
  final Report? report;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _form = GlobalKey<FormState>();
  late final _type = TextEditingController(text: widget.report?.type);
  late final _location = TextEditingController(text: widget.report?.location);
  late final _description = TextEditingController(
    text: widget.report?.description,
  );
  late DateTime _occurredAt = (widget.report?.occurredAt ?? DateTime.now())
      .toLocal();
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _type.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5);
    final last = DateTime(now.year + 1);
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: _occurredAt.isBefore(first) ? _occurredAt : first,
      lastDate: _occurredAt.isAfter(last) ? _occurredAt : last,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final saved = await widget.api.save(
        id: widget.report?.id,
        type: _type.text,
        location: _location.text,
        description: _description.text,
        occurredAt: _occurredAt,
      );
      if (mounted) Navigator.pop(context, saved);
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  Widget _field(String label, TextEditingController controller, int limit) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLength: limit,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value!.trim().isEmpty ? '$label 항목을 입력해 주세요.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.report == null ? '제보 등록' : '제보 수정'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('유형', _type, 60),
            _field('위치', _location, 120),
            _field('설명', _description, 1000),
            TextButton(
              onPressed: _saving ? null : _pickTime,
              child: Text('발생 시각 ${_displayTime(_occurredAt)}'),
            ),
            if (_failed) const Text('저장하지 못했습니다. API 상태를 확인해 주세요.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '저장 중' : '저장'),
        ),
      ],
    );
  }
}
