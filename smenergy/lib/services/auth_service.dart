import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;
  static const Set<String> _hasEquipmentBypassEmails = {
    'sergiomica14@gmail.com',
  };

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Falha ao criar o utilizador.');
    }

    await user.updateDisplayName(name);
    await _createUserStructure(uid: user.uid, name: name, email: email);

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('CANCELLED');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Falha ao autenticar com Google.');
    }

    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNewUser) {
      final name = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (googleUser.displayName?.trim().isNotEmpty == true
                ? googleUser.displayName!.trim()
                : 'Utilizador');
      final email = user.email ?? googleUser.email;
      await _createUserStructure(uid: user.uid, name: name, email: email);
    }

    return userCredential;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserName({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilizador não autenticado.');
    }

    await user.updateDisplayName(name);
    await _db.collection('users').doc(user.uid).set({
      'name': name,
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccountAndData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilizador não autenticado.');
    }

    await _deleteUserData(user.uid);
    await user.delete();
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _deleteUserData(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    final devicesSnapshot = await userRef.collection('devices').get();
    for (final deviceDoc in devicesSnapshot.docs) {
      final sensorsRef = deviceDoc.reference.collection('sensors');
      final sensorsSnapshot = await sensorsRef.get();
      for (final sensorDoc in sensorsSnapshot.docs) {
        await _deleteCollection(sensorDoc.reference.collection('readings'));
      }
      await _deleteCollection(sensorsRef);
    }

    await _deleteCollection(userRef.collection('devices'));
    await userRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection, {
    int batchSize = 100,
  }) async {
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) {
        break;
      }
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> enrollPhoneMfa({
    required String phoneNumber,
    required Future<String?> Function() getSmsCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilizador não autenticado.');
    }

    if (user.email != null && !user.emailVerified) {
      // Email verification is recommended but not required for SMS MFA enrollment.
      await user.sendEmailVerification();
    }

    final session = await user.multiFactor.getSession();
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      multiFactorSession: session,
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await user.multiFactor.enroll(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        final smsCode = await getSmsCode();
        if (smsCode == null) {
          if (!completer.isCompleted) {
            completer.completeError(StateError('CANCELLED'));
          }
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        try {
          await user.multiFactor.enroll(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    await completer.future;
  }

  Future<UserCredential> resolveSignInWithSmsMfa({
    required FirebaseAuthMultiFactorException exception,
    required Future<String?> Function() getSmsCode,
  }) async {
    final hint = exception.resolver.hints.first;
    if (hint is! PhoneMultiFactorInfo) {
      throw StateError('Segundo fator não suportado.');
    }

    final completer = Completer<UserCredential>();

    await _auth.verifyPhoneNumber(
      multiFactorSession: exception.resolver.session,
      multiFactorInfo: hint,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await exception.resolver.resolveSignIn(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        final smsCode = await getSmsCode();
        if (smsCode == null) {
          if (!completer.isCompleted) {
            completer.completeError(StateError('CANCELLED'));
          }
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        try {
          final result = await exception.resolver.resolveSignIn(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<bool> hasEquipmentForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final normalizedEmail = user.email?.trim().toLowerCase();
    if (normalizedEmail != null &&
        _hasEquipmentBypassEmails.contains(normalizedEmail)) {
      return true;
    }

    final devicesSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .get();

    for (final doc in devicesSnapshot.docs) {
      final data = doc.data();
      final placeholder = data['placeholder'] == true;
      if (doc.id != '_meta' && !placeholder) {
        return true;
      }
    }
    return false;
  }

  Future<void> _createUserStructure({
    required String uid,
    required String name,
    required String email,
  }) async {
    final now = FieldValue.serverTimestamp();
    final userRef = _db.collection('users').doc(uid);

    final batch = _db.batch();

    batch.set(userRef, {
      'uid': uid,
      'name': name,
      'email': email,
      'points': 0,
      'created_at': now,
    });

    // Placeholder docs to materialize nested subcollections in the console.
    final deviceRef = userRef.collection('devices').doc('_meta');
    final sensorRef = deviceRef.collection('sensors').doc('_meta');
    final readingRef = sensorRef.collection('readings').doc('_meta');

    batch.set(deviceRef, {'created_at': now, 'placeholder': true});
    batch.set(sensorRef, {'created_at': now, 'placeholder': true});
    batch.set(readingRef, {'created_at': now, 'placeholder': true});

    await batch.commit();
  }
}
