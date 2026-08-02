import 'dart:math';

import 'package:csahati_desktop/constants/app_constants.dart';

enum AppScreen { list, form, preview, menuPage }

enum MenuPage { reports, users, domains, payments, admin, services, request }

enum TemplateKind {
  generic,
  sickLeave,
  driverCard1,
  driverCard2,
  operationCard1,
  operationCard2,
  healthAnnual,
  healthFoodDelivery,
  healthRiyadh,
  healthSeasonal,
}

enum FieldKind { text, select, date, time, file, textarea }

enum ManagedOptionKind { hospital, doctor, position }

class FileRecord {
  FileRecord({
    this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.user,
    required this.client,
    String? templateSlug,
    this.personKey = '',
    this.notes = 'لا توجد ملاحظات',
    this.downloads = 1,
    this.htmlUrl = '',
    this.pdfUrl = '',
    this.values = const {},
  }) : templateSlug = templateSlug ?? _docSlug(type);

  final int? id;
  final String name;
  final String date;
  final TemplateKind type;
  final String user;
  final String client;
  final String templateSlug;
  final String personKey;
  final String notes;
  final int downloads;
  final String htmlUrl;
  final String pdfUrl;
  final Map<String, String> values;

  factory FileRecord.fromApi(Map<String, dynamic> item) {
    final fields = item['fields_data'] is Map
        ? Map<String, dynamic>.from(item['fields_data'] as Map)
        : <String, dynamic>{};
    final genFiles = fields['generated_files'] is List
        ? List<dynamic>.from(fields['generated_files'] as List)
        : const <dynamic>[];
    final slug = _canonicalSlug((item['document_type_slug'] ?? '').toString());
    return FileRecord(
      id: _asInt(item['id']),
      name: (item['person_name'] ?? 'مستند بدون اسم').toString(),
      date: (item['document_date'] ?? '').toString(),
      type: _kindFromSlug(slug),
      templateSlug: slug.isEmpty ? null : slug,
      user: (item['app_user'] ?? 'كعبيلان').toString(),
      client: (item['client_name'] ?? 'طوارئ').toString(),
      personKey: (item['person_key'] ?? '').toString(),
      notes: (item['notes'] ?? 'لا توجد ملاحظات').toString(),
      downloads: genFiles.isNotEmpty ? genFiles.length : 1,
      htmlUrl: (item['html_url'] ?? '').toString(),
      pdfUrl: (item['pdf_url'] ?? '').toString(),
      values: fields.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.phone,
    required this.isAgent,
    required this.active,
    this.notes = '',
    this.createdBy = '',
    this.additionsCount = 0,
  });

  final int id;
  final String name;
  final String countryCode;
  final String phone;
  final bool isAgent;
  final bool active;
  final String notes;
  final String createdBy;
  final int additionsCount;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: _asInt(json['id']) ?? 0,
        name: (json['name'] ?? '').toString(),
        countryCode: (json['country_code'] ?? '966').toString(),
        phone: (json['phone'] ?? '').toString(),
        isAgent: json['is_agent'] == true || json['is_agent'] == 1,
        active: json['active'] != false && json['active'] != 0,
        notes: (json['notes'] ?? '').toString(),
        createdBy: (json['created_by'] ?? '').toString(),
        additionsCount: _asInt(json['additions_count']) ?? 0,
      );
}

class AppBootstrap {
  const AppBootstrap({
    this.currentUser,
    required this.users,
    required this.agentEnabled,
    required this.walletBalance,
    required this.totalAdditions,
  });

  final AppUser? currentUser;
  final List<AppUser> users;
  final bool agentEnabled;
  final String walletBalance;
  final int totalAdditions;

  factory AppBootstrap.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map
        ? Map<String, dynamic>.from(json['settings'] as Map)
        : <String, dynamic>{};
    final stats = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : <String, dynamic>{};
    final rawUsers = json['users'] is List ? json['users'] as List : const [];
    return AppBootstrap(
      currentUser: json['user'] is Map
          ? AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      users: rawUsers
          .whereType<Map>()
          .map((u) => AppUser.fromJson(Map<String, dynamic>.from(u)))
          .toList(),
      agentEnabled: settings['agent_enabled'] != false,
      walletBalance: (settings['wallet_balance'] ?? '0').toString(),
      totalAdditions: _asInt(stats['total_additions']) ?? 0,
    );
  }
}

class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    this.kind = FieldKind.text,
    this.options = const [],
    this.value = '',
    this.translate = false,
    this.full = false,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final String value;
  final bool translate;
  final bool full;

  factory FieldSpec.fromJson(Map<String, dynamic> json) {
    return FieldSpec(
      key: (json['key'] ?? json['field_key'] ?? json['name'] ?? '').toString(),
      label: (json['label'] ?? json['title'] ?? json['name'] ?? '').toString(),
      kind: fieldKindFromString((json['kind'] ?? json['type'] ?? 'text').toString()),
      options: json['options'] is List
          ? (json['options'] as List).map((item) => item.toString()).toList()
          : const [],
      value: (json['value'] ?? json['default'] ?? '').toString(),
      translate: json['translate'] == true || json['auto_translate'] == true,
      full: json['full'] == true || json['full_width'] == true,
    );
  }
}

FieldKind fieldKindFromString(String value) {
  switch (value.trim().toLowerCase()) {
    case 'select':
    case 'dropdown':
      return FieldKind.select;
    case 'date':
      return FieldKind.date;
    case 'time':
      return FieldKind.time;
    case 'file':
    case 'image':
    case 'upload':
      return FieldKind.file;
    case 'textarea':
    case 'multiline':
      return FieldKind.textarea;
    default:
      return FieldKind.text;
  }
}

class FormTemplate {
  const FormTemplate({
    required this.slug,
    required this.title,
    required this.previewUrl,
    required this.downloadUrl,
    this.category = '',
    this.status = 'approved',
    this.downloadName = '',
    this.barcodeUrl = '',
    this.checkUrl = '',
    this.active = true,
    this.fields = const [],
  });

  final String slug;
  final String title;
  final String category;
  final String previewUrl;
  final String downloadUrl;
  final String status;
  final String downloadName;
  final String barcodeUrl;
  final String checkUrl;
  final bool active;
  final List<FieldSpec> fields;

  TemplateKind get kind => _kindFromSlug(slug);

  factory FormTemplate.fromJson(Map<String, dynamic> json) => FormTemplate(
        slug: (json['slug'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        previewUrl: (json['preview_url'] ?? '').toString(),
        downloadUrl: (json['download_url'] ?? json['preview_url'] ?? '').toString(),
        status: (json['status'] ?? 'approved').toString(),
        downloadName: (json['download_name'] ?? '').toString(),
        barcodeUrl: (json['barcode_url'] ?? '').toString(),
        checkUrl: (json['check_url'] ?? '').toString(),
        active: json['active'] != false,
        fields: json['fields'] is List
            ? (json['fields'] as List)
                .whereType<Map>()
                .map((item) => FieldSpec.fromJson(Map<String, dynamic>.from(item)))
                .where((field) => field.key.isNotEmpty && field.label.isNotEmpty)
                .toList()
            : const [],
      );
}

final defaultFormTemplates = [
  FormTemplate(slug: 'sick-leave', title: 'إجازة مرضية', category: 'التقارير الطبية', previewUrl: '$legacyDeskApiBase/render-template?slug=sick-leave', downloadUrl: '$legacyDeskApiBase/render-template?slug=sick-leave'),
  FormTemplate(slug: 'sick-leave-2', title: 'إجازة مرضية 2', category: 'التقارير الطبية', previewUrl: '$legacyDeskApiBase/render-template?slug=sick-leave-2', downloadUrl: '$legacyDeskApiBase/render-template?slug=sick-leave-2'),
  FormTemplate(slug: 'driver-card-1', title: 'بطاقة سائق 1', category: 'النقل', previewUrl: '$legacyDeskApiBase/render-template?slug=driver-card-1', downloadUrl: '$legacyDeskApiBase/render-template?slug=driver-card-1'),
  FormTemplate(slug: 'driver-card-2', title: 'بطاقة سائق 2', category: 'النقل', previewUrl: '$legacyDeskApiBase/render-template?slug=driver-card-2', downloadUrl: '$legacyDeskApiBase/render-template?slug=driver-card-2'),
  FormTemplate(slug: 'annual-health-certificate', title: 'شهادة صحية سنوية', category: 'الشهادات الصحية', previewUrl: '$legacyDeskApiBase/render-template?slug=annual-health-certificate', downloadUrl: '$legacyDeskApiBase/render-template?slug=annual-health-certificate'),
  FormTemplate(slug: 'food-delivery-health-certificate', title: 'شهادة صحية لموصلي الطعام', category: 'الشهادات الصحية', previewUrl: '$legacyDeskApiBase/render-template?slug=food-delivery-health-certificate', downloadUrl: '$legacyDeskApiBase/render-template?slug=food-delivery-health-certificate'),
  FormTemplate(slug: 'riyadh-health-certificate', title: 'شهادة صحية الرياض', category: 'الشهادات الصحية', previewUrl: '$legacyDeskApiBase/render-template?slug=riyadh-health-certificate', downloadUrl: '$legacyDeskApiBase/render-template?slug=riyadh-health-certificate'),
  FormTemplate(slug: 'seasonal-health-certificate', title: 'شهادة صحية موسمية', category: 'الشهادات الصحية', previewUrl: '$legacyDeskApiBase/render-template?slug=seasonal-health-certificate', downloadUrl: '$legacyDeskApiBase/render-template?slug=seasonal-health-certificate'),
  FormTemplate(slug: 'operation-card-1', title: 'كرت تشغيل 1', category: 'النقل', previewUrl: '$legacyDeskApiBase/render-template?slug=operation-card-1', downloadUrl: '$legacyDeskApiBase/render-template?slug=operation-card-1'),
  FormTemplate(slug: 'operation-card-2', title: 'كرت تشغيل 2', category: 'النقل', previewUrl: '$legacyDeskApiBase/render-template?slug=operation-card-2', downloadUrl: '$legacyDeskApiBase/render-template?slug=operation-card-2'),
];

final runtimeTemplates = <String, FormTemplate>{
  for (final t in defaultFormTemplates) t.slug: t,
};

String _docSlug(TemplateKind kind) {
  switch (kind) {
    case TemplateKind.generic: return 'generic';
    case TemplateKind.sickLeave: return 'sick-leave';
    case TemplateKind.driverCard1: return 'driver-card-1';
    case TemplateKind.driverCard2: return 'driver-card-2';
    case TemplateKind.operationCard1: return 'operation-card-1';
    case TemplateKind.operationCard2: return 'operation-card-2';
    case TemplateKind.healthAnnual: return 'annual-health-certificate';
    case TemplateKind.healthFoodDelivery: return 'food-delivery-health-certificate';
    case TemplateKind.healthRiyadh: return 'riyadh-health-certificate';
    case TemplateKind.healthSeasonal: return 'seasonal-health-certificate';
  }
}

TemplateKind _kindFromSlug(String slug) {
  switch (slug) {
    case 'sick-leave': return TemplateKind.sickLeave;
    case 'sick-leave-2': return TemplateKind.sickLeave;
    case 'driver-card-1': return TemplateKind.driverCard1;
    case 'driver-card-2': return TemplateKind.driverCard2;
    case 'operation-card-1': return TemplateKind.operationCard1;
    case 'operation-card-2': return TemplateKind.operationCard2;
    case 'annual-health-certificate': return TemplateKind.healthAnnual;
    case 'food-delivery-health-certificate': return TemplateKind.healthFoodDelivery;
    case 'riyadh-health-certificate': return TemplateKind.healthRiyadh;
    case 'seasonal-health-certificate': return TemplateKind.healthSeasonal;
    default: return TemplateKind.generic;
  }
}

String _canonicalSlug(String slug) {
  final v = slug.trim().replaceAll('-', '_');
  const aliases = {
    'sick_leave': 'sick-leave', 'sick_leave_2': 'sick-leave-2',
    'driver_card': 'driver-card-1', 'driver_card_1': 'driver-card-1', 'driver_card_2': 'driver-card-2',
    'operation_card': 'operation-card-1', 'operation_card_1': 'operation-card-1', 'operation_card_2': 'operation-card-2',
    'health_certificate': 'annual-health-certificate', 'health_certificate_annual': 'annual-health-certificate',
    'health_certificate_food_delivery': 'food-delivery-health-certificate',
    'health_certificate_riyadh': 'riyadh-health-certificate', 'health_certificate_seasonal': 'seasonal-health-certificate',
  };
  return aliases[v] ?? v;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse((v ?? '').toString());
}

String todayDate() => DateTime.now().toIso8601String().split('T').first;

String digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

final _leaveIdRng = Random();
String randomSickLeaveId(String sector) {
  final n = sector.trim().toLowerCase();
  final priv = n.contains('خاص') || n.contains('private') || n.contains('اهلي') || n.contains('أهلي');
  final suffix = List.generate(8, (_) => _leaveIdRng.nextInt(10)).join();
  return priv ? 'PSL260$suffix' : 'GSL264$suffix';
}

FormTemplate templateForSlug(String slug) =>
    runtimeTemplates[slug] ?? defaultFormTemplates.firstWhere((t) => t.slug == slug, orElse: () => defaultFormTemplates.first);
