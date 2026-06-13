import 'package:json_annotation/json_annotation.dart';

part 'otp_response.g.dart';

/// Response for both `login/sendOtp` and `login/verifyOtp`.
/// sendOtp returns: { success, sent, dev_otp? }
/// verifyOtp returns: { success, message }
@JsonSerializable()
class OtpResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  /// Whether the WhatsApp delivery actually succeeded (sendOtp only).
  @JsonKey(name: 'sent')
  final bool? sent;

  /// Plain OTP returned only when the backend runs with WhatsApp disabled in
  /// non-production (dev convenience). Null in production.
  @JsonKey(name: 'dev_otp')
  final String? devOtp;

  OtpResponse({
    required this.success,
    this.message,
    this.sent,
    this.devOtp,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OtpResponseToJson(this);
}
