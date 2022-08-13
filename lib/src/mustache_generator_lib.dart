import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:mustache_template/mustache.dart';
import 'package:source_gen/source_gen.dart';

class MustacheLibGenerator implements Builder {
  final BuilderOptions options;

  MustacheLibGenerator(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['templates_output.dart', 'templates_decorators.dart'],
    };
  }

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      'lib${Platform.pathSeparator}templates_output.dart',
    );
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final Map<Element, List<Template>> allElements = {};
    final Map<String, Template> templates = {};

    await for (final input in buildStep.findAssets(Glob('lib/**.mustache'))) {
      final source = await buildStep.readAsString(input);
      final template = Template(
        source,
        name: input.path,
        htmlEscapeValues: false,
        partialResolver: (name) {
          final key = name.replaceAll('-', '/');
          return templates[key];
        },
      );
      final key =
          input.path.substring(0, input.path.length - '.mustache'.length);
      templates[key] = template;
    }

    final List<MapEntry<String, Template>> allDecorators =
        templates.entries.map((e) {
      String name = e.key.split('/').last;
      name = '${name.substring(0, 1).toUpperCase()}'
          '${name.substring(1)}Template';
      return MapEntry(name, e.value);
    }).toList();

    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        'lib${Platform.pathSeparator}templates_decorators.dart',
      ),
      '''
${allDecorators.map((e) {
        final name = e.key;
        return 'class $name { const $name(); }';
      }).join('\n')}
''',
    );

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      try {
        final library = await buildStep.resolver.libraryFor(input);
        // for (final element in library.topLevelElements) {
        //   element.visitChildren(const _WarningElementVisitor());
        // }

        final reader = LibraryReader(library);

        for (final element in reader.allElements) {
          for (final dec in allDecorators) {
            final checker = TypeChecker.fromUrl(
              'package:${buildStep.inputId.package}/templates_decorators.dart#${dec.key}',
            );
            if (checker.hasAnnotationOf(element)) {
              allElements.putIfAbsent(element, () => []).add(dec.value);
            }
          }
        }
      } catch (_) {}
    }
    // allElements.removeWhere((e) => _name(e).startsWith('_'));

    try {
      final List<String> templateImports = [];
      final templateStrings = allElements.entries.expand((entry) {
        final element = entry.key;
        return entry.value.expand(
          (template) {
            final lines = template
                .renderString(getElementTemplateValues(element))
                .split(RegExp('\n'));
            int i = 0;
            while (i < lines.length) {
              final line = lines[i];
              if (RegExp('^import [\'"][^\'"]+[\'"];\$').hasMatch(line)) {
                templateImports.add(line);
                lines[i] = '';
              } else {
                break;
              }
              i++;
            }

            return lines..add('\n');
          },
        );
      }).join('\n');

      String out = '''
${allElements.keys.map((e) => "import '${e.source!.uri}';").followedBy(templateImports).toSet().join()}

$templateStrings
''';
      try {
        out = DartFormatter().format(out);
      } catch (_) {}

      await buildStep.writeAsString(_allFileOutput(buildStep), out);
    } catch (e, s) {
      print('$e $s');
    }
  }
}

Map<String, Object?> getElementTemplateValues(Element e) {
  if (e is ClassElement) {
    return {
      'name': e.name,
      'metadata': getAnnotationsTemplateValues(e.metadata),
      'docs': getDocumentationTemplateValues(e),
      'methods': e.methods.mapMs(getElementTemplateValues).toList(),
      'fields': e.fields.mapMs(getElementTemplateValues).toList(),
      'typeParameters':
          e.typeParameters.mapMs(getElementTemplateValues).toList(),
      'constructors': e.constructors.mapMs(getElementTemplateValues).toList(),
      'supertype': e.supertype == null
          ? null
          : getInterfaceTypeTemplateValues(e.supertype!),
      'mixins': e.mixins.mapMs(getInterfaceTypeTemplateValues).toList(),
      'interfaces': e.interfaces.mapMs(getInterfaceTypeTemplateValues).toList(),
      'allSupertypes':
          e.allSupertypes.mapMs(getInterfaceTypeTemplateValues).toList(),
    };
  } else if (e is ConstructorElement) {
    return {
      ...getExecutableElementTemplateValues(e),
      'isDefaultConstructor': e.isDefaultConstructor,
      'isUnnamed': e.name.isEmpty,
      'isFactory': e.isFactory,
      'isGenerative': e.isGenerative,
      'redirectedConstructor': e.redirectedConstructor?.name,
      'isConst': e.isConst,
    };
  } else if (e is ExecutableElement) {
    // MethodElement and FunctionElement
    return getExecutableElementTemplateValues(e);
  } else if (e is FieldElement) {
    return {
      'name': e.name,
      ...getDartTypeTemplateValues(e.type),
      'metadata': getAnnotationsTemplateValues(e.metadata),
      'docs': getDocumentationTemplateValues(e),
      'isAbstract': e.isAbstract,
      'isStatic': e.isStatic,
      'isFinal': e.isFinal,
      'isLate': e.isLate,
      'isPrivate': e.isPrivate,
      'isPublic': e.isPublic,
    };
  } else if (e is ParameterElement) {
    return {
      'name': e.name,
      ...getDartTypeTemplateValues(e.type),
      'metadata': getAnnotationsTemplateValues(e.metadata),
      'docs': getDocumentationTemplateValues(e),
      'defaultValueCode': e.defaultValueCode,
      'isNamed': e.isNamed,
      'isOptional': e.isOptional,
      'isPositional': e.isPositional,
      'isRequired': e.isRequired,
    };
  } else if (e is TypeParameterElement) {
    return {
      'name': e.name,
      ...getDartTypeTemplateValues(e.bound, typeKey: 'boundType')
    };
  }
  throw Error();
}

Map<String, Object?> getExecutableElementTemplateValues(ExecutableElement e) {
  return {
    'name': e.name,
    ...getDartTypeTemplateValues(e.type),
    ...getDartTypeTemplateValues(e.returnType, typeKey: 'returnType'),
    'metadata': getAnnotationsTemplateValues(e.metadata),
    'docs': getDocumentationTemplateValues(e),
    'isAbstract': e.isAbstract,
    'isStatic': e.isStatic,
    'parameters': e.parameters.mapMs(getElementTemplateValues).toList(),
    'hasParameters': e.parameters.isNotEmpty,
    'typeParameters': e.typeParameters.mapMs(getElementTemplateValues).toList(),
    'isPrivate': e.isPrivate,
    'isPublic': e.isPublic,
  };
}

List<Map<String, Object?>> getAnnotationsTemplateValues(
  List<ElementAnnotation> metadata,
) {
  return metadata.mapMs((e) {
    final element = e.element;
    return {
      'source': e.toSource(),
      if (element is ConstructorElement) 'constructorName': element.name,
      if (element is PropertyAccessorElement) ...{
        'propertyEnclosingElement': element.enclosingElement3.name,
        'propertyName': element.enclosingElement3.name,
      }
    };
  }).toList();
}

Map<String, Object?> getDocumentationTemplateValues(Element e) {
  final cleanComment =
      (e.documentationComment ?? '').replaceAll(RegExp(r'/// ?'), '');
  return {
    'comment': e.documentationComment,
    'hasComment': e.documentationComment != null,
    'cleanComment': cleanComment,
    'oneLineComment': cleanComment.replaceAll(RegExp(r'\n'), ' '),
    // TODO: support code ``` sections
    'lineBreakComment': cleanComment.replaceAll(RegExp(r'\n'), '<br/>'),
  };
}

Map<String, Object?> getInterfaceTypeTemplateValues(
  InterfaceType e, {
  String typeKey = 'type',
}) {
  return {
    ...getDartTypeTemplateValues(e, typeKey: typeKey),
    'typeArguments': e.typeArguments.mapMs(getDartTypeTemplateValues).toList(),
  };
}

Map<String, Object?> getDartTypeTemplateValues(
  DartType? e, {
  String typeKey = 'type',
}) {
  if (e == null) return {};
  return {
    typeKey: e.getDisplayString(withNullability: true),
    '${typeKey}NotNull': e.getDisplayString(withNullability: false),
    '${typeKey}IsNullable': e.nullabilitySuffix != NullabilitySuffix.none,
    '${typeKey}Core': {
      'isBool': e.isDartCoreBool,
      'isDouble': e.isDartCoreDouble,
      'isInt': e.isDartCoreInt,
      'isList': e.isDartCoreList,
      'isMap': e.isDartCoreMap,
      'isSet': e.isDartCoreSet,
      'isCollection': e.isDartCoreSet || e.isDartCoreList || e.isDartCoreMap,
      'isNum': e.isDartCoreNum,
      'isString': e.isDartCoreString,
      'isEnum': e.isDartCoreEnum,
      'isFunction': e.isDartCoreFunction,
      'isIterable': e.isDartCoreIterable,
      'isObject': e.isDartCoreObject,
      'isNull': e.isDartCoreNull,
      'isSymbol': e.isDartCoreSymbol,
      'listGeneric': e.isDartCoreList
          ? getDartTypeTemplateValues((e as InterfaceType).typeArguments.first)
          : null,
      'setGeneric': e.isDartCoreSet
          ? getDartTypeTemplateValues((e as InterfaceType).typeArguments.first)
          : null,
      'mapKeyGeneric': e.isDartCoreMap
          ? getDartTypeTemplateValues((e as InterfaceType).typeArguments.first)
          : null,
      'mapValueGeneric': e.isDartCoreMap
          ? getDartTypeTemplateValues((e as InterfaceType).typeArguments.last)
          : null,
    },
    '${typeKey}IsJson': dartTypeIsJson(e),
  };
}

bool dartTypeIsJson(DartType e) {
  if (e.isDartCoreList) {
    return dartTypeIsJson((e as InterfaceType).typeArguments.first);
  }
  if (e.isDartCoreMap) {
    final arguments = (e as InterfaceType).typeArguments;
    return arguments.first.getDisplayString(withNullability: false) ==
            'String' &&
        dartTypeIsJson(arguments.last);
  }
  return e.isDartCoreBool ||
      e.isDartCoreDouble ||
      e.isDartCoreInt ||
      e.isDartCoreNum ||
      e.isDartCoreString;
}

extension CollectionExtension<T> on Iterable<T> {
  Iterable<Map<String, Object?>> mapMs(
    Map<String, Object?> Function(T) mapper,
  ) {
    final length = this.length;
    int i = 0;
    return map((e) {
      final value = mapper(e);
      value['ms-last'] = i == length - 1;
      value['ms-first'] = i == 0;
      value['ms-index'] = i++;
      return value;
    });
  }
}

class _WarningElementVisitor extends SimpleElementVisitor<void> {
  const _WarningElementVisitor();

  void visit(Element element) {
    // if (const TypeChecker.fromRuntime(ValidaField).hasAnnotationOf(element) &&
    //     element.enclosingElement != null &&
    //     !const TypeChecker.fromRuntime(Valida)
    //         .hasAnnotationOfExact(element.enclosingElement!)) {
    //   print(
    //     'Element "${element}" has a `ValidaField` annotation,'
    //     ' but it\'s enclosing element "${element.enclosingElement}"'
    //     ' does not have a `Valida` annotation.'
    //     ' The field may not be validated.',
    //   );
    // }
  }

  @override
  void visitConstructorElement(ConstructorElement element) => visit(element);
  @override
  void visitFieldElement(FieldElement element) => visit(element);
  @override
  void visitFunctionElement(FunctionElement element) => visit(element);
  @override
  void visitMethodElement(MethodElement element) => visit(element);
  @override
  void visitParameterElement(ParameterElement element) => visit(element);
  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) =>
      visit(element);
  @override
  void visitClassElement(ClassElement element) => visit(element);
  @override
  void visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      visit(element);
}
