// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

UserProfile welcomeFromJson(String str) => UserProfile.fromJson(json.decode(str));

String welcomeToJson(UserProfile data) => json.encode(data.toJson());

class UserProfile {
    final int idUser;
    final String name;
    final String email;
    final int totalEarnings;
    final int totalEarningsThisMonth;
    final int numberOfEarningsThisMonth;
    final int percentageEarningsCompareToLastMonth;
    final String description;
    final bool? isSubscribed;

    UserProfile({
        required this.idUser,
        required this.name,
        required this.email,
        required this.totalEarnings,
        required this.totalEarningsThisMonth,
        required this.numberOfEarningsThisMonth,
        required this.percentageEarningsCompareToLastMonth,
        required this.description,
        this.isSubscribed,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        idUser: json["idUser"],
        name: json["name"],
        email: json["email"],
        totalEarnings: json["totalEarnings"],
        totalEarningsThisMonth: json["totalEarningsThisMonth"],
        numberOfEarningsThisMonth: json["numberOfEarningsThisMonth"],
        percentageEarningsCompareToLastMonth: json["percentageEarningsCompareToLastMonth"],
        description: json["description"] ?? 'no description',
        isSubscribed: json["isSubscribed"] ?? false,
    );

    Map<String, dynamic> toJson() => {
        "idUser": idUser,
        "name": name,
        "email": email,
        "totalEarnings": totalEarnings,
        "totalEarningsThisMonth": totalEarningsThisMonth,
        "numberOfEarningsThisMonth": numberOfEarningsThisMonth,
        "percentageEarningsCompareToLastMonth": percentageEarningsCompareToLastMonth,
        "description": description,
        "isSubscribed": isSubscribed,

    };
}
