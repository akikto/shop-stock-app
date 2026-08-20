import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'sync_database.g.dart';

class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get salePrice => real()();
  RealColumn get currentStock => real()();
  RealColumn get lowStockLimit => real()();
  BoolColumn get isActive => boolean()();
  TextColumn get photoThumbUrl => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PendingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceTxnId => text().unique()();
  TextColumn get type => text()();
  TextColumn get productId => text()();
  RealColumn get quantity => real().nullable()();
  RealColumn get quantityChange => real().nullable()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get lastProductSyncAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
}

@DriftDatabase(tables: [CachedProducts, PendingTransactions, SyncMetadata])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase(QueryExecutor executor) : super(executor);

  SyncDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static Future<SyncDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'shop_stock_sync.db'));
    return SyncDatabase(NativeDatabase(file));
  }
}
