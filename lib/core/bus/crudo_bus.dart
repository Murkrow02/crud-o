import 'package:event_bus/event_bus.dart';

/// This bus is used to communicate between different parts of the app without using the context.
/// Can be useful for example for the rest client to notify the app that authentication is required.
EventBus _crudoEventBus = EventBus();
EventBus get crudoEventBus => _crudoEventBus;