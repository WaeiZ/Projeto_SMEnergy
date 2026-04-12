import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'pages/add_equipment_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final SessionStateService _sessionStateService = FirebaseSessionStateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_pushNotificationService.initialize());
    });
  }

  @override
  void dispose() {
    _pushNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMEnergy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Open Sans',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF1D7EF8),
          onPrimary: Colors.white,
          secondary: const Color(0xFF3DA5FA),
          onSecondary: Colors.white,
          surface: const Color(0xFFE3F0FE),
          onSurface: const Color(0xFF49454F),
          error: const Color(0xFFDB3918),
          onError: Colors.white,
          outline: const Color(0xFF3DA5FA).withValues(alpha: 0.5),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AppEntryPoint(sessionStateService: _sessionStateService),
    );
  }
}

abstract class SessionStateService {
  bool get isSignedIn;

  Stream<bool> authChanges();

  Future<bool> hasEquipmentForCurrentUser();
}

class FirebaseSessionStateService implements SessionStateService {
  FirebaseSessionStateService({
    FirebaseAuth? auth,
    AuthServiceBase? authService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _authService = authService ?? AuthService();

  final FirebaseAuth _auth;
  final AuthServiceBase _authService;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Stream<bool> authChanges() =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  Future<bool> hasEquipmentForCurrentUser() =>
      _authService.hasEquipmentForCurrentUser();
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({
    super.key,
    required this.sessionStateService,
    this.loginPageBuilder,
    this.dashboardPageBuilder,
    this.addEquipmentPageBuilder,
  });

  final SessionStateService sessionStateService;
  final WidgetBuilder? loginPageBuilder;
  final WidgetBuilder? dashboardPageBuilder;
  final WidgetBuilder? addEquipmentPageBuilder;

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  StreamSubscription<bool>? _authSubscription;
  bool _isSignedIn = false;
  bool _isCheckingEquipment = false;
  bool _hasEquipment = false;

  @override
  void initState() {
    super.initState();
    _isSignedIn = widget.sessionStateService.isSignedIn;
    _authSubscription = widget.sessionStateService.authChanges().listen(
      _handleAuthChanged,
    );
    unawaited(_handleAuthChanged(_isSignedIn));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthChanged(bool isSignedIn) async {
    if (!mounted) return;

    if (!isSignedIn) {
      setState(() {
        _isSignedIn = false;
        _isCheckingEquipment = false;
        _hasEquipment = false;
      });
      return;
    }

    setState(() {
      _isSignedIn = true;
      _isCheckingEquipment = true;
    });

    bool hasEquipment = false;
    try {
      hasEquipment = await widget.sessionStateService
          .hasEquipmentForCurrentUser();
    } catch (_) {
      hasEquipment = false;
    }

    if (!mounted || !_isSignedIn) return;

    setState(() {
      _hasEquipment = hasEquipment;
      _isCheckingEquipment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedIn) {
      final builder = widget.loginPageBuilder ?? (_) => const LoginPage();
      return builder(context);
    }

    if (_isCheckingEquipment) {
      return const _StartupLoadingScreen();
    }

    final builder =
        _hasEquipment
            ? (widget.dashboardPageBuilder ?? (_) => const DashboardPage())
            : (widget.addEquipmentPageBuilder ??
                (_) => const AddEquipmentPage());
    return builder(context);
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
