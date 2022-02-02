import 'package:database/src/domain/column_type.dart';
import 'package:database/src/domain/database_interface.dart';
import 'package:database/src/domain/sgbd_interface.dart';
import 'package:database/src/domain/tables_interface.dart';
import 'package:database/src/domain/type_column.dart';
import 'package:database/src/repository/sql_database.dart';

class DatabaseController implements DatabaseInterface {
  final int version;
  final bool offlineSync;
  final TablesInterface tables;

  late DatabaseInterface _db;

  DatabaseController({
    required this.version,
    required this.tables,
    this.offlineSync = true,
  }) {
    _db = SQLDatabase(
      offlineSync: offlineSync,
      version: version,
      tables: offlineSync
          ? tables.getTables.map((e) {
              List<ColumnTable> columns = e['columns'];
              columns.add(
                ColumnTable(
                  name: 'synced',
                  type: TypeColumn.text,
                ),
              );
              return e;
            }).toList()
          : tables.getTables,
    );
  }

  @override
  Future<void> init() {
    return _db.init();
  }

  @override
  Future<Map<String, dynamic>> createOrUpdate({
    required String table,
    required Map<String, dynamic> data,
    bool synced = false,
  }) {
    return _db.createOrUpdate(
      table: table,
      data: data,
      synced: synced,
    );
  }

  @override
  Future<Map<String, dynamic>?> getByColumn({
    required String table,
    required String column,
    required dynamic value,
    String? orderBy,
  }) {
    return _db.getByColumn(
      table: table,
      column: column,
      value: value,
      orderBy: orderBy,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> list({
    required String table,
    String? where,
    List<dynamic>? args,
    int? limit,
    int? page,
    String? orderBy,
  }) {
    return _db.list(
      table: table,
      where: where,
      args: args,
      limit: limit,
      page: page,
      orderBy: orderBy,
    );
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required String column,
    required dynamic value,
    required Map<String, dynamic> data,
    bool synced = false,
  }) {
    return _db.update(
      table: table,
      column: column,
      value: value,
      data: data,
      synced: synced,
    );
  }

  @override
  Future<bool> delete({
    required String table,
    required String column,
    required dynamic value,
  }) {
    return _db.delete(
      table: table,
      column: column,
      value: value,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery({
    required String sql,
    List<dynamic>? arguments,
  }) {
    return _db.rawQuery(sql: sql, arguments: arguments);
  }

  @override
  Future<void> clearAllTables() {
    return (_db as SGBDInterface).clearAllTables();
  }

  @override
  Future<void> deleteAllTables() {
    return (_db as SGBDInterface).deleteAllTables();
  }
}
