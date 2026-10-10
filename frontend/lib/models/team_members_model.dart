import 'dart:convert';

TeamMembersResponse teamMembersResponseFromJson(String str) =>
    TeamMembersResponse.fromJson(json.decode(str));

String teamMembersResponseToJson(TeamMembersResponse data) =>
    json.encode(data.toJson());

class TeamMembersResponse {
  final int teamId;
  final int organizationId;
  final bool canManage;
  final List<TeamMember> members;

  TeamMembersResponse({
    required this.teamId,
    required this.organizationId,
    required this.canManage,
    required this.members,
  });

  factory TeamMembersResponse.fromJson(Map<String, dynamic> json) {
    return TeamMembersResponse(
      teamId: json['teamId'] as int,
      organizationId: json['organizationId'] as int,
      canManage: json['canManage'] as bool,
      members: (json['members'] as List<dynamic>)
          .map((member) => TeamMember.fromJson(member as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'organizationId': organizationId,
    'canManage': canManage,
    'members': members.map((member) => member.toJson()).toList(),
  };
}

class TeamMember {
  final int teamMemberId;
  final int userId;
  final String userName;
  final String email;

  TeamMember({
    required this.teamMemberId,
    required this.userId,
    required this.userName,
    required this.email,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      teamMemberId: json['teamMemberId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamMemberId': teamMemberId,
    'userId': userId,
    'userName': userName,
    'email': email,
  };
}
