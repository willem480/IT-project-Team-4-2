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
        idUser: json["idUser"] as int? ?? 0,
        name: json["name"]?.toString() ?? 'User',
        email: json["email"]?.toString() ?? 'unknown@email.com',

        totalEarnings: (json["totalEarnings"] as num?)?.toInt() ?? 0,
        totalEarningsThisMonth: (json["totalEarningsThisMonth"] as num?)?.toInt() ?? 0,
        numberOfEarningsThisMonth: (json["numberOfEarningsThisMonth"] as num?)?.toInt() ?? 0,
        percentageEarningsCompareToLastMonth: (json["percentageEarningsCompareToLastMonth"] as num?)?.toInt() ?? 0,

        description: json["description"]?.toString() ?? 'no description',

        isSubscribed: json["subscribeEmail"] as bool? ?? false,
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
