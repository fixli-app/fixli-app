// lib/data/models/user_model.dart

import 'package:equatable/equatable.dart';
import 'package:fixli_app/data/datasources/app_database.dart'; // Importera din Drift-genererade databas

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? location;
  final String? phone;
  final String? profilePicturePath;
  final String? bio;
  final bool isAdmin; // 🟢 NYTT FÄLT: isAdmin

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.location,
    this.phone,
    this.profilePicturePath,
    this.bio,
    this.isAdmin = false, // Sätt default till false
  });

  // 🟢 Factory-konstruktor för att skapa en UserModel från en Drift User entitet
  factory UserModel.fromDrift(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      location: user.location,
      phone: user.phone,
      profilePicturePath: user.profilePicturePath,
      bio: user.bio,
      isAdmin: user.isAdmin, // Använd isAdmin från Drift-entiteten
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? location,
    String? phone,
    String? profilePicturePath,
    String? bio,
    bool? isAdmin, // 🟢 Lägg till isAdmin här också
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      bio: bio ?? this.bio,
      isAdmin: isAdmin ?? this.isAdmin, // 🟢 Använd isAdmin här
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    location,
    phone,
    profilePicturePath,
    bio,
    isAdmin, // 🟢 Lägg till isAdmin i props
  ];
}