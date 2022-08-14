import 'package:mustache_generator_example/mustache_generator_example.dart';
import 'package:mobx/mobx.dart';

const markdownDocsModel = '''
# Model
The model

## Constructors
The constructors for Model

### Unnamed


#### Parameters
| Parameter | Type | Description | Default | Required |
| ---- | ---- | --- | --- | --- |
  |name|`String?`|NA||false|
  |value|`int`|NA||true|
  |items|`List<String>?`|NA|const ['default']|false|
  |itemsNotNull|`List<int?>`|NA||true|

## Fields
The fields you will find in Model

| Name | Type | Description | Final |
| ---- | ---- | --- | --- |
  |name|`String?`|NA|true|
  |value|`int`|Documentation for value<br/>non-null integer|true|
  |items|`List<String>?`|A list of items|true|
  |itemsNotNull|`List<int?>`|NA|true|
''';

enum ModelFields {
  name,
  value,
  items,
  itemsNotNull,
}

class ModelPartial {
  ModelPartial({
    String? name,
    int? value,
    List<String>? items,
    List<int?>? itemsNotNull,
  })  : _name = name,
        value = value,
        _items = items,
        itemsNotNull = itemsNotNull;

  String? _name;
  String? get name => _name;
  set name(String? value) {
    _name = value;
    _nameIsSet = true;
  }

  bool _nameIsSet = false;
  bool get nameIsSet => _nameIsSet || name != null;

  /// Documentation for value
  /// non-null integer
  int? value;
  bool get valueIsSet => value != null;

  /// A list of items
  List<String>? _items;
  List<String>? get items => _items;
  set items(List<String>? value) {
    _items = value;
    _itemsIsSet = true;
  }

  bool _itemsIsSet = false;
  bool get itemsIsSet => _itemsIsSet || items != null;

  List<int?>? itemsNotNull;
  bool get itemsNotNullIsSet => itemsNotNull != null;

  ModelPartial.fromValue(Model value)
      : _name = value.name,
        value = value.value,
        _items = value.items,
        itemsNotNull = value.itemsNotNull;

  ModelPartial.fromJson(Map<String, Object?> json)
      : _name = json['name'] as String?,
        value = json['value'] as int?,
        _items = json['items'] as List<String>?,
        itemsNotNull = json['itemsNotNull'] as List<int?>?;

  ModelPartial clone() {
    return ModelPartial()..merge(this);
  }

  void merge(ModelPartial other) {
    if (other.nameIsSet) name = other.name;
    if (other.valueIsSet) value = other.value;
    if (other.itemsIsSet) items = other.items;
    if (other.itemsNotNullIsSet) itemsNotNull = other.itemsNotNull;
  }

  bool get isValidValue {
    if (value is! int) return false;
    if (itemsNotNull is! List<int?>) return false;
    return true;
  }

  Model? tryToValue() {
    if (!isValidValue) return null;
    return Model(
      name: name,
      value: value as int,
      items: items,
      itemsNotNull: itemsNotNull as List<int?>,
    );
  }

  @override
  operator ==(Object? other) =>
      other is ModelPartial &&
      other.name == name &&
      other.value == value &&
      other.items == items &&
      other.itemsNotNull == itemsNotNull;

  @override
  int get hashCode => Object.hashAll([
        name,
        value,
        items,
        itemsNotNull,
      ]);

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'value': value,
      'items': items,
      'itemsNotNull': itemsNotNull,
    };
  }

  @override
  String toString() {
    return 'ModelPartial${toJson()}';
  }
}

extension ModelPartialExt on Model {
  ModelPartial toPartial() => ModelPartial.fromValue(this);
}

class ModelMutable {
  ModelMutable({
    required this.nameObservable,
    required this.valueObservable,
    required this.itemsObservable,
    required this.itemsNotNullObservable,
  });

  final Observable<String?> nameObservable;
  String? get name => nameObservable.value;
  set name(String? value) => nameObservable.value = value;

  /// Documentation for value
  /// non-null integer

  final Observable<int> valueObservable;
  int get value => valueObservable.value;
  set value(int value) => valueObservable.value = value;

  /// A list of items
  final Observable<ObservableList<String>?> itemsObservable;
  ObservableList<String>? get items => itemsObservable.value;
  set items(List<String>? value) =>
      itemsObservable.value = value == null ? null : ObservableList.of(value);

  final Observable<ObservableList<int?>> itemsNotNullObservable;
  ObservableList<int?> get itemsNotNull => itemsNotNullObservable.value;
  set itemsNotNull(List<int?> value) =>
      itemsNotNullObservable.value = ObservableList.of(value);

  ModelMutable.fromValue(Model value)
      : nameObservable = Observable(value.name),
        valueObservable = Observable(value.value),
        itemsObservable = Observable(
            value.items == null ? null : ObservableList.of(value.items!)),
        itemsNotNullObservable =
            Observable(ObservableList.of(value.itemsNotNull));

  ModelMutable.fromJson(Map<String, Object?> json)
      : nameObservable = Observable(json['name'] as String?),
        valueObservable = Observable(json['value'] as int),
        itemsObservable = Observable(json['items'] == null
            ? null
            : ObservableList.of((json['items'] as List<dynamic>).cast())),
        itemsNotNullObservable = Observable(
            ObservableList.of((json['itemsNotNull'] as List<dynamic>).cast()));

  void mergePartial(ModelPartial other) {
    runInAction(() {
      if (other.nameIsSet) {
        name = other.name;
      }
      if (other.valueIsSet) {
        value = other.value as int;
      }
      if (other.itemsIsSet) {
        items = other.items;
      }
      if (other.itemsNotNullIsSet) {
        itemsNotNull = other.itemsNotNull as List<int?>;
      }
    });
  }

  Model toValue() {
    return Model(
      name: name,
      value: value,
      items: items,
      itemsNotNull: itemsNotNull,
    );
  }

  late final List<Observable<Object?>> allObservables = [
    nameObservable,
    valueObservable,
    itemsObservable,
    itemsNotNullObservable,
  ];

  @override
  operator ==(Object? other) =>
      other is ModelMutable &&
      other.name == name &&
      other.value == value &&
      other.items == items &&
      other.itemsNotNull == itemsNotNull;

  @override
  int get hashCode => Object.hashAll([
        name,
        value,
        items,
        itemsNotNull,
      ]);

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'value': value,
      'items': items,
      'itemsNotNull': itemsNotNull,
    };
  }

  @override
  String toString() {
    return 'ModelMutable${toJson()}';
  }
}

extension ModelMutableExt on Model {
  ModelMutable toMutable() => ModelMutable.fromValue(this);
}

const markdownDocsOtherModel = '''
# OtherModel

- tag1
- model

## Constructors
The constructors for OtherModel

### Unnamed



## Fields
The fields you will find in OtherModel

| Name | Type | Description | Final |
| ---- | ---- | --- | --- |
  |t|`int?`|Documentation for [t]|false|
''';
