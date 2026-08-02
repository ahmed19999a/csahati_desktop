import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import 'package:csahati_desktop/constants/app_constants.dart';
import 'package:csahati_desktop/models.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({required this.walletBalance, required this.username, required this.onMenuTap, super.key});
  final String walletBalance;
  final String username;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, size: 30),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.account_balance_wallet_outlined, color: appRed, size: 22),
                const SizedBox(width: 6),
                Text('$walletBalance ريال', style: const TextStyle(color: appRed, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.brightness_3_outlined, size: 24, color: Colors.black),
            const Spacer(),
            Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            const CircleAvatar(radius: 24, backgroundColor: appBlue, child: Icon(Icons.person, color: Colors.white, size: 28)),
          ],
        ),
      ),
    );
  }
}

class SubHeader extends StatelessWidget {
  const SubHeader({required this.title, required this.onBack, super.key});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back, size: 28), onPressed: onBack),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class FileCard extends StatelessWidget {
  const FileCard({required this.file, this.selected = false, this.onToggleSelected, this.onEdit, this.onView, this.onDownload, super.key});
  final FileRecord file;
  final bool selected;
  final ValueChanged<bool>? onToggleSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final void Function(int index)? onDownload;

  @override
  Widget build(BuildContext context) {
    final tpl = templateForSlug(file.templateSlug);
    final client = file.client.isNotEmpty ? file.client : 'الوكيل الرئيسي';
    final notes = file.notes.isNotEmpty ? file.notes : 'لا توجد ملاحظات';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appCardLine, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          textDirection: TextDirection.ltr,
          children: [
            _miniAction(Icons.edit, appBlue, onEdit),
            const SizedBox(width: 10),
            _miniAction(Icons.download, appBlue, () {
              if (onDownload != null) {
                for (var i = 1; i <= file.downloads; i++) {
                  onDownload!(i);
                }
              } else if (onEdit != null) {
                onEdit!();
              }
            }),
            const Spacer(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(file.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(file.date, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onView,
              child: const CircleAvatar(radius: 14, backgroundColor: Colors.white, child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.folder, color: appBlue, size: 24))),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => onToggleSelected?.call(!selected),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? appBlue : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? appBlue : Colors.black87, width: 2),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _rowLabel('العميل', client, icon: Icons.person, iconColor: appBlue),
        const SizedBox(height: 8),
        _rowLabel('النوع', tpl.title, icon: Icons.push_pin, iconColor: Colors.red),
        const SizedBox(height: 8),
        _rowLabel('المستخدم', file.user, icon: Icons.person, iconColor: appBlue),
        const SizedBox(height: 8),
        _rowLabel('ملاحظات', notes, icon: Icons.note_alt_outlined, iconColor: Colors.orange),
      ]),
    );
  }

  Widget _miniAction(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _rowLabel(String label, String value, {required IconData icon, required Color iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class PeriodToggle extends StatelessWidget {
  const PeriodToggle({required this.closed, required this.onChanged, super.key});
  final bool closed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black26, width: 1.2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bar_chart, color: Colors.black, size: 24),
        const SizedBox(width: 10),
        const Text('الفترة مغلقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Switch(value: closed, onChanged: onChanged, activeColor: appBlue),
      ]),
    );
  }
}

class SummaryLine extends StatelessWidget {
  const SummaryLine({required this.total, required this.visible, super.key});
  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart, size: 20, color: Colors.black54),
        const SizedBox(width: 6),
        Text('الإجمالي: $total | الظاهر: $visible', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({required this.count, required this.onMore, super.key});
  final int count;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundIcon(Icons.remove, Colors.blue, () {}),
        const SizedBox(width: 16),
        Container(
          width: 42,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black26)),
          child: Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 16),
        _roundIcon(Icons.add, Colors.blue, () {}),
        const SizedBox(width: 18),
        OutlinedButton.icon(
          onPressed: onMore,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          label: const Text('إظهار المزيد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: appBlue,
            side: const BorderSide(color: appCardLine, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _roundIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class ChoiceBox extends StatelessWidget {
  const ChoiceBox({required this.label, required this.value, required this.onTap, super.key});
  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: appLightBlue, borderRadius: BorderRadius.circular(12), border: Border.all(color: appCardLine)),
        child: Row(children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: value.isEmpty ? Colors.grey : Colors.black))),
          const Icon(Icons.arrow_drop_down, color: appBlue),
        ]),
      ),
    );
  }
}

class FormFieldBox extends StatefulWidget {
  const FormFieldBox({required this.field, required this.value, required this.onChanged, this.onTranslate, this.onUpload, this.uploading = false, super.key});
  final FieldSpec field;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTranslate;
  final VoidCallback? onUpload;
  final bool uploading;

  @override
  State<FormFieldBox> createState() => _FormFieldBoxState();
}

class _FormFieldBoxState extends State<FormFieldBox> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant FormFieldBox old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(f.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        switch (f.kind) {
          FieldKind.text || FieldKind.textarea => TextField(
            controller: _ctrl,
            maxLines: f.kind == FieldKind.textarea ? 3 : 1,
            textDirection: _isEnglishField(f.key) ? TextDirection.ltr : TextDirection.rtl,
            keyboardType: _keyboardType(f.key),
            inputFormatters: _inputFormatters(f.key),
            decoration: InputDecoration(
              isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appCardLine)),
              suffixIcon: widget.onTranslate != null
                  ? IconButton(icon: const Icon(Icons.translate, size: 22), onPressed: widget.onTranslate)
                  : null,
            ),
            onChanged: widget.onChanged,
          ),
          FieldKind.select => ChoiceBox(label: '', value: widget.value, onTap: () => _showOptionSheet(context, f)),
          FieldKind.date => InkWell(
            onTap: () => _pickDate(context),
            child: IgnorePointer(child: TextField(
              controller: _ctrl, decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appCardLine)),
                suffixIcon: const Icon(Icons.calendar_today, size: 20)),
            ))),
          FieldKind.time => InkWell(
            onTap: () => _pickTime(context),
            child: IgnorePointer(child: TextField(
              controller: _ctrl, decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: appCardLine)),
                suffixIcon: const Icon(Icons.access_time, size: 20)),
            ))),
          FieldKind.file => ElevatedButton.icon(
            onPressed: widget.uploading ? null : widget.onUpload,
            icon: widget.uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, size: 20),
            label: Text(widget.uploading ? 'جاري الرفع...' : (widget.value.isEmpty ? 'رفع ملف' : 'تم الرفع ✓'), style: const TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(backgroundColor: widget.value.isNotEmpty ? Colors.green.shade50 : appLightBlue, foregroundColor: appBlue),
          ),
        },
      ]),
    );
  }

  void _showOptionSheet(BuildContext ctx, FieldSpec f) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('اختر ${f.label}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          ...f.options.map((o) => ListTile(title: Text(o), trailing: widget.value == o ? const Icon(Icons.check, color: appBlue) : null,
            onTap: () {
              widget.onChanged(o);
              Navigator.pop(ctx);
            })),
        ]),
      ),
    );
  }

  Future<void> _pickDate(BuildContext ctx) async {
    final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked != null) {
      final dateStr = intl.DateFormat('yyyy-MM-dd').format(picked);
      _ctrl.text = dateStr;
      widget.onChanged(dateStr);
    }
  }

  Future<void> _pickTime(BuildContext ctx) async {
    final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _ctrl.text = timeStr;
      widget.onChanged(timeStr);
    }
  }
}

bool _isEnglishField(String key) => key.contains('_en') || key.contains('English') || key.contains('english');
TextInputType _keyboardType(String key) {
  if (key.contains('phone') || key.contains('number') || key.contains('identity')) return TextInputType.phone;
  if (_isEnglishField(key)) return TextInputType.text;
  return TextInputType.text;
}

List<TextInputFormatter> _inputFormatters(String key) {
  if (key.contains('phone') || key.contains('identity') || key.contains('number')) {
    return [FilteringTextInputFormatter.digitsOnly];
  }
  return [];
}

String translateArabicText(String text) {
  if (text.trim().isEmpty) return '';
  final arEn = {
    'أ': 'A', 'ب': 'B', 'ت': 'T', 'ث': 'Th', 'ج': 'J', 'ح': 'H', 'خ': 'Kh', 'د': 'D', 'ذ': 'Th', 'ر': 'R',
    'ز': 'Z', 'س': 'S', 'ش': 'Sh', 'ص': 'S', 'ض': 'D', 'ط': 'T', 'ظ': 'Th', 'ع': 'A\'', 'غ': 'Gh',
    'ف': 'F', 'ق': 'Q', 'ك': 'K', 'ل': 'L', 'م': 'M', 'ن': 'N', 'ه': 'H', 'و': 'W', 'ي': 'Y', 'ة': 'h',
    'ئ': 'e', 'ء': 'a', 'ؤ': 'o', ' ': ' ', 'ى': 'a', 'لا': 'La', 'ال': 'Al',
  };
  final buf = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (arEn.containsKey(ch)) {
      if (ch == ' ' && buf.isNotEmpty && buf.toString()[buf.length - 1] == ' ') continue;
      buf.write(arEn[ch]!);
    } else {
      buf.write(ch);
    }
  }
  return buf.toString().trim();
}

class FormProgressStrip extends StatelessWidget {
  const FormProgressStrip({required this.fieldCount, required this.completedCount, super.key});
  final int fieldCount, completedCount;

  @override
  Widget build(BuildContext context) {
    final pct = fieldCount > 0 ? completedCount / fieldCount : 0.0;
    return Column(children: [
      Row(children: [
        const Text('إكتمال النموذج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$completedCount / $fieldCount', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: appCardLine, valueColor: const AlwaysStoppedAnimation<Color>(appBlue)),
      ),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.title, required this.subtitle, this.onAction, this.actionLabel, super.key});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, style: ElevatedButton.styleFrom(backgroundColor: appBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(actionLabel!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ],
        ]),
      ),
    );
  }
}

List<FieldSpec> fieldsFor(TemplateKind type) {
  switch (type) {
    case TemplateKind.generic:
      return [
        const FieldSpec(key: 'name_ar', label: 'الاسم', kind: FieldKind.text),
        const FieldSpec(key: 'identity_number', label: 'رقم الهوية', kind: FieldKind.text),
        const FieldSpec(key: 'document_date', label: 'تاريخ المستند', kind: FieldKind.date),
        const FieldSpec(key: 'notes', label: 'ملاحظات', kind: FieldKind.textarea, full: true),
      ];
    case TemplateKind.sickLeave:
      return [
        FieldSpec(key: 'identity_number', label: 'رقم الهوية', kind: FieldKind.text),
        FieldSpec(key: 'leave_id', label: 'رقم الإجازة المرضية', kind: FieldKind.text),
        FieldSpec(key: 'nationality_ar', label: 'الجنسية (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'nationality_en', label: 'الجنسية (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'name_ar', label: 'الاسم (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'name_en', label: 'الاسم (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'employer_ar', label: 'جهة العمل (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'employer_en', label: 'جهة العمل (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'leave_days', label: 'عدد أيام الإجازة', kind: FieldKind.text),
        FieldSpec(key: 'sector_type', label: 'القطاع', kind: FieldKind.select, options: ['حكومي', 'خاص']),
        FieldSpec(key: 'case_type', label: 'نوع الحالة', kind: FieldKind.select, options: ['مراجعة', 'تنويم', 'طوارئ']),
        FieldSpec(key: 'leave_from_greg', label: 'تاريخ بداية الإجازة', kind: FieldKind.date),
        FieldSpec(key: 'leave_to_greg', label: 'تاريخ نهاية الإجازة', kind: FieldKind.date),
        FieldSpec(key: 'leave_from_hijri', label: 'تاريخ بداية الإجازة هجري', kind: FieldKind.text, value: '13-02-1448'),
        FieldSpec(key: 'leave_to_hijri', label: 'تاريخ نهاية الإجازة هجري', kind: FieldKind.text, value: '13-02-1448'),
        FieldSpec(key: 'doctor_ar', label: 'اسم الطبيب (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'doctor_en', label: 'اسم الطبيب (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'position_ar', label: 'المسمى الوظيفي (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'position_en', label: 'المسمى الوظيفي (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'hospital_ar', label: 'اسم المستشفى (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'hospital_en', label: 'اسم المستشفى (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'hospital_logo', label: 'شعار المستشفى', kind: FieldKind.file),
        FieldSpec(key: 'license_number', label: 'رقم الترخيص', kind: FieldKind.text),
        FieldSpec(key: 'print_time', label: 'وقت الطباعة', kind: FieldKind.time),
      ];
    case TemplateKind.healthAnnual:
    case TemplateKind.healthFoodDelivery:
    case TemplateKind.healthRiyadh:
    case TemplateKind.healthSeasonal:
      return [
        FieldSpec(key: 'amanah', label: 'الأمانة / البلدية', kind: FieldKind.text, value: 'الرياض'),
        FieldSpec(key: 'name_ar', label: 'الاسم (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'name_en', label: 'الاسم (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'identity_number', label: 'رقم الهوية', kind: FieldKind.text),
        FieldSpec(key: 'gender', label: 'الجنس', kind: FieldKind.select, options: ['ذكر', 'أنثى']),
        FieldSpec(key: 'nationality', label: 'الجنسية', kind: FieldKind.text, value: 'السعودية'),
        FieldSpec(key: 'job', label: 'المهنة', kind: FieldKind.text),
        FieldSpec(key: 'issue_date', label: 'تاريخ الإصدار', kind: FieldKind.date),
        FieldSpec(key: 'expiry_date', label: 'تاريخ الانتهاء', kind: FieldKind.date),
        FieldSpec(key: 'program_type', label: 'نوع البرنامج', kind: FieldKind.text),
        FieldSpec(key: 'program_end_date', label: 'تاريخ نهاية البرنامج', kind: FieldKind.date),
        FieldSpec(key: 'facility_name', label: 'اسم المنشأة', kind: FieldKind.text),
        FieldSpec(key: 'facility_number', label: 'رقم المنشأة', kind: FieldKind.text),
        FieldSpec(key: 'photo', label: 'الصورة الشخصية', kind: FieldKind.file),
      ];
    case TemplateKind.driverCard1:
    case TemplateKind.driverCard2:
      return [
        FieldSpec(key: 'identity_number', label: 'رقم الهوية', kind: FieldKind.text),
        FieldSpec(key: 'city', label: 'المدينة', kind: FieldKind.text, value: 'عسير'),
        FieldSpec(key: 'sponsor_name_ar', label: 'اسم الكفيل (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'sponsor_name_en', label: 'اسم الكفيل (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'issue_date', label: 'تاريخ الإصدار', kind: FieldKind.date),
        FieldSpec(key: 'expiry_date', label: 'تاريخ الانتهاء', kind: FieldKind.date),
        FieldSpec(key: 'license_issue_date', label: 'تاريخ إصدار الرخصة', kind: FieldKind.date),
        FieldSpec(key: 'license_expiry_date', label: 'تاريخ انتهاء الرخصة', kind: FieldKind.date),
        FieldSpec(key: 'renew_date', label: 'تاريخ التجديد', kind: FieldKind.date),
        FieldSpec(key: 'driver_id', label: 'رقم السائق', kind: FieldKind.text),
        FieldSpec(key: 'driver_name_ar', label: 'اسم السائق (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'driver_name_en', label: 'اسم السائق (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'transport_type', label: 'نوع النقل', kind: FieldKind.select, options: ['نقل ثقيل', 'نقل خفيف', 'نقل متوسط']),
        FieldSpec(key: 'period', label: 'المدة', kind: FieldKind.select, options: ['سنويه', 'نصف سنويه', 'ربع سنويه']),
        FieldSpec(key: 'entity_type', label: 'نوع الكيان', kind: FieldKind.select, options: ['مؤسسة', 'شركة', 'فردي']),
        FieldSpec(key: 'request_type', label: 'نوع الطلب', kind: FieldKind.select, options: ['تجديد', 'إصدار', 'بدل فاقد']),
      ];
    case TemplateKind.operationCard1:
    case TemplateKind.operationCard2:
      return [
        FieldSpec(key: 'identity_number', label: 'رقم الهوية', kind: FieldKind.text),
        FieldSpec(key: 'city', label: 'المدينة', kind: FieldKind.text, value: 'عسير'),
        FieldSpec(key: 'name_ar', label: 'اسم المنشأة (عربي)', kind: FieldKind.text),
        FieldSpec(key: 'name_en', label: 'اسم المنشأة (إنجليزي)', kind: FieldKind.text, translate: true),
        FieldSpec(key: 'issue_date', label: 'تاريخ الإصدار', kind: FieldKind.date),
        FieldSpec(key: 'expiry_date', label: 'تاريخ الانتهاء', kind: FieldKind.date),
        FieldSpec(key: 'vehicle_make', label: 'نوع المركبة', kind: FieldKind.text),
        FieldSpec(key: 'vehicle_model', label: 'موديل المركبة', kind: FieldKind.text),
        FieldSpec(key: 'plate_number', label: 'رقم اللوحة', kind: FieldKind.text),
        FieldSpec(key: 'plate_color', label: 'لون اللوحة', kind: FieldKind.select, options: ['أبيض', 'أصفر', 'أزرق']),
        FieldSpec(key: 'vehicle_year', label: 'سنة الصنع', kind: FieldKind.text),
        FieldSpec(key: 'license_issue_date', label: 'تاريخ إصدار الرخصة', kind: FieldKind.date),
        FieldSpec(key: 'license_expiry_date', label: 'تاريخ انتهاء الرخصة', kind: FieldKind.date),
        FieldSpec(key: 'renew_date', label: 'تاريخ التجديد', kind: FieldKind.date),
        FieldSpec(key: 'serial_number', label: 'الرقم التسلسلي', kind: FieldKind.text),
        FieldSpec(key: 'transport_type', label: 'نوع النقل', kind: FieldKind.select, options: ['نقل ثقيل', 'نقل خفيف', 'نقل متوسط']),
        FieldSpec(key: 'period', label: 'المدة', kind: FieldKind.select, options: ['سنويه', 'نصف سنويه', 'ربع سنويه']),
        FieldSpec(key: 'entity_type', label: 'نوع الكيان', kind: FieldKind.select, options: ['مؤسسة', 'شركة', 'فردي']),
        FieldSpec(key: 'request_type', label: 'نوع الطلب', kind: FieldKind.select, options: ['تجديد', 'إصدار', 'بدل فاقد']),
      ];
  }
}

List<FieldSpec> fieldsForTemplate(FormTemplate template) {
  if (template.fields.isNotEmpty) return template.fields;
  return fieldsFor(template.kind);
}
