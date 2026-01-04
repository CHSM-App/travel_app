// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      StatusId: (json['StatusId'] as num?)?.toInt(),
      StatusName: json['StatusName'] as String?,
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'StatusId': instance.StatusId,
      'StatusName': instance.StatusName,
    };
