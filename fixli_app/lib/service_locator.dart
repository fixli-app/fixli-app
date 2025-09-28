// lib/service_locator.dart
import 'package:fixli_app/data/datasources/app_database.dart';
import 'package:fixli_app/data/repositories/ad_repository.dart';
import 'package:fixli_app/data/repositories/auth_repository.dart';
import 'package:fixli_app/data/repositories/job_application_repository.dart';
import 'package:fixli_app/data/repositories/notification_repository.dart';
import 'package:fixli_app/data/repositories/rating_repository.dart';
import 'package:fixli_app/data/repositories/request_repository.dart';
import 'package:fixli_app/data/repositories/news_repository.dart'; // 🟢 NY IMPORT
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<AppDatabase>(AppDatabase());
  locator.registerLazySingleton(() => AuthRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => RequestRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => AdRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => RatingRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => JobApplicationRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => NotificationRepository(locator<AppDatabase>()));
  locator.registerLazySingleton(() => NewsRepository(locator<AppDatabase>())); // 🟢 NY REGISTRERING FÖR NEWSREPOSITORY
}