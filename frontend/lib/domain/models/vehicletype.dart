import 'package:json_annotation/json_annotation.dart';
part 'vehicletype.g.dart';
            
@JsonSerializable()
class VehicleType {
  int? TypeId;
    String? Type;

   VehicleType({this.TypeId, this.Type});

   factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
         TypeId: json['TypeId'] as int?,
         Type: json['Type'] as String?,
       );

   Map<String, dynamic> toJson() => {
         'TypeId': TypeId,
         'Type': Type,
       };

}
