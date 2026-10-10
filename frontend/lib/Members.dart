import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'models/organisation_members_model.dart';
import 'models/team_members_model.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({
    super.key,
    this.organisationId,
    this.teamId,
    required this.userId,
    required this.isManager,
  }) : assert(
         (organisationId == null) != (teamId == null),
         'Provide exactly one of organisationId or teamId.',
       );

  final int? organisationId;
  final int? teamId;
  final int userId;
  // Retained for existing callers; the members API determines permission.
  final bool isManager;

  bool get isOrganisationView => organisationId != null;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<({int? teamMemberId, String name, String email, String teamName})>
  members = [];
  bool canManage = false;
  bool _isLoading = true;
  String? _errorMessage;
  // Used for Team Member Admin navigation, not to determine the page source.
  int? _organizationId;

  static const _avatarColors = [
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
  ];

  String _query = '';

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  void fetchMembers() async {
    final url = Uri.parse(
      widget.isOrganisationView
          ? 'http://127.0.0.1:4523/m1/8806835-8598944-default/organization/getOrganizationMembers?organizationId=${widget.organisationId}&viewerUserId=${widget.userId}'
          : 'http://127.0.0.1:4523/m1/8806835-8598944-default/team/getTeamMembers?teamId=${widget.teamId}&viewerUserId=${widget.userId}',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse is! Map<String, dynamic>) {
          throw const FormatException('Invalid members response.');
        }
        final teamResponse = widget.isOrganisationView
            ? null
            : TeamMembersResponse.fromJson(parsedResponse);
        final organisationResponse = widget.isOrganisationView
            ? OrganisationMembersResponse.fromJson(parsedResponse)
            : null;
        final parsedMembers = teamResponse != null
            ? teamResponse.members
                  .map(
                    (member) => (
                      teamMemberId: member.teamMemberId,
                      name: member.userName,
                      email: member.email,
                      teamName: '',
                    ),
                  )
                  .toList()
            : organisationResponse!.members
                  .map(
                    (member) => (
                      teamMemberId: member.teamMemberId,
                      name: member.userName,
                      email: member.email,
                      teamName: member.teamName,
                    ),
                  )
                  .toList();
        if (!mounted) return;
        setState(() {
          members = parsedMembers;
          canManage =
              teamResponse?.canManage ?? organisationResponse!.canManage;
          if (teamResponse != null) {
            _organizationId = teamResponse.organizationId;
          }
          _isLoading = false;
          _errorMessage = null;
        });
        debugPrint('Members loaded: ${members.length}');
      } else {
        debugPrint('Failed to load members: ${response.statusCode}');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load members.';
        });
      }
    } catch (e) {
      debugPrint('Failed to load members: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load members.';
      });
    }
  }

  void _openAdmin(int teamMemberId) {
    final organisationId = widget.isOrganisationView
        ? widget.organisationId
        : _organizationId;
    if (organisationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine the organisation.')),
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminPage(
          userId: widget.userId,
          organisationId: organisationId,
          teamMemberId: teamMemberId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMembers = members
        .where((member) => member.name.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        toolbarHeight: 72,
        title: const Column(
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF111827),
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.isOrganisationView
                          ? 'Organisation Members'
                          : 'Team Members',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${visibleMembers.length} results',
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
              child:
                  _isLoading || _errorMessage != null || visibleMembers.isEmpty
                  ? Center(
                      child: Text(
                        _isLoading
                            ? 'Loading members...'
                            : _errorMessage ??
                                  (members.isEmpty
                                      ? (widget.isOrganisationView
                                            ? 'No members in this organisation yet.'
                                            : 'No members in this team yet.')
                                      : 'No members match your search.'),
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: visibleMembers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => MemberCard(
                        isManager: canManage,
                        teamMemberId: visibleMembers[index].teamMemberId,
                        onManage: _openAdmin,
                        name: visibleMembers[index].name,
                        email: visibleMembers[index].email,
                        teamName: widget.isOrganisationView
                            ? visibleMembers[index].teamName
                            : null,
                        avatarColor:
                            _avatarColors[members.indexOf(
                                  visibleMembers[index],
                                ) %
                                _avatarColors.length],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: TextButton.icon(
                onPressed: () {
                  // Team entry has an extra TeamsPage above Organisation.
                  final routesToPop = widget.isOrganisationView ? 1 : 2;
                  var poppedRoutes = 0;
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst || poppedRoutes++ == routesToPop,
                  );
                },
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
            ),
            const SizedBox(width: 60),
            Flexible(
              child: TextButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }
}

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.teamMemberId,
    required this.onManage,
    required this.name,
    required this.email,
    this.teamName,
    required this.avatarColor,
    required this.isManager,
  });

  final int? teamMemberId;
  final ValueChanged<int> onManage;
  final String name;
  final String email;
  final String? teamName;
  final Color avatarColor;
  final bool isManager;

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(
              _initials,
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
                if (teamName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    teamName!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  email,
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
            onPressed: isManager && teamMemberId != null
                ? () => onManage(teamMemberId!)
                : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF065F46),
              backgroundColor: const Color(0xFFD1FAE5),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              disabledBackgroundColor: const Color(0xFFF3F4F6),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Manage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
