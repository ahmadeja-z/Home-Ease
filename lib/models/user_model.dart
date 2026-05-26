import 'address_model.dart';
import 'worker_doc_model.dart';

class UserModel {
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;
  WorkerDocModel? workerDoc;
  AddressModel? address;

  String? status;
  bool? isActive;
  String? verification;

  String? profileImage;

  DateTime? createdAt;
  DateTime? updatedAt;
  String? deviceFcmToken;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.address,
    this.status,
    this.isActive,
    this.verification,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    this.deviceFcmToken,
    this.workerDoc,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      status: json['status'],
      isActive: json['isActive'],
      verification: json['verification'],
      profileImage: json['profileImage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      deviceFcmToken: json['deviceFcmToken'],
      workerDoc: json['workerDoc'] != null
          ? WorkerDocModel.fromJson(json['workerDoc'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phoneNumber": phoneNumber,
      "role": role,
      "address": address?.toJson(),
      "status": status,
      "isActive": isActive,
      "verification": verification,
      "profileImage": profileImage,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "deviceFcmToken": deviceFcmToken,
      "workerDoc": workerDoc?.toJson(),
    };
  }
}
