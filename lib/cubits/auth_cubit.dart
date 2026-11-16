import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:equatable/equatable.dart';
import '../models/developer_model.dart';
import '../services/firestore_service.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '635695574820-hebu74bedl2pdmtv2p77q8l7otpdui6h.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final FirestoreService _firestoreService = FirestoreService();

  AuthCubit() : super(const AuthInitial()) {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(const AuthLoading());
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(const Unauthenticated());
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        try {
          final existing = await _firestoreService.getDeveloperProfile(user.uid);
          if (existing == null) {
            await _firestoreService.saveDeveloperProfile(
              DeveloperModel(
                id: user.uid,
                name: user.displayName ?? 'Developer',
                email: user.email ?? '',
                githubUrl: '',
                avatarUrl: user.photoURL,
              ),
            );
          }
        } catch (e) {
          debugPrint("Firestore profile sync warning: $e");
        }
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      emit(const AuthLoading());
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        emit(Authenticated(credential.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Authentication failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      emit(const AuthLoading());
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        try {
          await _firestoreService.saveDeveloperProfile(
            DeveloperModel(
              id: user.uid,
              name: name.trim(),
              email: email.trim(),
              githubUrl: '',
            ),
          );
        } catch (e) {
          debugPrint("Firestore registration warning: $e");
        }
        emit(Authenticated(user));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Registration failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    emit(const Unauthenticated());
  }
}
