class AddressModel {
  double? latitude;
  double? longitude;
  String? address;

  AddressModel({this.latitude, this.longitude, this.address});

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {"latitude": latitude, "longitude": longitude, "address": address};
  }
}
