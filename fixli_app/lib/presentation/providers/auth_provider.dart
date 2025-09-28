// lib/presentation/providers/auth_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:fixli_app/data/models/user_model.dart';
import 'package:fixli_app/data/repositories/auth_repository.dart';
import 'package:fixli_app/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'activeUserId';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository = locator<AuthRepository>();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_prefsKey);

    if (userId != null) {
      final user = await _authRepository.getUserById(userId);
      if (user != null) {
        state = AuthState(user: user, isLoading: false);
      } else {
        await prefs.remove(_prefsKey);
        state = AuthState(isLoading: false);
      }
    } else {
      state = AuthState(isLoading: false);
    }
  }

  Future<void> login(String emailOrName, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authRepository.login(emailOrName, password);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsKey, user.id);
        state = AuthState(user: user);
      } else {
        state = AuthState(error: 'Felaktigt användarnamn eller lösenord.');
      }
    } catch (e) {
      state = AuthState(error: 'Ett oväntat fel uppstod: $e');
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? location,
    String? phone,
    String? bio,
    File? imageFile,
  }) async {
    state = AuthState(isLoading: true);
    if (await _authRepository.isNameTaken(name)) {
      state = AuthState(error: 'Användarnamnet är redan upptaget.');
      return false;
    }
    if (await _authRepository.isEmailTaken(email)) {
      state = AuthState(error: 'E-postadressen är redan registrerad.');
      return false;
    }

    try {
      // 🟢 KORRIGERING: Skickar nu vidare bio och imageFile till repositoryt
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        location: location,
        phone: phone,
        bio: bio,
        imageFile: imageFile,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, user.id);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      state = AuthState(error: 'Kunde inte registrera: $e');
      return false;
    }
  }

  void updateUserState(UserModel updatedUser) {
    state = AuthState(user: updatedUser);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});