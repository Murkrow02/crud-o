class SortModel {
  SortModel({
    required this.field,
    required this.direction,
  });

  final String field;
  final String direction;

  factory SortModel.fromJson(Map<String, dynamic> json) => SortModel(
        field: json['field'] as String,
        direction: json['direction'] as String,
      );

  Map<String, dynamic> toJson() => {
        'field': field,
        'direction': direction,
      };
}