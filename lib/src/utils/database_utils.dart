class DatabaseUtils {
  static bool? convertBool(dynamic value) {
    if (value == null) return null;
    if (value.runtimeType.toString() == 'bool') return value;
    if (value.runtimeType.toString() == 'int') return value == 1;
    if (value.runtimeType.toString() == 'String') return value == 'true';
    return false;
  }
}
