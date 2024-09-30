
import 'package:crud_o/resources/crudo_resource.dart';

class PaginatedResponse<T> {

  late List<T> data;
  final int? currentPage;
  final int? nextPage;
  bool get hasNextPage => nextPage != null;
  final int? from;
  final int? to;

  PaginatedResponse({
    required this.currentPage,
    required this.from,
    required this.to,
    required this.nextPage,
    this.data = const [],
  }) ;

  factory PaginatedResponse.fromJson(dynamic json) {
    return PaginatedResponse(
      currentPage: json['current_page'],
      nextPage: json['next_page_url'] != null ? json['current_page'] + 1 : null,
      from: json['from'],
      to: json['to'],
    );
  }
}

class SinglePageResponse<T> extends PaginatedResponse<T> {
  SinglePageResponse({required List<T> data}) : super(currentPage: 1, from: 1, to: 1, nextPage: 1, data: data);
}