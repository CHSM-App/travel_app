import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';

@JsonSerializable()
class Customer {
  @JsonKey(name: 'CustomerId')
  int? customerId;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'phone')
  String? phone;

  @JsonKey(name: 'address')
  String? address;

  @JsonKey(name: 'LicenceNo')
  String? licenceNo;

  @JsonKey(name: 'LicenceExpiry')
  DateTime? licenceExpiry;

  @JsonKey(name: 'documents')
  String? documents;

  @JsonKey(name: 'agency_id')
  String? agencyId;

  // Outstanding balance across this customer's non-cancelled trips, supplied by
  // the CustomerList query. Null when the backend doesn't return it.
  @JsonKey(name: 'pending_amount')
  double? pendingAmount;

  Customer({
    this.customerId,
    this.name,
    this.phone,
    this.address,
    this.licenceNo,
    this.licenceExpiry,
    this.documents,
    this.agencyId,
    this.pendingAmount,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        customerId: _readInt(json, const ['CustomerId', 'customerId', 'id']),
        name: _readString(json, const ['name', 'Name']),
        phone: _readString(json, const ['phone', 'Phone']),
        address: _readString(json, const ['address', 'Address']),
        licenceNo: _readString(json, const ['LicenceNo', 'licenseNo']),
        licenceExpiry: _readDate(json, const ['LicenceExpiry', 'licenseExpiry']),
        documents: _readString(json, const [
          'documents',
          'Documents',
          'document',
          'Document',
          'id_proof',
          'Id_Proof',
          'photo',
          'Photo',
          'idProof',
          'IdProof',
        ]),
        agencyId: _readString(json, const ['agency_id', 'agencyId']),
        pendingAmount:
            _readDouble(json, const ['pending_amount', 'pendingAmount']),
      );

  Map<String, dynamic> toJson() => {
        'CustomerId': customerId,
        'customerId': customerId,
        'customer_id': customerId,
        'name': name,
        'phone': phone,
        'address': address,
        'LicenceNo': licenceNo,
        'licenceNo': licenceNo,
        'LicenseNo': licenceNo,
        'LicenceExpiry': _dateToJson(licenceExpiry),
        'licenceExpiry': _dateToJson(licenceExpiry),
        'LicenseExpiry': _dateToJson(licenceExpiry),
        'documents': documents,
        'agency_id': agencyId,
        'agencyId': agencyId,
        'pending_amount': pendingAmount,
      };

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    final raw = _readString(json, keys);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static String? _dateToJson(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
