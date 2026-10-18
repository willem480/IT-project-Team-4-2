import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'models/team_members_model.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({
    super.key,
    required this.teamId,
    required this.userId,
    this.userName = '',
    required this.isManager,
  });

  final int teamId;
  final int userId;
  final String userName;
  // Retained for existing callers; the members API determines permission.
  final bool isManager;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String _userName = '';

  String get _displayName => _userName.isEmpty ? 'Loading...' : _userName;

  Future<void> _fetchUserName() async {
    // Reuse the current user's name when a parent page has already loaded it.
    if (_userName.isNotEmpty) return;
    final userId = widget.userId;
    try {
      final response = await http
          .post(
            Uri.parse(
              'http://127.0.0.1:8080/profilePage/getUser?userId=$userId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('User profile request failed (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final name = (data['name'] as String?)?.trim() ?? '';
      if (!mounted || widget.userId != userId || _userName.isNotEmpty) return;
      setState(() => _userName = name.isEmpty ? 'User' : name);
    } catch (error) {
      debugPrint('Failed to load greeting name for user $userId: $error');
      if (!mounted || widget.userId != userId || _userName.isNotEmpty) return;
      setState(() => _userName = 'User');
    }
  }

  List<({int? teamMemberId, String name, String email})> members = [];
  bool canManage = false;
  bool _isLoading = true;
  String? _errorMessage;
  // Used for Team Member Admin navigation.
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
    _userName = widget.userName.trim();
    _fetchUserName();
    fetchMembers();
  }

  @override
  void didUpdateWidget(covariant MembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userName != widget.userName) {
      _userName = widget.userName.trim();
      _fetchUserName();
    }
  }

  void fetchMembers() async {
    final url = Uri.parse(
      'http://127.0.0.1:8080/team/getTeamMembers?teamId=${widget.teamId}&viewerUserId=${widget.userId}',
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
        final teamResponse = TeamMembersResponse.fromJson(parsedResponse);
        final parsedMembers = teamResponse.members
            .map(
              (member) => (
                teamMemberId: member.teamMemberId,
                name: member.userName,
                email: member.email,
              ),
            )
            .toList();
        if (!mounted) return;
        setState(() {
          members = parsedMembers;
          canManage = teamResponse.canManage;
          _organizationId = teamResponse.organizationId;
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

  Future<void> _openAdmin(int teamMemberId) async {
    final organisationId = _organizationId;
    if (organisationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine the organisation.')),
      );
      return;
    }

    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => AdminPage(
          userId: widget.userId,
          userName: _userName,
          organisationId: organisationId,
          teamId: widget.teamId,
          teamMemberId: teamMemberId,
        ),
      ),
    );
    if (deleted == true && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      fetchMembers();
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning,',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              _displayName,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF111827),
              child: Text(
                _displayName.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
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
                  const Flexible(
                    child: Text(
                      'Team Members',
                      style: TextStyle(
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
                                      ? 'No members in this team yet.'
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
                  const routesToPop = 2;
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
                      builder: (context) => Profile(userId: widget.userId),
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
    required this.avatarColor,
    required this.isManager,
  });

  final int? teamMemberId;
  final ValueChanged<int> onManage;
  final String name;
  final String email;
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
