import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  PushNotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseMessaging? messaging,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenForCurrentUser(token);
    });
    await _handleAuthChanged(_auth.currentUser);
    _initialized = true;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _saveTokenForCurrentUser(token);
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final hasPoints = snapshot.data()?.containsKey('points') ?? false;
    await userRef.set({
      'uid': user.uid,
      'name': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Utilizador',
      'email': user.email ?? '',
      if (!hasPoints) 'points': 0,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final tokenRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('notification_tokens')
        .doc(token);

    await tokenRef.set({
      'token': token,
      'platform': 'mobile',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
