class StoreProfile {
  final String outletName;
  final String address;
  final String phoneNumber;
  final String receiptCustomText;

  StoreProfile({
    required this.outletName,
    required this.address,
    required this.phoneNumber,
    this.receiptCustomText = '',
  });

  Map<String, dynamic> toJson() => {
    'outletName': outletName,
    'address': address,
    'phoneNumber': phoneNumber,
    'receiptCustomText': receiptCustomText,
  };

  factory StoreProfile.fromJson(Map<String, dynamic> json) => StoreProfile(
    outletName: json['outletName'] ?? json['outlet_name'] ?? 'Kedai Kopi Aksiva',
    address: json['address'] ?? '',
    phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
    receiptCustomText: json['receiptCustomText'] ?? json['receipt_custom_text'] ?? '',
  );

  StoreProfile copyWith({
    String? outletName,
    String? address,
    String? phoneNumber,
    String? receiptCustomText,
  }) {
    return StoreProfile(
      outletName: outletName ?? this.outletName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      receiptCustomText: receiptCustomText ?? this.receiptCustomText,
    );
  }
}
