<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Generate files from Dart code annotations and [Mustache](http://mustache.github.io/) templates

## Features

- Generate files from Dart code annotations and [Mustache](http://mustache.github.io/) templates

## Getting started

Install dependencies:

```yaml
dev_dependencies:
  build_runner:
  mustache_generator:
    git:
      url: https://github.com/juancastillo0/template_generator
```

## Usage

Create a Mustache template within the `lib` directory (`lib/templates/fieldsEnum.mustache`):

```mustache
enum {{name}}Fields {
{{# fields }}
  {{ name }},
{{/ fields }}
}
```

Create and annotate your model:

```dart
@FieldsEnumTemplate()
class Model {
  final String fieldName;

  const Model({
    required this.fieldName,
  });
}
```

Run the code generator:

```bash
dart pub run build_runner watch --delete-conflicting-outputs
```

This will generate the following file:

```dart
enum ModelFields {
    fieldName,
}
```

You can check out the [`/example`](./example/) folder for a complete example.

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
