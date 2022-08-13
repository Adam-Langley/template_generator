import 'templates_decorators.dart';

/// The model
@DocsTemplate()
@FieldsTemplate()
class Model {
  final String? name;

  /// Documentation for value
  /// non-null integer
  final int value;

  /// A list of items
  final List<String>? items;

  final List<int?> itemsNotNull;

  Model({
    this.name,
    required this.value,
    this.items = const ['default'],
    required this.itemsNotNull,
  });
}

@DocsTemplate()
class OtherModel {
  /// Documentation for [t]
  int? t;
}
