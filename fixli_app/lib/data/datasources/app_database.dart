// lib/data/datasources/app_database.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get email => text().unique()();
  TextColumn get hashedPassword => text()();
  TextColumn get location => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get profilePicturePath => text().nullable()();
  TextColumn get bio => text().nullable()();
  // 🟢 NY KOLUMN: isAdmin
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
}

@DataClassName('Request')
class Requests extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get location => text()();
  TextColumn get price => text()();
  IntColumn get uploadedBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get isSponsored => boolean().withDefault(const Constant(false))();
  TextColumn get contactPreference => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get fixerId => integer().nullable().references(Users, #id)();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Ad')
class SponsoredAds extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get city => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  TextColumn get category => text().withDefault(const Constant('Övrigt'))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  // 🟢 NY KOLUMN FÖR FÖRETAGSLOGOTYP
  TextColumn get logoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 🟢 NY TABELL FÖR NYHETSARTIKLAR
@DataClassName('NewsArticle')
class NewsArticles extends Table {
  TextColumn get id => text()(); // Unikt ID för artikeln
  TextColumn get title => text()();
  TextColumn get content => text()(); // Brödtexten för nyheten
  TextColumn get imageUrl => text().nullable()(); // URL till en eventuell bild
  IntColumn get authorId => integer().references(Users, #id)(); // Vem som skapade artikeln
  DateTimeColumn get createdAt => dateTime()(); // När den skapades
  DateTimeColumn get updatedAt => dateTime().nullable()(); // När den senast uppdaterades

  @override
  Set<Column> get primaryKey => {id};
}


@DataClassName('Rating')
class Ratings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(Requests, #id)();
  IntColumn get ratingValue => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get ratedUserId => integer().references(Users, #id)();
  IntColumn get raterUserId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('JobApplication')
class JobApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(Requests, #id)();
  IntColumn get applicantId => integer().references(Users, #id)();
  TextColumn get message => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('Notification')
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get requestId => text().nullable().references(Requests, #id)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [
  Users,
  Requests,
  SponsoredAds,
  Ratings,
  JobApplications,
  Notifications,
  NewsArticles // 🟢 NY TABELL TILLAGD HÄR
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 14; // 🟢 VIKTIGT: ÖKA VERSIONEN TILL 14

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) { await migrator.createTable(sponsoredAds); }
      if (from < 3) { await migrator.addColumn(requests, requests.contactPreference); }
      if (from < 4) { await migrator.addColumn(requests, requests.imagePath); }
      if (from < 5) {
        await migrator.addColumn(requests, requests.status);
        await migrator.addColumn(requests, requests.fixerId);
        await migrator.createTable(ratings);
      }
      if (from < 6) {
        await migrator.createTable(jobApplications);
      }
      if (from < 7) {
        await migrator.addColumn(sponsoredAds, sponsoredAds.category);
      }
      if (from < 8) {
        await migrator.addColumn(requests, requests.latitude);
        await migrator.addColumn(requests, requests.longitude);
      }
      if (from < 9) {
        await migrator.addColumn(users, users.profilePicturePath);
        await migrator.addColumn(users, users.bio);
      }
      if (from < 10) {
        await migrator.createTable(notifications);
      }
      if (from < 11) {
        await migrator.addColumn(sponsoredAds, sponsoredAds.latitude);
        await migrator.addColumn(sponsoredAds, sponsoredAds.longitude);
      }
      if (from < 12) {
        await migrator.addColumn(sponsoredAds, sponsoredAds.logoPath);
      }
      // 🟢 NY MIGRATIONS-LOGIK FÖR isAdmin i Users
      if (from < 13) {
        await migrator.addColumn(users, users.isAdmin);
      }
      // 🟢 NY MIGRATIONS-LOGIK FÖR NewsArticles-tabellen
      if (from < 14) {
        await migrator.createTable(newsArticles);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fixli_db.sqlite'));
    return NativeDatabase(file);
  });
}