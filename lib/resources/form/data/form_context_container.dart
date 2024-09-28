import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

/// This class is needed to pass the form context to the fields
/// Fields are not aware of the resource or model type so we pass a generic bloc + other info
class FormContextContainer
{
  final CrudoFormBloc formBloc;
  final ResourceContext resourceContext;
  final Map<String, dynamic> formData;
  final GlobalKey<FormBuilderState> formKey;
  FormContextContainer({required this.formBloc, required this.resourceContext, required this.formData, required this.formKey});
}

extension FormContextContainerExtension on BuildContext
{
  FormContextContainer readFormContext() => read<FormContextContainer>();
}