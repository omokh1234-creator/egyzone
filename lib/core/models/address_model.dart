class Address {
  final dynamic addressId;
  final String street;
  final String city;
  final String country;
  final dynamic customerId;

  Address({
    this.addressId,
    required this.street,
    required this.city,
    required this.country,
    this.customerId,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['addressId'] ?? json['id'],
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      customerId: json['customerId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'country': country,
      };

  @override
  String toString() => '$street, $city, $country';
}
