// lib/data/models/request_model.dart

import 'package:equatable/equatable.dart';

class RequestModel extends Equatable {
  final String id;
  final String title;
  final String? body;
  final String location;
  final String price;
  final int uploadedBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isSponsored;

  const RequestModel({
    required this.id,
    required this.title,
    this.body,
    required this.location,
    required this.price,
    required this.uploadedBy,
    required this.createdAt,
    required this.expiresAt,
    required this.isSponsored,
  });

  @override
  List<Object?> get props => [id, title, body, location, price, uploadedBy, createdAt, expiresAt, isSponsored];
}