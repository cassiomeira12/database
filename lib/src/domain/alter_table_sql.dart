class AlterTableSQL {
  final int versionToExecute;
  final List<String> sql;

  AlterTableSQL({
    required this.versionToExecute,
    required this.sql,
  });
}
