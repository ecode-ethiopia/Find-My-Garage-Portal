import 'package:cloud_firestore/cloud_firestore.dart';

class Garage{
  final String name;
  final String address;
  final String telNo;
  final String vehicleCategory;
  final String specializedIn;
  final String openTime;
  final String closeTime;
  final String closedDates;
  final String coordinates;
  final bool canHandleCritical;

  Garage(this.name, this.address, this.telNo, this.vehicleCategory, this
      .specializedIn, this.openTime, this.closeTime, this.closedDates, this
      .coordinates, this.canHandleCritical);

  Map<String, dynamic> toDocument() => <String, dynamic>{
    'name': name,
    'address': address,
    'telNo': telNo,
    'vehicleCategory': vehicleCategory,
    'specializedIn': specializedIn,
    'openTime': openTime,
    'closeTime': closeTime,
    'closedDates': closedDates,
    'coordinates': coordinates,
    'canHandleCritical': canHandleCritical,
  };

  factory Garage.fromDocument(DocumentSnapshot document){
    Garage newGarage = new Garage(
      document["name"],
      document["address"],
      document["telNo"],
      document["vehicleCategory"],
      document["specializedIn"],
      document["openTime"],
      document["closeTime"],
      document["closedDates"],
      document["coordinates"],
      document["canHandleCritical"],
    );
    return newGarage;
  }
}