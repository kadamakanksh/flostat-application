class UserModel {
  String email;
  String firstName;
  String lastName;
  String token;

  UserModel({required this.email, required this.firstName, required this.lastName, required this.token});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      token: json['token'],
    );
  }
}
