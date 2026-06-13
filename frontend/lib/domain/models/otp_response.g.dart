// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpResponse _$OtpResponseFromJson(Map<String, dynamic> json) => OtpResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  sent: json['sent'] as bool?,
  devOtp: json['dev_otp'] as String?,
);

Map<String, dynamic> _$OtpResponseToJson(OtpResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'sent': instance.sent,
      'dev_otp': instance.devOtp,
    };
