import 'package:json_annotation/json_annotation.dart';
part 'Vehicletype.g.dart';
            
@JsonSerializable()
class VehicleType {
  int? TypeId;
    String? type;

   VehicleType({this.TypeId, this.type});

   factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
         TypeId: json['TypeId'] as int?,
         type: json['type'] as String?,
       );

   Map<String, dynamic> toJson() => {
         'vehicleTypeId': TypeId,
         'typeName': type,
       };

}
