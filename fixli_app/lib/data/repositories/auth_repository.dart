// lib/data/repositories/auth_repository.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/models/user_model.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  final AppDatabase _db;
  AuthRepository(this._db);

  Future<UserModel?> login(String emailOrName, String password) async {
    final lowerIdentifier = emailOrName.toLowerCase();
    final userEntity = await (_db.select(_db.users)..where((u) => u.email.equals(lowerIdentifier) | u.name.equals(lowerIdentifier))).getSingleOrNull();
    if (userEntity == null) return null;
    final bool passwordMatch = BCrypt.checkpw(password, userEntity.hashedPassword);
    if (passwordMatch) {
      return UserModel(
        id: userEntity.id,
        name: userEntity.name,
        email: userEntity.email,
        location: userEntity.location,
        phone: userEntity.phone,
        profilePicturePath: userEntity.profilePicturePath,
        bio: userEntity.bio,
      );
    }
    return null;
  }

  // 🟢 Uppdaterad med nya parametrar för bio och bild
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? location,
    String? phone,
    String? bio,
    File? imageFile,
  }) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    String? finalImagePath;
    if (imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(imageFile.path);
      final newFileName = 'profile_${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await imageFile.copy(newPath);
      finalImagePath = newFile.path;
    }

    final userCompanion = UsersCompanion.insert(
      name: name,
      email: email,
      hashedPassword: hashedPassword,
      location: Value(location),
      phone: Value(phone),
      bio: Value(bio),
      profilePicturePath: Value(finalImagePath),
    );
    final newId = await _db.into(_db.users).insert(userCompanion);

    return UserModel(
      id: newId,
      name: name,
      email: email,
      location: location,
      phone: phone,
      bio: bio,
      profilePicturePath: finalImagePath,
    );
  }

  Future<void> changePassword({required int userId, required String newPassword}) async {
    final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    final companion = UsersCompanion(hashedPassword: Value(hashedPassword));
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(companion);
  }

  Future<UserModel> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    required String newLocation,
    required String newPhone,
    required String newBio,
    File? newProfilePictureFile,
    String? existingProfilePicturePath,
  }) async {
    String? finalImagePath = existingProfilePicturePath;

    if (newProfilePictureFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(newProfilePictureFile.path);
      final newFileName = 'profile_${const Uuid().v4()}$fileExtension';
      final newPath = p.join(directory.path, newFileName);
      final newFile = await newProfilePictureFile.copy(newPath);
      finalImagePath = newFile.path;
    }

    final companion = UsersCompanion(
      location: Value(newLocation),
      phone: Value(newPhone),
      bio: Value(newBio),
      profilePicturePath: Value(finalImagePath),
    );
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(companion);

    return UserModel(
      id: userId,
      name: name,
      email: email,
      location: newLocation,
      phone: newPhone,
      bio: newBio,
      profilePicturePath: finalImagePath,
    );
  }

  Future<bool> isEmailTaken(String email) async {
    final existing = await (_db.select(_db.users)..where((u) => u.email.equals(email.toLowerCase()))).getSingleOrNull();
    return existing != null;
  }

  Future<bool> isNameTaken(String name) async {
    final existing = await (_db.select(_db.users)..where((u) => u.name.equals(name.toLowerCase()))).getSingleOrNull();
    return existing != null;
  }

  Future<List<User>> getAllUsers() async {
    return _db.select(_db.users).get();
  }

  Future<UserModel?> getUserById(int id) async {
    final userEntity = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
    if (userEntity != null) {
      return UserModel(
        id: userEntity.id,
        name: userEntity.name,
        email: userEntity.email,
        location: userEntity.location,
        phone: userEntity.phone,
        profilePicturePath: userEntity.profilePicturePath,
        bio: userEntity.bio,
      );
    }
    return null;
  }
}