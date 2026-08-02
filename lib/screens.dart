import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:file_picker/file_picker.dart';
import 'package:csahati_desktop/constants/app_constants.dart';
import 'package:csahati_desktop/models.dart';
import 'package:csahati_desktop/services/api_service.dart';
import 'package:csahati_desktop/widgets.dart';

final _api = ApiService();

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onLoginSuccess, super.key});
  final ValueChanged<AppBootstrap> onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController(), _passCtrl = TextEditingController();
  String _countryCode = '966';
  bool _loading = false, _remember = false, _showPass = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final remembered = await _api.rememberedLogin();
    if (remembered['password']?.isNotEmpty == true) {
      setState(() {
        _countryCode = remembered['country_code'] ?? '966';
        _phoneCtrl.text = remembered['phone'] ?? '';
        _passCtrl.text = remembered['password'] ?? '';
        _remember = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final bootstrap = await _api.login(_countryCode, _phoneCtrl.text.trim(), _passCtrl.text, remember: _remember);
      if (_remember) await _api.saveRemembered(_countryCode, _phoneCtrl.text.trim(), _passCtrl.text);
      else await _api.clearRemembered();
      widget.onLoginSuccess(bootstrap);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.speed, size: 54, color: appBlue),
            const SizedBox(height: 8),
            const Text('المعقب السريع', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 4))]),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'مفتاح الدولة', border: OutlineInputBorder()),
                      controller: TextEditingController(text: _countryCode),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _countryCode = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'رقم الجوال', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور', border: const OutlineInputBorder(),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, size: 22), onPressed: () => setState(() => _showPass = !_showPass)),
                      const Icon(Icons.fingerprint, size: 22, color: appBlue),
                    ]),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false)),
                  const Text('تذكرني', style: TextStyle(fontSize: 13)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(backgroundColor: appBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: appRed, fontSize: 14), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                const Text('بتسجيل الدخول أنت توافق على سياسة الخصوصية والشروط والأحكام', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({
    required this.bootstrap, required this.templates, required this.files,
    required this.onAdd, required this.onEdit, required this.onView, required this.onLogout, required this.onMenuPage, super.key,
  });
  final AppBootstrap bootstrap;
  final List<FormTemplate> templates;
  final List<FileRecord> files;
  final VoidCallback onAdd;
  final ValueChanged<FileRecord> onEdit;
  final ValueChanged<FileRecord> onView;
  final VoidCallback onLogout;
  final ValueChanged<MenuPage> onMenuPage;
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _periodClosed = true;
  @override
  Widget build(BuildContext context) {
    final drawerItems = [
      _DrawerItem(Icons.dashboard, 'لوحة القيادة', () => widget.onMenuPage(MenuPage.reports)),
      _DrawerItem(Icons.bar_chart, 'تقارير', () => widget.onMenuPage(MenuPage.reports)),
      _DrawerItem(Icons.people, 'المستخدمين', () => widget.onMenuPage(MenuPage.users)),
      _DrawerItem(Icons.public, 'الدومينات', () => widget.onMenuPage(MenuPage.domains)),
      _DrawerItem(Icons.credit_card, 'الدفع', () => widget.onMenuPage(MenuPage.payments)),
      _DrawerItem(Icons.build_circle, 'الخدمات', () => widget.onMenuPage(MenuPage.services)),
      _DrawerItem(Icons.support_agent, 'طلب خدمة او اقتراح', () => widget.onMenuPage(MenuPage.request)),
      _DrawerItem(Icons.logout, 'تسجيل الخروج', widget.onLogout, isLogout: true),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * .72,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(children: [
              SizedBox(
                height: 170,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('المعقب\nالسريع', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF071657), fontSize: 26, height: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 16),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(color: appBlue, shape: BoxShape.circle),
                        child: const Icon(Icons.speed, color: Colors.white, size: 38),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.black),
              ...drawerItems.map((item) => _DrawerMenuTile(
                item: item,
                onTap: () {
                  Navigator.pop(context);
                  item.onTap();
                },
              )),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        MainHeader(
          walletBalance: widget.bootstrap.walletBalance,
          username: widget.bootstrap.currentUser?.name ?? 'الوكيل الرئيسي',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add, size: 24),
                label: const Text('إضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const Spacer(),
              PeriodToggle(closed: _periodClosed, onChanged: (v) => setState(() => _periodClosed = v)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SummaryLine(total: widget.files.length, visible: widget.files.length),
        const SizedBox(height: 20),
        Expanded(
          child: widget.files.isEmpty
              ? const EmptyState(icon: Icons.folder_open, title: 'لا توجد ملفات', subtitle: 'اضغط على زر إضافة لإضافة ملف جديد')
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  children: [
                    FileCard(
                      file: widget.files.first,
                      onEdit: () => widget.onEdit(widget.files.first),
                      onView: () => widget.onView(widget.files.first),
                      onDownload: (idx) => _downloadPdf(widget.files.first, fileIndex: idx),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        PaginationBar(count: 5, onMore: () {}),
        const SizedBox(height: 24),
      ]),
    );
  }

  Future<void> _downloadPdf(FileRecord file, {int fileIndex = 1}) async {
    try {
      final url = _api.documentPdfUrl(file, fileIndex: fileIndex);
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('تعذر فتح رابط الملف');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل PDF: $e'), backgroundColor: appRed));
      }
    }
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLogout;
  _DrawerItem(this.icon, this.label, this.onTap, {this.isLogout = false});
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({required this.item, required this.onTap});

  final _DrawerItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: Colors.black, size: 27),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.isLogout ? appRed : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormScreen extends StatefulWidget {
  const FormScreen({required this.template, required this.client, required this.existingFile, required this.onSaved, required this.onBack, super.key});
  final FormTemplate template;
  final String client;
  final FileRecord? existingFile;
  final ValueChanged<FileRecord> onSaved;
  final VoidCallback onBack;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final Map<String, String> _values = {};
  bool _saving = false;
  String? _error;
  late FormTemplate _template;
  late String _client;
  bool _uploading = false;

  final _clients = const ['طوارئ', 'مجاني', 'كعبيلان', 'تجريبي'];

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    _client = widget.client;
    if (widget.existingFile != null) {
      _values.addAll(widget.existingFile!.values);
    }
    for (final f in fieldsForTemplate(_template)) {
      _values.putIfAbsent(f.key, () => f.value);
    }
  }

  List<FieldSpec> get _visibleFields => fieldsForTemplate(_template);
  int get _completedCount => _visibleFields.where((f) => (_values[f.key] ?? '').trim().isNotEmpty).length;

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final file = await _api.createDocument(_template, _client, _values, existing: widget.existingFile);
      widget.onSaved(file);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadForField(FieldSpec field) async {
    if (_uploading) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final url = await _api.uploadFile(result.files.first.path!, field.key == 'photo' ? 'photo' : field.key);
      if (!mounted) return;
      setState(() => _values[field.key] = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر رفع الملف: $e'), backgroundColor: appRed));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingFile != null;
    return Column(children: [
      SubHeader(title: isEdit ? 'تعديل النموذج' : 'إضافة نموذج', onBack: widget.onBack),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: appLightBlue, borderRadius: BorderRadius.circular(16), border: Border.all(color: appCardLine)),
              child: Column(children: [
                Text(_template.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(isEdit ? 'عدّل البيانات ثم احفظ.' : 'اختر النموذج والعميل ثم املأ الحقول.', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: ChoiceBox(label: 'النوع', value: _template.title, onTap: () => _pickTemplate(context))),
              const SizedBox(width: 16),
              Expanded(child: ChoiceBox(label: 'العميل', value: _client, onTap: () => _pickClient(context))),
            ]),
            const SizedBox(height: 22),
            FormProgressStrip(fieldCount: _visibleFields.length, completedCount: _completedCount),
            const SizedBox(height: 24),
            Wrap(spacing: 14, runSpacing: 4, children: _visibleFields.map((f) => SizedBox(
              width: f.full ? double.infinity : 360,
              child: FormFieldBox(field: f, value: _values[f.key] ?? '', onChanged: (v) => setState(() => _values[f.key] = v),
                onUpload: f.kind == FieldKind.file ? () => _uploadForField(f) : null, uploading: _uploading && f.kind == FieldKind.file),
            )).toList()),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: appBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'حفظ التعديلات' : 'حفظ الملف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: appRed, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ]),
        ),
      ),
    ]);
  }

  void _pickTemplate(BuildContext ctx) {
    final templates = List<FormTemplate>.from(runtimeTemplates.values);
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('اختر النموذج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          ...templates.map((t) => ListTile(
            title: Text(t.title), subtitle: Text(t.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: _template.slug == t.slug ? const Icon(Icons.check, color: appBlue) : null,
            onTap: () {
              setState(() {
                _template = t;
                for (final field in fieldsForTemplate(_template)) {
                  _values.putIfAbsent(field.key, () => field.value);
                }
              });
              Navigator.pop(ctx);
            },
          )),
        ]),
      ),
    );
  }

  void _pickClient(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('اختر العميل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          ..._clients.map((c) => ListTile(
            title: Text(c), trailing: _client == c ? const Icon(Icons.check, color: appBlue) : null,
            onTap: () { setState(() => _client = c); Navigator.pop(ctx); },
          )),
        ]),
      ),
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({required this.file, required this.onBack, super.key});
  final FileRecord file;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tpl = templateForSlug(file.templateSlug);
    final thumbUrl = _api.documentThumbnailUrl(file);
    return Column(children: [
      SubHeader(title: '${tpl.title} - ${file.name}', onBack: onBack),
      Expanded(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5, maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: appBlue));
                },
                errorBuilder: (context, error, stackTrace) => const EmptyState(icon: Icons.error_outline, title: 'تعذر عرض المعاينة', subtitle: 'جرب تحميل الملف PDF بدلاً من ذلك'),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class MenuPageScreen extends StatelessWidget {
  const MenuPageScreen({required this.page, required this.bootstrap, required this.templates, required this.onBack, required this.onTemplateSelected, super.key});
  final MenuPage page;
  final AppBootstrap bootstrap;
  final List<FormTemplate> templates;
  final VoidCallback onBack;
  final ValueChanged<FormTemplate> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SubHeader(title: _pageTitle(page), onBack: onBack),
      Expanded(child: _pageContent(context)),
    ]);
  }

  String _pageTitle(MenuPage p) {
    switch (p) {
      case MenuPage.reports: return 'التقارير';
      case MenuPage.users: return 'المستخدمين';
      case MenuPage.domains: return 'النطاقات';
      case MenuPage.payments: return 'المدفوعات';
      case MenuPage.admin: return 'الإدارة';
      case MenuPage.services: return 'الخدمات';
      case MenuPage.request: return 'طلب خدمة';
    }
  }

  Widget _pageContent(BuildContext context) {
    switch (page) {
      case MenuPage.reports:
        return const Center(child: EmptyState(icon: Icons.bar_chart, title: 'التقارير والإحصائيات', subtitle: 'قريباً - عرض التقارير والإحصائيات'));
      case MenuPage.users:
        return const Center(child: EmptyState(icon: Icons.people, title: 'إدارة المستخدمين', subtitle: 'قريباً - إضافة وإدارة المستخدمين'));
      case MenuPage.domains:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, size: 64, color: appBlue),
          const SizedBox(height: 12),
          const Text('app.csahati.site', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('النطاق الأساسي للتطبيق', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ]));
      case MenuPage.payments:
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.payment, size: 64, color: appBlue),
          const SizedBox(height: 12),
          Text('الرصيد: ${bootstrap.walletBalance} ريال', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('إجمالي الإضافات: ${0}', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ]));
      case MenuPage.services:
        final sourceTemplates = templates.isEmpty ? defaultFormTemplates : templates;
        final services = sourceTemplates.where((template) {
          return template.slug == 'sick-leave' ||
              template.slug == 'sick-leave-2' ||
              template.slug.contains('health-certificate');
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appLightBlue,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appCardLine, width: 1.2),
              ),
              child: Row(children: [
                const CircleAvatar(radius: 24, backgroundColor: appBlue, child: Icon(Icons.settings_applications, color: Colors.white)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('لوحة النماذج المرتبطة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('المصدر: mang.csahati.site', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ]),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://mang.csahati.site/'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('فتح اللوحة'),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ...services.map((template) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onTemplateSelected(template),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: appCardLine, width: 1.2),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: appLightBlue,
                      child: Icon(_templateIcon(template.kind), color: appBlue, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(template.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(template.category.isEmpty ? 'نموذج مرتبط بسجل الإدارة' : template.category, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(999)),
                      child: const Text('مرتبط', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_back_ios_new, color: appBlue, size: 18),
                  ]),
                ),
              ),
            )),
          ],
        );
      case MenuPage.request:
        return const Center(child: EmptyState(icon: Icons.request_page, title: 'طلب خدمة جديدة', subtitle: 'قريباً - إرسال طلب خدمة جديد'));
      case MenuPage.admin:
        return const Center(child: EmptyState(icon: Icons.admin_panel_settings, title: 'لوحة الإدارة', subtitle: 'قريباً - إدارة القوالب والإعدادات'));
    }
  }

  IconData _templateIcon(TemplateKind kind) {
    switch (kind) {
      case TemplateKind.generic: return Icons.description;
      case TemplateKind.sickLeave: return Icons.sick;
      case TemplateKind.driverCard1:
      case TemplateKind.driverCard2: return Icons.directions_car;
      case TemplateKind.operationCard1:
      case TemplateKind.operationCard2: return Icons.engineering;
      case TemplateKind.healthAnnual:
      case TemplateKind.healthFoodDelivery:
      case TemplateKind.healthRiyadh:
      case TemplateKind.healthSeasonal: return Icons.health_and_safety;
    }
  }
}
