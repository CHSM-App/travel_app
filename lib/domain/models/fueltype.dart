import 'package:json_annotation/json_annotation.dart';

part 'Fueltype.g.dart';

@JsonSerializable()
class Fueltype {
  int? FuelTypeId;
  String? FuelType;

  Fueltype({this.FuelTypeId, this.FuelType});


}
