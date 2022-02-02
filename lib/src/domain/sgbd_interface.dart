abstract class SGBDInterface {
  abstract List<Map<String, dynamic>> tables;
  Future<void> createDatabase(database);
  Future<void> upgradeDatabase(database, int currentVersion, int newVersion);
  Future<void> downgradeDatabase(database, int currentVersion, int newVersion);
  Future<void> clearAllTables();
  Future<void> deleteAllTables();
}
