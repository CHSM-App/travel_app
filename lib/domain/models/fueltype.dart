import 'package:json_annotation/json_annotation.dart';

part 'fueltype.g.dart';

@JsonSerializable()
class Fueltype {
  final int? FuelTypeId;
  final String? FuelType;

  Fueltype({this.FuelTypeId, this.FuelType});

  factory Fueltype.fromJson(Map<String, dynamic> json) =>
      _$FueltypeFromJson(json);

  Map<String, dynamic> toJson() => _$FueltypeToJson(this);
}
