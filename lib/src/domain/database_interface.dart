abstract class DatabaseInterface {
  Future<void> init();

  Future<Map<String, dynamic>> createOrUpdate({
    required String table,
    required Map<String, dynamic> data,
    bool synced = false,
  });

  Future<Map<String, dynamic>?> getByColumn({
    required String table,
    required String column,
    required dynamic value,
    String? orderBy,
  });

  Future<Map<String, dynamic>> update({
    required String table,
    required String column,
    required dynamic value,
    required Map<String, dynamic> data,
    bool synced = false,
  });

  Future<bool> delete({
    required String table,
    required String column,
    required dynamic value,
  });

  Future<List<Map<String, dynamic>>> list({
    required String table,
    String? where,
    List<dynamic>? args,
    int? limit,
    int? page,
    String? orderBy,
  });

  Future<List<Map<String, dynamic>>> rawQuery({
    required String sql,
    List<dynamic>? arguments,
  });

  Future<void> clearAllTables();

  Future<void> deleteAllTables();
}
