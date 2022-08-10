import 'dart:io';

import 'package:database/src/domain/alter_table_sql.dart';
import 'package:database/src/domain/column_type.dart';
import 'package:database/src/domain/database_interface.dart';
import 'package:database/src/domain/sgbd_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SQLDatabase implements SGBDInterface, DatabaseInterface {
  final int version;
  final bool offlineSync;

  final String _databaseName = 'database_app.db';

  @override
  List<Map<String, dynamic>> tables;

  late Database _database;

  SQLDatabase({
    required this.offlineSync,
    required this.version,
    required this.tables,
  });

  @override
  Future<void> init() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = p.join(directory.path, _databaseName);
    _database = await openDatabase(
      path,
      version: version,
      onOpen: (Database db) async {
        var version = await db.getVersion();
        debugPrint('DB version [$version] - ${db.path}');
      },
      onCreate: (Database db, int newVersion) => createDatabase(db),
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < newVersion) {
          await upgradeDatabase(db, oldVersion, newVersion);
        }
      },
      onDowngrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion > newVersion) {
          await downgradeDatabase(db, oldVersion, newVersion);
        }
      },
    );
  }

  @override
  Future<void> close() {
    return _database.close();
  }

  @override
  Future<void> createDatabase(database) async {
    try {
      for (var table in tables) {
        debugPrint('CREATE DATABASE TABLES');
        List<ColumnTable> columns = table['columns'];
        String columnsString = columns
            .map((column) {
              return column.toString();
            })
            .toList()
            .join(', ');
        final String sql =
            'CREATE TABLE IF NOT EXISTS ${table['name']} ( $columnsString )';
        await database.execute(sql);
        debugPrint('--------\n$sql\n--------');
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  @override
  Future<void> upgradeDatabase(
    database,
    int currentVersion,
    int newVersion,
  ) async {
    debugPrint('DB upgrade from [$currentVersion] to [$newVersion]');
    for (var table in tables) {
      await _checkIfTableExist(
        database,
        table['name'],
        table['columns'],
      );
      List<AlterTableSQL> alterTable = table['upgrade'] ?? const [];
      for (var alter in alterTable) {
        if (alter.versionToExecute > currentVersion &&
            alter.versionToExecute <= newVersion) {
          await _alterTable(database, sql: alter.sql);
        }
      }
    }
  }

  @override
  Future<void> downgradeDatabase(
    database,
    int currentVersion,
    int newVersion,
  ) async {
    debugPrint('DB downgrade from [$currentVersion] to [$newVersion]');
    for (var table in tables) {
      List<AlterTableSQL> alterTable = table['downgrade'] ?? const [];
      for (var alter in alterTable) {
        if (alter.versionToExecute <= currentVersion &&
            alter.versionToExecute > newVersion) {
          await _alterTable(database, sql: alter.sql);
        }
      }
    }
  }

  Future<void> _checkIfTableExist(
    Database database,
    String table,
    List<ColumnTable> columns,
  ) async {
    try {
      final list = await database.rawQuery('PRAGMA table_info($table)');
      if (list.isEmpty) {
        String columnsString = columns
            .map((column) {
              return column.toString();
            })
            .toList()
            .join(', ');
        final String sql =
            'CREATE TABLE IF NOT EXISTS $table ( $columnsString )';
        database.execute(sql);
        debugPrint(sql);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> _alterTable(
    Database database, {
    required List<String> sql,
  }) async {
    try {
      for (var sqlQuery in sql) {
        await database.execute(sqlQuery);
        debugPrint(sqlQuery);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  @override
  Future<void> clearAllTables() async {
    try {
      for (var table in tables) {
        var count = await _database.delete(table['name']);
        debugPrint('CLEAR [$count] ROWS FROM TABLE [${table['name']}]');
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  @override
  Future<void> deleteAllTables() async {
    try {
      for (var table in tables) {
        await _database.rawQuery('DROP TABLE ${table['name']}');
        debugPrint('DROPPED TABLE ${table['name']}');
      }
    } catch (error) {
      debugPrint(error.toString());
    } finally {
      await createDatabase(_database);
    }
  }

  @override
  Future<Map<String, dynamic>> createOrUpdate({
    required String table,
    required Map<String, dynamic> data,
    bool synced = false,
  }) async {
    if (offlineSync) {
      data['synced'] = '$synced';
    }
    try {
      if (data['id'] == null) {
        int id = await _database.insert(
          table,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        data['id'] = id;
        if (data.containsKey('synced')) {
          data['synced'] = data['synced'] == 'true';
        }
        return data;
      } else {
        final id = data['id'];
        var temp = await getByColumn(
          table: table,
          column: 'id',
          value: id,
        );
        if (temp == null) {
          int id = await _database.insert(
            table,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          data['id'] = id;
          if (data.containsKey('synced')) {
            data['synced'] = data['synced'] == 'true';
          }
          return data;
        } else {
          data.remove('id');
          await _database.update(
            table,
            data,
            where: 'id = ?',
            whereArgs: [id],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          data['id'] = id;
          if (data.containsKey('synced')) {
            data['synced'] = data['synced'] == 'true';
          }
          return data;
        }
      }
    } catch (error) {
      debugPrint("Error createOrUpdate - $table - $error");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getByColumn({
    required String table,
    required String column,
    required dynamic value,
    String? orderBy,
  }) async {
    try {
      List result = await _database.query(
        table,
        where: '$column = ?',
        whereArgs: [value],
        orderBy: orderBy, // ?? 'id DESC',
      );
      List<Map<String, dynamic>> list = result.map<Map<String, dynamic>>((map) {
        return Map<String, dynamic>.from(map);
      }).toList();
      if (list.isNotEmpty) {
        var data = list.first;
        if (data.containsKey('synced')) {
          data['synced'] = data['synced'] == 'true';
        }
        return data;
      }
      return null;
    } catch (error) {
      debugPrint("Error getByColumn - $table - $error");
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> list({
    required String table,
    String? where,
    List<dynamic>? args,
    int? limit,
    int? page,
    String? orderBy,
  }) async {
    try {
      List result = await _database.query(
        table,
        limit: limit,
        offset: page,
        where: where,
        whereArgs: args,
        orderBy: orderBy, // ?? 'id DESC',
      );
      List<Map<String, dynamic>> list = result.map<Map<String, dynamic>>((map) {
        return Map<String, dynamic>.from(map);
      }).toList();
      return list;
    } catch (error) {
      debugPrint("Error list - $table - $error");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required String column,
    required dynamic value,
    required Map<String, dynamic> data,
    bool synced = false,
  }) async {
    if (offlineSync) {
      data['synced'] = '$synced';
    }
    try {
      Map<String, dynamic> map = data;
      final id = data['id'];
      data.remove('id');
      await _database.transaction((txn) {
        return txn.update(
          table,
          map,
          where: '$column = ?',
          whereArgs: [value],
        );
      });
      data['id'] = id;
      if (data.containsKey('synced')) {
        data['synced'] = data['synced'] == 'true';
      }
      return data;
    } catch (error) {
      debugPrint("Error update - $table - $error");
      rethrow;
    }
  }

  @override
  Future<bool> delete({
    required String table,
    required String column,
    required dynamic value,
  }) async {
    try {
      await _database.transaction((txn) {
        return txn.delete(
          table,
          where: '$column = ?',
          whereArgs: [value],
        );
      });
      return true;
    } catch (error) {
      debugPrint("Error delete - $table - $error");
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery({
    required String sql,
    List<dynamic>? arguments,
  }) async {
    try {
      List result = await _database.rawQuery(sql, arguments);
      List<Map<String, dynamic>> list = result.map<Map<String, dynamic>>((map) {
        return Map<String, dynamic>.from(map);
      }).toList();
      return list;
    } catch (error) {
      debugPrint("Error execute - $error");
      rethrow;
    }
  }
}
