import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:csahati_desktop/constants/app_constants.dart';
import 'package:csahati_desktop/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String _deviceId = '';
  Future<String> get deviceId async {
    if (_deviceId.isNotEmpty) return _deviceId;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(deviceIdKey) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';
      await prefs.setString(deviceIdKey, _deviceId);
    }
    return _deviceId;
  }

  Future<Map<String, String>> rememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(rememberLoginKey) != '1') return {};
    return {
      'country_code': prefs.getString(rememberCountryKey) ?? '966',
      'phone': prefs.getString(rememberPhoneKey) ?? '',
      'password': prefs.getString(rememberPasswordKey) ?? '',
    };
  }

  Future<void> saveRemembered(String country, String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final cc = _normalizeCountry(country);
    await prefs.setString(rememberLoginKey, '1');
    await prefs.setString(rememberCountryKey, cc);
    await prefs.setString(rememberPhoneKey, _normalizePhone(cc, phone));
    await prefs.setString(rememberPasswordKey, password);
  }

  Future<void> clearRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(rememberLoginKey);
    await prefs.remove(rememberCountryKey);
    await prefs.remove(rememberPhoneKey);
    await prefs.remove(rememberPasswordKey);
  }

  Future<AppBootstrap> login(String countryCode, String phone, String password, {bool remember = false}) async {
    final cc = _normalizeCountry(countryCode);
    final ph = _normalizePhone(cc, phone);
    final data = jsonEncode({
      'country_code': cc, 'phone': ph, 'password': password,
      'remember': remember, 'remember_me': remember,
      'allow_multi_device': true, 'device_id': await deviceId,
    });
    Object? lastErr;
    for (final base in loginApiBaseCandidates) {
      try {
        final resp = await http.post(Uri.parse('$base/app/login'),
          headers: {'Content-Type': 'application/json'},
          body: data,
        ).timeout(const Duration(seconds: 12));
        final payload = jsonDecode(resp.body) as Map<String, dynamic>;
        if (payload['ok'] == true) return AppBootstrap.fromJson(payload);
        lastErr = payload['error'] ?? 'تعذر تسجيل الدخول';
      } catch (e) {
        lastErr = e;
      }
    }
    throw Exception(lastErr?.toString() ?? 'تعذر تسجيل الدخول');
  }

  Future<AppBootstrap> fetchBootstrap() async {
    final resp = await http.get(Uri.parse('$apiBase/app/bootstrap'));
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true) throw Exception(payload['error'] ?? 'تعذر تحميل الإعدادات');
    return AppBootstrap.fromJson(payload);
  }

  Future<List<FileRecord>> fetchDocuments() async {
    final resp = await http.get(Uri.parse('$apiBase/documents'));
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true) throw Exception(payload['error'] ?? 'تعذر تحميل الملفات');
    final items = payload['items'] is List ? payload['items'] as List : const [];
    return items
        .whereType<Map>()
        .map((i) => FileRecord.fromApi(Map<String, dynamic>.from(i)))
        .where((f) => runtimeTemplates.containsKey(f.templateSlug) || _officialKinds().contains(f.type))
        .toList();
  }

  Future<List<FormTemplate>> fetchTemplates() async {
    final resp = await http.get(Uri.parse(registryUrl));
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    final reg = payload['registry'] is Map ? Map<String, dynamic>.from(payload['registry'] as Map) : <String, dynamic>{};
    final forms = reg['forms'] is List ? reg['forms'] as List : const [];
    final templates = forms
        .whereType<Map>()
        .map((i) => FormTemplate.fromJson(Map<String, dynamic>.from(i)))
        .where((t) => t.slug.isNotEmpty && t.previewUrl.isNotEmpty && t.active && t.status == 'approved')
        .toList();
    if (templates.isEmpty) return defaultFormTemplates;
    runtimeTemplates..clear()..addEntries(templates.map((t) => MapEntry(t.slug, t)));
    return templates;
  }

  Future<FileRecord> createDocument(FormTemplate template, String client, Map<String, String> values, {FileRecord? existing}) async {
    final type = template.kind;
    final fields = _fieldsForApi(type, values);
    if (template.barcodeUrl.trim().isNotEmpty) {
      fields['barcode_url'] = template.barcodeUrl.trim();
      fields['verification_url'] = template.barcodeUrl.trim();
    }
    if (template.checkUrl.trim().isNotEmpty) {
      fields['check_url'] = template.checkUrl.trim();
    }
    final personName = _firstValue(fields, ['name_ar', 'driver_name_ar', 'organization_name_ar', 'name']) ?? 'مستند بدون اسم';
    final body = jsonEncode({
      'document_type_slug': template.slug, 'type_label': template.title,
      'person_name': personName,
      'person_key': existing?.personKey ?? _firstValue(fields, ['identity_number', 'driver_identity_number', 'national_id']) ?? '',
      'document_date': fields['document_date'] ?? fields['issue_date'] ?? fields['leave_from_greg'] ?? todayDate(),
      'fields_data': fields, 'app_user': 'كعبيلان', 'client_name': client,
      'notes': fields['notes']?.isNotEmpty == true ? fields['notes'] : 'لا توجد ملاحظات', 'status': 'ready',
    });
    final resp = await http.post(Uri.parse('$apiBase/documents'),
      headers: {'Content-Type': 'application/json'}, body: body);
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true) throw Exception(payload['error'] ?? 'تعذر حفظ الملف');
    final id = _asInt(payload['id']);
    if (id == null) throw Exception('تم الحفظ لكن لم يرجع معرف الملف.');
    final getResp = await http.get(Uri.parse('$apiBase/documents/$id'));
    final getPayload = jsonDecode(getResp.body) as Map<String, dynamic>;
    if (getPayload['ok'] == true && getPayload['document'] is Map) {
      return FileRecord.fromApi(Map<String, dynamic>.from(getPayload['document'] as Map));
    }
    return FileRecord(id: id, name: personName, date: todayDate(), type: type, templateSlug: template.slug,
      personKey: existing?.personKey ?? '', user: 'كعبيلان', client: client,
      values: fields, htmlUrl: (payload['html_url'] ?? '').toString(), pdfUrl: (payload['pdf_url'] ?? '').toString());
  }

  Future<AppUser> createUser(String name, String cc, String phone, String password, bool isAgent, bool active, {String notes = ''}) async {
    final resp = await http.post(Uri.parse('$apiBase/app/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'country_code': cc, 'phone': phone, 'password': password, 'is_agent': isAgent, 'active': active, 'notes': notes, 'created_by': 'كعبيلان'}));
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true || payload['user'] is! Map) throw Exception(payload['error'] ?? 'تعذر إضافة المستخدم');
    return AppUser.fromJson(Map<String, dynamic>.from(payload['user'] as Map));
  }

  Future<AppUser> updateUser(AppUser user, {bool? active, bool? isAgent}) async {
    final resp = await http.patch(Uri.parse('$apiBase/app/users/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({if (active != null) 'active': active, if (isAgent != null) 'is_agent': isAgent}));
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true || payload['user'] is! Map) throw Exception(payload['error'] ?? 'تعذر تحديث المستخدم');
    return AppUser.fromJson(Map<String, dynamic>.from(payload['user'] as Map));
  }

  Future<String> uploadFile(String filePath, String folder) async {
    final req = http.MultipartRequest('POST', Uri.parse('$apiBase/uploads/media'));
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    req.fields['folder'] = folder;
    final stream = await req.send();
    final resp = await http.Response.fromStream(stream);
    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    if (payload['ok'] != true || payload['file'] is! Map) throw Exception(payload['error'] ?? 'تعذر رفع الملف');
    final saved = Map<String, dynamic>.from(payload['file'] as Map);
    final url = (saved['url'] ?? '').toString();
    if (url.isEmpty) throw Exception('لم يرجع رابط صالح.');
    return url;
  }

  String documentPdfUrl(FileRecord file, {int fileIndex = 1}) {
    if (file.id != null) return '$apiBase/documents/${file.id}/render?format=pdf&file=$fileIndex';
    return _absDeskUrl(file.pdfUrl);
  }

  String documentThumbnailUrl(FileRecord file, {int fileIndex = 1}) {
    if (file.id != null) return '$apiBase/documents/${file.id}/render?format=thumbnail&file=$fileIndex';
    return documentPdfUrl(file, fileIndex: fileIndex);
  }
}

List<TemplateKind> _officialKinds() => [
  TemplateKind.sickLeave, TemplateKind.driverCard1, TemplateKind.driverCard2,
  TemplateKind.healthAnnual, TemplateKind.healthFoodDelivery, TemplateKind.healthRiyadh, TemplateKind.healthSeasonal,
  TemplateKind.operationCard1, TemplateKind.operationCard2,
];

String _normalizeCountry(String v) {
  var d = digitsOnly(v);
  while (d.startsWith('00')) d = d.substring(2);
  while (d.startsWith('0') && d.length > 1) d = d.substring(1);
  return d.isEmpty ? '966' : d;
}

String _normalizePhone(String cc, String v) {
  var d = digitsOnly(v);
  if (d.startsWith('00$cc')) d = d.substring(cc.length + 2);
  else if (d.startsWith(cc) && d.length > cc.length) d = d.substring(cc.length);
  if (cc == '966' && d.startsWith('0') && d.length > 1) d = d.substring(1);
  return d;
}

Map<String, String> _fieldsForApi(TemplateKind type, Map<String, String> values) {
  final f = Map<String, String>.from(values);
  switch (type) {
    case TemplateKind.sickLeave:
      f['leaveDays'] ??= f['leave_days'] ?? '1';
      f['leave_sector'] ??= f['sector_type'] ?? 'حكومي';
      if ((f['leave_id'] ?? '').trim().isEmpty) f['leave_id'] = randomSickLeaveId(f['leave_sector'] ?? 'حكومي');
      f['admissionDate'] ??= f['leave_from_greg'] ?? todayDate();
      f['dischargeDate'] ??= f['discharge_date'] ?? f['admissionDate'] ?? todayDate();
      f['issueDate'] ??= f['leave_from_greg'] ?? todayDate();
      f['issue_date_greg'] ??= f['issueDate'] ?? todayDate();
      f['practitioner_ar'] ??= f['doctor_ar'] ?? '';
      f['practitioner_en'] ??= f['doctor_en'] ?? '';
      f['position'] ??= f['position_ar'] ?? '';
      f['positionEnglish'] ??= f['position_en'] ?? '';
      f['hospital'] ??= f['hospital_ar'] ?? '';
      f['hospitalEnglish'] ??= f['hospital_en'] ?? '';
      break;
    case TemplateKind.driverCard1:
    case TemplateKind.driverCard2:
      f['organization_name_ar'] ??= f['sponsor_name_ar'] ?? f['name_ar'] ?? '';
      f['organization_name_en'] ??= f['sponsor_name_en'] ?? f['name_en'] ?? '';
      f['driver_identity_number'] ??= f['driver_id'] ?? f['identity_number'] ?? '';
      f['activity_type'] ??= f['transport_type'] ?? 'نقل ثقيل';
      f['card_category'] ??= f['period'] ?? 'سنويه';
      f['renewal_type'] ??= f['request_type'] ?? 'تجديد';
      f['card_issue_date'] ??= f['issue_date'] ?? todayDate();
      f['card_expiry_date'] ??= f['expiry_date'] ?? '';
      break;
    case TemplateKind.operationCard1:
    case TemplateKind.operationCard2:
      f['organization_name_ar'] ??= f['name_ar'] ?? '';
      f['organization_name_en'] ??= f['name_en'] ?? '';
      f['activity_type'] ??= f['transport_type'] ?? 'نقل ثقيل';
      f['card_issue_date'] ??= f['issue_date'] ?? todayDate();
      f['card_expiry_date'] ??= f['expiry_date'] ?? '';
      f['card_renew_date'] ??= f['renew_date'] ?? '';
      break;
    case TemplateKind.healthAnnual: f['certificate_type'] = 'annual'; break;
    case TemplateKind.healthFoodDelivery: f['certificate_type'] = 'food_delivery'; break;
    case TemplateKind.healthRiyadh: f['certificate_type'] = 'riyadh'; break;
    case TemplateKind.healthSeasonal: f['certificate_type'] = 'seasonal'; break;
  }
  return f;
}

String? _firstValue(Map<String, String> map, List<String> keys) {
  for (final k in keys) { if (map[k]?.isNotEmpty == true) return map[k]; }
  return null;
}

String _absDeskUrl(String url) {
  if (url.startsWith('http') || url.startsWith('blob:')) return url;
  if (url.startsWith('/')) return 'https://desk.almaktb2.37.60.235.208.sslip.io$url';
  return url;
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse((v ?? '').toString());
}
