import 'dart:convert';

OrganisationMembersResponse organisationMembersResponseFromJson(String str) =>
    OrganisationMembersResponse.fromJson(json.decode(str));

String organisationMembersResponseToJson(OrganisationMembersResponse data) =>
    json.encode(data.toJson());

class OrganisationMembersResponse {
  final int? organizationId;
  final bool canManage;
  final List<OrganisationMember> members;

  OrganisationMembersResponse({
    this.organizationId,
    required this.canManage,
    required this.members,
  });

  factory OrganisationMembersResponse.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] ?? [];
    if (rawMembers is! List) {
      throw const FormatException('Invalid members list.');
    }

    return OrganisationMembersResponse(
      organizationId: json['organizationId'] as int?,
      canManage: json['canManage'] == true,
      members: rawMembers
          .whereType<Map<String, dynamic>>()
          .map(OrganisationMember.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'canManage': canManage,
    'members': members.map((member) => member.toJson()).toList(),
  };
}

class OrganisationMember {
  final int? teamMemberId;
  final int? userId;
  final String userName;
  final String email;
  final int? teamId;
  final String teamName;

  OrganisationMember({
    this.teamMemberId,
    this.userId,
    required this.userName,
    required this.email,
    this.teamId,
    required this.teamName,
  });

  factory OrganisationMember.fromJson(Map<String, dynamic> json) {
    String readText(dynamic value) => value is String ? value : '';

    return OrganisationMember(
      teamMemberId: json['teamMemberId'] as int?,
      userId: json['userId'] as int?,
      userName: readText(json['userName']),
      email: readText(json['email']),
      teamId: json['teamId'] as int?,
      teamName: readText(json['teamName']),
    );
  }

  Map<String, dynamic> toJson() => {
    'teamMemberId': teamMemberId,
    'userId': userId,
    'userName': userName,
    'email': email,
    'teamId': teamId,
    'teamName': teamName,
  };
}
