import 'dart:io';

import 'package:interact_cli/interact_cli.dart';

void main(List<String> arguments) {
  // Resource name
  final name = Input(
    prompt: 'Name of the resource',
    validator: (String x) {
      if (x.isEmpty) {
        throw 'Name cannot be empty';
      }
      return true;
    },
  ).interact();

  // Components
  final components = MultiSelect(
    prompt: 'What do you want to add to the resource?',
    options: ['Form', 'View', 'List'],
  ).interact();

  // Create files inside lib/resources/{name}
  final path = 'lib/resources/$name';
  final resourcePath = '$path/$name\_resource.dart';

  // Create resource file with IO
  final resourceFile = File(resourcePath);
  resourceFile.createSync(recursive: true);
}

String resourceStub(String name) {
  return '''



''';
}
