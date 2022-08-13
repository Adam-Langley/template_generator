/// Generate files from Dart code annotations and Mustache templates
library mustache_generator;

import 'package:build/build.dart';
import 'package:mustache_generator/src/mustache_generator_lib.dart';

/// Returns a Builder that generates the file that centralizes all
/// generated templates in the project
Builder mustacheLibGen(BuilderOptions options) => MustacheLibGenerator(options);
