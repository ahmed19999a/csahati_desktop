import 'package:flutter/material.dart';

const apiOrigin = 'https://app.csahati.site';
const legacyDeskApiBase = 'https://desk.almaktb2.37.60.235.208.sslip.io/api/v1';
const registryUrl = 'https://mang.csahati.site/api.php?action=registry';
String get apiBase => legacyDeskApiBase;
List<String> get loginApiBaseCandidates => [legacyDeskApiBase];

const rememberLoginKey = 'csahati.remember_login';
const rememberCountryKey = 'csahati.login_country';
const rememberPhoneKey = 'csahati.login_phone';
const rememberPasswordKey = 'csahati.login_password';
const deviceIdKey = 'csahati.device_id';

const appBlue = Color(0xFF1387D8);
const appLightBlue = Color(0xFFEEF6FF);
const appCardLine = Color(0xFFBFE3FF);
const appCanvas = Color(0xFFFAFAFA);
const appRed = Color(0xFFEF4444);
