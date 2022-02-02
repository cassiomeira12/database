import 'package:flutter/foundation.dart';

import 'type_column.dart';

class ColumnTable {
  final String name;
  final TypeColumn type;
  String? options;

  ColumnTable({
    required this.name,
    required this.type,
    this.options,
  });

  @override
  String toString() {
    return '$name ${describeEnum(type)} ${options ?? ''}';
  }
}
