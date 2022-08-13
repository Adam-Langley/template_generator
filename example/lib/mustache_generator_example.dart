import 'package:mustache_generator/mustache_generator.dart';

@Mustache()
class Model {
  final String? name;

  /// Documentation for value
  /// non-null integer
  final int value;

  final List<String>? items;

  final List<int?> itemsNotNull;

  Model({
    this.name,
    required this.value,
    this.items,
    required this.itemsNotNull,
  });
}
