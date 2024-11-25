import 'package:http/http.dart';
import 'bus_event.dart';

class UnauthorizedBusEvent extends BusEvent {
  Response response;
  UnauthorizedBusEvent({required this.response});
}