import 'package:json_annotation/json_annotation.dart';
part 'Status.g.dart';
            
@JsonSerializable()
class Status {
  int? StatusId;
    String? StatusName;

    Status({
      this.StatusId, 
      this.StatusName
      
      });

    factory Status.fromJson(Map<String, dynamic> json) => Status(
          StatusId: json['StatusId'] as int?,
          StatusName: json['StatusName'] as String?,
        );

   

}
