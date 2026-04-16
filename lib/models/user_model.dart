import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role; // admin, watchman, member
  final String? unitNumber;
  final String? subGroup;
  final String? blockName;
  final String? fcmToken;
  final String? phone;
  final String? societyId;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.unitNumber,
    this.subGroup,
    this.blockName,
    this.fcmToken,
    this.phone,
    this.societyId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      unitNumber: data['unitNumber'],
      subGroup: data['subGroup'],
      blockName: data['blockName'],
      fcmToken: data['fcmToken'],
      phone: data['phone'] as String?,
      societyId: data['societyId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'unitNumber': unitNumber,
      'subGroup': subGroup,
      'blockName': blockName,
      'fcmToken': fcmToken,
      'phone': phone,
      'societyId': societyId,
    };
  }

  @override
  List<Object?> get props =>
      [uid, name, email, role, unitNumber, blockName, subGroup, fcmToken, phone, societyId];
}
