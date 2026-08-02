import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:csahati_desktop/constants/app_constants.dart';
import 'package:csahati_desktop/models.dart';
import 'package:csahati_desktop/services/api_service.dart';
import 'package:csahati_desktop/screens.dart';

final _api = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(900, 600));
    await windowManager.setSize(const Size(1280, 800));
    await windowManager.center();
    await windowManager.setTitle('صحتي - التطبيق');
  }

  runApp(const CsahatiApp());
}

class CsahatiApp extends StatelessWidget {
  const CsahatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'صحتي - التطبيق',
      theme: ThemeData(
        scaffoldBackgroundColor: appCanvas,
        fontFamily: 'Arial',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: appBlue),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppScreen _screen = AppScreen.list;
  FormTemplate _selectedTemplate = defaultFormTemplates[4];
  String _selectedClient = 'طوارئ';
  FileRecord? _activeFile;
  MenuPage _activeMenuPage = MenuPage.reports;
  bool _loadingFiles = true;
  bool _authenticated = false;
  bool _agentEnabled = false;
  String _walletBalance = '0';
  int _totalAdditions = 0;
  AppUser? _currentUser;
  List<AppUser> _users = const [];
  List<FormTemplate> _templates = List<FormTemplate>.from(defaultFormTemplates);
  List<FileRecord> _files = [];


  @override
  void initState() {
    super.initState();
    _tryRestoreLogin();
  }

  Future<void> _tryRestoreLogin() async {
    final remembered = await _api.rememberedLogin();
    final password = remembered['password'] ?? '';
    if (password.isEmpty) {
      if (mounted) setState(() => _loadingFiles = false);
      return;
    }
    try {
      final bootstrap = await _api.login(remembered['country_code'] ?? '966', remembered['phone'] ?? '', password, remember: true);
      if (!mounted) return;
      _applyBootstrap(bootstrap);
      await _loadData();
    } catch (_) {
      if (mounted) setState(() => _loadingFiles = false);
    }
  }

  void _applyBootstrap(AppBootstrap bootstrap) {
    setState(() {
      _authenticated = true;
      _currentUser = bootstrap.currentUser;
      _users = bootstrap.users;
      _agentEnabled = bootstrap.agentEnabled;
      _walletBalance = bootstrap.walletBalance;
      _totalAdditions = bootstrap.totalAdditions;
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.fetchTemplates(),
        _api.fetchDocuments(),
        _api.fetchBootstrap(),
      ]);
      if (!mounted) return;
      setState(() {
        _templates = results[0] as List<FormTemplate>;
        _files = results[1] as List<FileRecord>;
        final fresh = results[2] as AppBootstrap;
        _currentUser = fresh.currentUser;
        _users = fresh.users;
        _agentEnabled = fresh.agentEnabled;
        _walletBalance = fresh.walletBalance;
        _totalAdditions = fresh.totalAdditions;
        _loadingFiles = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFiles = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e'), backgroundColor: appRed));
      }
    }
  }

  void _handleLogin(AppBootstrap bootstrap) {
    _applyBootstrap(bootstrap);
    _loadData();
  }

  void _handleLogout() {
    _api.clearRemembered();
    setState(() {
      _authenticated = false;
      _screen = AppScreen.list;
      _files = [];
      _loadingFiles = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return LoginScreen(onLoginSuccess: _handleLogin);
    }

    if (_loadingFiles) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: appBlue)));
    }

    switch (_screen) {
      case AppScreen.list:
        return FilesScreen(
          bootstrap: AppBootstrap(currentUser: _currentUser, users: _users, agentEnabled: _agentEnabled, walletBalance: _walletBalance, totalAdditions: _totalAdditions),
          templates: _templates,
          files: _files,
          onAdd: () {
            setState(() {
              _selectedTemplate = _templates.isNotEmpty ? _templates[4] : defaultFormTemplates[4];
              _selectedClient = 'طوارئ';
              _activeFile = null;
              _screen = AppScreen.form;
            });
          },
          onEdit: (file) {
            setState(() {
              _selectedTemplate = templateForSlug(file.templateSlug);
              _selectedClient = file.client;
              _activeFile = file;
              _screen = AppScreen.form;
            });
          },
          onView: (file) {
            setState(() { _activeFile = file; _screen = AppScreen.preview; });
          },
          onLogout: _handleLogout,
          onMenuPage: (page) {
            setState(() { _activeMenuPage = page; _screen = AppScreen.menuPage; });
          },
        );
      case AppScreen.form:
        return FormScreen(
          template: _selectedTemplate,
          client: _selectedClient,
          existingFile: _activeFile,
          onSaved: (file) {
            setState(() {
              final idx = _files.indexWhere((f) => f.id == file.id || f.name == file.name);
              if (idx >= 0) {
                _files[idx] = file;
              } else {
                _files.insert(0, file);
              }
              _activeFile = file;
              _screen = AppScreen.preview;
            });
          },
          onBack: () => setState(() => _screen = AppScreen.list),
        );
      case AppScreen.preview:
        return PreviewScreen(
          file: _activeFile!,
          onBack: () => setState(() => _screen = AppScreen.list),
        );
      case AppScreen.menuPage:
        return MenuPageScreen(
          page: _activeMenuPage,
          bootstrap: AppBootstrap(currentUser: _currentUser, users: _users, agentEnabled: _agentEnabled, walletBalance: _walletBalance, totalAdditions: _totalAdditions),
          templates: _templates,
          onBack: () => setState(() => _screen = AppScreen.list),
          onTemplateSelected: (template) => setState(() {
            _selectedTemplate = template;
            _selectedClient = 'طوارئ';
            _activeFile = null;
            _screen = AppScreen.form;
          }),
        );
    }
  }
}
