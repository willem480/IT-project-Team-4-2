import 'dart:convert';

TeamsResponse teamsResponseFromJson(String str) =>
    TeamsResponse.fromJson(json.decode(str));

String teamsResponseToJson(TeamsResponse data) => json.encode(data.toJson());

class TeamsResponse {
  final int organizationId;
  final bool canManage;
  final List<Team> teams;

  TeamsResponse({
    required this.organizationId,
    required this.canManage,
    required this.teams,
  });

  factory TeamsResponse.fromJson(Map<String, dynamic> json) {
    return TeamsResponse(
      organizationId: json['organizationId'] as int,
      canManage: json['canManage'] as bool,
      teams: (json['teams'] as List<dynamic>)
          .map((team) => Team.fromJson(team as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'canManage': canManage,
    'teams': teams.map((team) => team.toJson()).toList(),
  };
}

class Team {
  final int teamId;
  final String name;
  final int memberCount;

  Team({required this.teamId, required this.name, required this.memberCount});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['teamId'] as int,
      name: json['name'] as String,
      memberCount: json['memberCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'name': name,
    'memberCount': memberCount,
  };
}
