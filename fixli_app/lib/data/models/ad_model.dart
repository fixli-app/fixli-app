// lib/data/models/ad_model.dart

import 'package:equatable/equatable.dart';

class AdModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String city;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime expiresAt;

  const AdModel({
    required this.id,
    required this.title,
    required this.body,
    required this.city,
    this.email,
    this.phone,
    required this.createdAt,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [id, title, body, city, email, phone, createdAt, expiresAt];
}