import 'dart:io';
import 'package:interact_cli/interact_cli.dart';

// Converts PascalCase to snake_case
String toSnakeCase(String input) {
  return input.replaceAllMapped(RegExp(r'[A-Z]'), (Match match) {
    return '_${match.group(0)!.toLowerCase()}';
  }).replaceFirst('_', '');
}

String toDashCase(String input) {
  return input.replaceAllMapped(RegExp(r'[A-Z]'), (Match match) {
    return '-${match.group(0)!.toLowerCase()}';
  }).replaceFirst('-', '');
}

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

  // Convert resource name to snake_case for filenames
  final snakeCaseName = toSnakeCase(name);

  // Components
  var options = ['Form', 'Table'];
  final selectedComponentsIndexes = MultiSelect(
    prompt: 'What do you want to add to the resource?',
    options: options,
  ).interact();
  var selectedComponents =
  selectedComponentsIndexes.map((e) => options[e]).toList();

  // Create files inside lib/resources/{name}
  final path = 'lib/resources/$snakeCaseName';
  final resourcePath = '$path/${snakeCaseName}_resource.dart';
  final factoryPath = '$path/${snakeCaseName}_factory.dart';
  final repositoryPath = '$path/${snakeCaseName}_repository.dart';
  final formPath = '$path/pages/${snakeCaseName}_form_page.dart';
  final tablePath = '$path/pages/${snakeCaseName}_table_page.dart';

  // Create resource file
  final resourceFile = File(resourcePath);
  resourceFile.createSync(recursive: true);
  resourceFile.writeAsStringSync(resourceStub(name, selectedComponents));

  // Create factory file
  final factoryFile = File(factoryPath);
  factoryFile.createSync(recursive: true);
  factoryFile.writeAsStringSync(factoryStub(name));

  // Create repository file
  final repositoryFile = File(repositoryPath);
  repositoryFile.createSync(recursive: true);
  repositoryFile.writeAsStringSync(repositoryStub(name));

  // Create form and table files based on the selected components
  if (selectedComponents.contains('Form')) {
    final formFile = File(formPath);
    formFile.createSync(recursive: true);
    formFile.writeAsStringSync(formPageStub(name));
  }

  if (selectedComponents.contains('Table')) {
    final tableFile = File(tablePath);
    tableFile.createSync(recursive: true);
    tableFile.writeAsStringSync(tablePageStub(name));
  }
}

String resourceStub(String name, List<String> components) {
  var titleCaseResource = name;
  var titleCaseResourcePlural = '${titleCaseResource}s';

  // Conditional imports for form and table pages
  var imports = [
    "import 'package:crud_o/resources/crudo_resource.dart';",
    "import 'package:flutter/material.dart';",
    "import '${toSnakeCase(name)}_repository.dart';",
  ];

  if (components.contains('Form')) {
    imports.add("import 'pages/${toSnakeCase(name)}_form_page.dart';");
  }

  if (components.contains('Table')) {
    imports.add("import 'pages/${toSnakeCase(name)}_table_page.dart';");
    imports.add(
        "import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';");
  }

  // Conditional formPage and tablePage overrides
  var formPageOverride = '';
  if (components.contains('Form')) {
    formPageOverride = '''
  @override
  Widget? get formPage => const ${titleCaseResource}FormPage();
    ''';
  }

  var tablePageOverride = '';
  if (components.contains('Table')) {
    tablePageOverride = '''
  @override
  Widget? get tablePage => ${titleCaseResource}TablePage();
    ''';
  }

  return '''
${imports.join('\n')}

class ${titleCaseResource}Resource extends CrudoResource<$titleCaseResource> {

  ${titleCaseResource}Resource() : super(repository: ${titleCaseResource}Repository());

  $formPageOverride

  $tablePageOverride

  @override
  String pluralName() => '$titleCaseResourcePlural';

  @override
  String singularName() => '$titleCaseResource';

  @override
  IconData icon() => Icons.folder;
}
  ''';
}

String factoryStub(String name) {
  var titleCaseResource = name;
  return '''
import 'package:crud_o/resources/resource_factory.dart';
import 'package:flutter/material.dart';

class ${titleCaseResource}Factory extends ResourceFactory<$titleCaseResource> {
  @override
  $titleCaseResource create() {
    return $titleCaseResource(
      id: 0,
      name: '',
    );
  }

  @override
  $titleCaseResource createFromJson(Map<String, dynamic> json) {
    return $titleCaseResource(
      id: json['id'],
      name: json['name'],
    );
  }
}
  ''';
}

String repositoryStub(String name) {
  var titleCaseResource = name;
  var titleCaseResourcePlural = '${titleCaseResource}s';
  return '''
import 'package:crud_o/resources/resource_repository.dart';
import '${toSnakeCase(name)}_factory.dart';

class ${titleCaseResource}Repository extends ResourceRepository<$titleCaseResource> {

  ${titleCaseResource}Repository() : super(endpoint: "${toDashCase(name)}s", factory: ${titleCaseResource}Factory());
}
  ''';
}

String formPageStub(String name) {
  var titleCaseResource = name;
  return '''
import 'package:flutter/material.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_form.dart';
import '../${toSnakeCase(name)}_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_text_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';

class ${titleCaseResource}FormPage extends StatelessWidget {
  const ${titleCaseResource}FormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudoForm<${titleCaseResource}Resource, $titleCaseResource> (
      displayType: CrudoFormDisplayType.fullPage,
      formBuilder: (context, formData, futureResult, formController) => Column(children: [
         CrudoTextField(
            config: CrudoFieldConfiguration(
              name: 'name',
              label: 'Nome',
              required: true,
            ),
          ),
          // Add more fields here
      ]),
      toFormData: (model, extraData) => {
        'id': model.id,
        'name': model.name,
      },
    );
  }
}
  ''';
}

String tablePageStub(String name) {
  var titleCaseResource = name;
  return '''
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import '../${toSnakeCase(name)}_resource.dart';

class ${titleCaseResource}TablePage extends StatelessWidget {
  const ${titleCaseResource}TablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudoTable<${titleCaseResource}Resource, $titleCaseResource>(
      fullPage: true,
      paginated: true,
      columns: [
        CrudoTableColumn(
          column: PlutoColumn(
            title: 'Name', field: 'name', type: PlutoColumnType.text(),
          ),
          cellBuilder: (${titleCaseResource} model) {
            return PlutoCell(value: model.name);
          },
        ),
      ],
    );
  }
}
  ''';
}

