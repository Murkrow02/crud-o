
import 'package:crud_o/resources/crudo_resource.dart';

class PaginatedResourceResponse<T> {

  late List<T> data;
  final int? currentPage;
  final int? nextPage;
  bool get hasNextPage => nextPage != null;
  final int? from;
  final int? to;

  PaginatedResourceResponse({
    required this.currentPage,
    required this.from,
    required this.to,
    required this.nextPage,
  }) ;

  factory PaginatedResourceResponse.fromJson(dynamic json) {
    return PaginatedResourceResponse(
      currentPage: json['current_page'],
      nextPage: json['next_page_url'] != null ? json['current_page'] + 1 : null,
      from: json['from'],
      to: json['to'],
    );
  }
}