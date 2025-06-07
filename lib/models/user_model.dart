import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String firstName;
  final String lastName;
  final String email;
  final String dob;
  final String uid;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dob,
    required this.uid,
  });

  // To map the user object to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dob': dob,
      'uid': uid,
    };
  }

  // To create a UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserModel(
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      dob: data['dob'],
      uid: data['uid'],
    );
  }
}
