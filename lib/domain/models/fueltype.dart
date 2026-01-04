import 'package:json_annotation/json_annotation.dart';

part 'fueltype.g.dart';

@JsonSerializable()
class Fueltype {
  final int? fuelTypeId;
  final String? fuelType;

  Fueltype({this.fuelTypeId, this.fuelType});

  factory Fueltype.fromJson(Map<String, dynamic> json) =>
      _$FueltypeFromJson(json);

  Map<String, dynamic> toJson() => _$FueltypeToJson(this);
}
