import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'Members.dart';
import 'models/Teams_model.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({
    super.key,
    required this.userId,
    required this.organizationId,
    required this.organisationName,
  });

  final int userId;
  final int organizationId;
  final String organisationName;

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<Team> teams = [];
  bool canManage = false;
  static const _avatarColors = [
    Colors.pink,
    Colors.teal,
    Colors.red,
    Colors.blue,
  ];

  String _query = '';

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  void fetchTeams() async {
    final url = Uri.parse(
      'http://127.0.0.1:4523/m1/8806835-8598944-default/organization/getOrganizationTeams?organizationId=${widget.organizationId}&viewerUserId=${widget.userId}',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final parsedResponse = teamsResponseFromJson(response.body);
        if (!mounted) return;
        setState(() {
          teams = parsedResponse.teams;
          canManage = parsedResponse.canManage;
        });
        debugPrint('Teams loaded: ${teams.length}');
      } else {
        debugPrint('Failed to load teams: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load teams: $e');
    }
  }

  void _openMembers(BuildContext context, int teamId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MembersPage(
          teamId: teamId,
          userId: widget.userId,
          isManager: canManage,
        ),
      ),
    );
  }

  void _openAdmin(BuildContext context, int teamId) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminPage(userId: widget.userId, teamId: teamId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTeams = teams
        .where((team) => team.name.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Alan',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search teams, members...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Your Teams',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${visibleTeams.length} results',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: visibleTeams.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final team = visibleTeams[index];
                  return _TeamCard(
                    isManager: canManage,
                    teamId: team.teamId,
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: team.name,
                    description: 'Loading...',
                    members: team.memberCount,
                    initials: team.name
                        .trim()
                        .split(RegExp(r'\s+'))
                        .where((word) => word.isNotEmpty)
                        .take(2)
                        .map((word) => word.characters.first)
                        .join()
                        .toUpperCase(),
                    avatarColor:
                        _avatarColors[teams.indexOf(team) %
                            _avatarColors.length],
                    onManage: () => _openAdmin(context, team.teamId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.bookmark_border,
                size: 25,
                color: Colors.black,
              ),
              label: const Text(
                'Organization',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 60),
            TextButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const Profile(),
                  ),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(
                Icons.person_2_outlined,
                size: 25,
                color: Colors.black,
              ),
              label: const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.teamId,
    required this.onOpenMembers,
    required this.initials,
    required this.name,
    required this.description,
    required this.members,
    required this.avatarColor,
    required this.onManage,
    required this.isManager,
  });

  final int teamId;
  final bool isManager;
  final ValueChanged<int> onOpenMembers;
  final String initials;
  final String name;
  final String description;
  final int members;
  final Color avatarColor;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isManager ? onManage : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF065F46),
                  backgroundColor: const Color(0xFFD1FAE5),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  disabledBackgroundColor: const Color(0xFFF3F4F6),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Manage',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFE5E7EB)),
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 20,
                child: Stack(
                  children: [
                    for (var index = 0; index < 3; index++)
                      Positioned(
                        left: index * 16.0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: const [
                              Color(0xFFFCE7F3),
                              Color(0xFFCCFBF1),
                              Color(0xFFDBEAFE),
                            ][index],
                            child: const Icon(
                              Icons.person,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$members members',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkResponse(
                  onTap: () => onOpenMembers(teamId),
                  radius: 20,
                  child: Tooltip(
                    message: 'View members of $name',
                    child: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
