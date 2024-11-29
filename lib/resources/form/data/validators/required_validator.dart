import 'package:crud_o/resources/form/data/validators/crudo_validator.dart';

class RequiredValidator implements CrudoValidator<dynamic> {

  @override
  String? validate(value) {
    return value == null ? 'Questo campo è obbligatorio' : null;
  }

}