import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  })
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

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
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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

    batch.set(deviceRef, {
      'created_at': now,
      'placeholder': true,
    });
    batch.set(sensorRef, {
      'created_at': now,
      'placeholder': true,
    });
    batch.set(readingRef, {
      'created_at': now,
      'placeholder': true,
    });

    await batch.commit();
  }
}
