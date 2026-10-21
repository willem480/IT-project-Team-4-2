import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'adminSearch.dart';
import 'models/team_members_model.dart';

typedef _MemberEntry = ({
  int? teamMemberId,
  int userId,
  String name,
  String email,
});

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

  List<_MemberEntry> members = [];
  List<_MemberEntry> _managers = [];
  Set<int> _managerUserIds = {};
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
  bool _isAddingMembers = false;
  int? _removingMemberId;
  bool _isSubmittingRemoval = false;

  bool get _memberActionInProgress =>
      _isAddingMembers || _removingMemberId != null;

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

  Future<void> fetchMembers() async {
    final url = Uri.parse(
      'http://127.0.0.1:8080/team/getTeamMembers?teamId=${widget.teamId}&viewerUserId=${widget.userId}',
    );

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final parsedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (parsedResponse is! Map<String, dynamic>) {
          throw const FormatException('Invalid members response.');
        }
        final teamResponse = TeamMembersResponse.fromJson(parsedResponse);
        if (teamResponse.teamId != widget.teamId) {
          throw const FormatException('Invalid members response.');
        }
        final managersResponse = await http
            .get(
              Uri.parse(
                'http://127.0.0.1:8080/organization/getOrganizationManagers?organizationId=${teamResponse.organizationId}',
              ),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 30));
        if (managersResponse.statusCode != 200) {
          throw Exception('Failed to load organisation managers.');
        }
        // Organisation roles are display-only here; only getTeamMembers supplies
        // membership IDs and entries for the Team Members section.
        final managers =
            (jsonDecode(utf8.decode(managersResponse.bodyBytes)) as List)
                .map<_MemberEntry>(
                  (manager) => (
                    teamMemberId: null,
                    userId: manager['userId'] as int,
                    name: manager['userName'] as String,
                    email: manager['email'] as String,
                  ),
                )
                .toList()
              ..sort((a, b) {
                final aIsCurrentUser = a.userId == widget.userId;
                final bIsCurrentUser = b.userId == widget.userId;
                if (aIsCurrentUser != bIsCurrentUser) {
                  return aIsCurrentUser ? -1 : 1;
                }
                return _comparePeople(a, b);
              });
        final managerUserIds = managers
            .map((manager) => manager.userId)
            .toSet();
        final parsedMembers =
            teamResponse.members
                .map(
                  (member) => (
                    teamMemberId: member.teamMemberId,
                    userId: member.userId,
                    name: member.userName,
                    email: member.email,
                  ),
                )
                .toList()
              ..sort((a, b) {
                final aIsCurrentUser = a.userId == widget.userId;
                final bIsCurrentUser = b.userId == widget.userId;
                if (aIsCurrentUser != bIsCurrentUser) {
                  return aIsCurrentUser ? -1 : 1;
                }
                final aIsManager = managerUserIds.contains(a.userId);
                final bIsManager = managerUserIds.contains(b.userId);
                if (aIsManager != bIsManager) return aIsManager ? -1 : 1;

                return _comparePeople(a, b);
              });
        if (!mounted) return;
        setState(() {
          members = parsedMembers;
          _managers = managers;
          _managerUserIds = managerUserIds;
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

  Future<void> _addMembers() async {
    if (!canManage || _memberActionInProgress) return;
    setState(() => _isAddingMembers = true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MemberSearchDialog(
          actorUserId: widget.userId,
          teamId: widget.teamId,
          onMemberAdded: fetchMembers,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingMembers = false);
    }
  }

  Future<void> _removeMember(_MemberEntry member) async {
    final membershipId = member.teamMemberId;
    if (!canManage || membershipId == null || _memberActionInProgress) return;
    setState(() => _removingMemberId = membershipId);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove this member?'),
          content: Text(
            'Are you sure to remove "${member.name}" from this team? '
      
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _isSubmittingRemoval = true);
      final url = Uri.parse('http://127.0.0.1:8080/team/removeTeamMember')
          .replace(
            queryParameters: {
              'actorUserId': '${widget.userId}',
              'teamId': '${widget.teamId}',
              'teamMemberId': '$membershipId',
            },
          );
      final response = await http
          .delete(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      final succeeded = response.statusCode >= 200 && response.statusCode < 300;
      if (succeeded) {
        setState(() {
          members.removeWhere((item) => item.teamMemberId == membershipId);
        });
        await fetchMembers();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              succeeded
                  ? 'Member removed from the team successfully.'
                  : _removeMemberError(response),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to remove member. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _removingMemberId = null;
          _isSubmittingRemoval = false;
        });
      }
    }
  }

  String _removeMemberError(http.Response response) {
    if (response.statusCode == 403) {
      return 'Only an organisation manager can remove team members.';
    }
    if (response.statusCode == 404) {
      return 'The team or membership no longer exists. Please refresh.';
    }
    final body = utf8.decode(response.bodyBytes).trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      }
    } on FormatException {
      if (body.isNotEmpty && !body.startsWith('<')) return body;
    }
    return 'Unable to remove member (HTTP ${response.statusCode}). Please try again.';
  }

  Future<void> _openAdmin(int teamMemberId) async {
    final organisationId = _organizationId;
    if (organisationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to determine the organisation.')),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminPage(
          userId: widget.userId,
          userName: _userName,
          organisationId: organisationId,
          teamId: widget.teamId,
          teamMemberId: teamMemberId,
        ),
      ),
    );
  }

  static int _comparePeople(_MemberEntry a, _MemberEntry b) {
    final nameOrder = a.name.trim().toLowerCase().compareTo(
      b.name.trim().toLowerCase(),
    );
    return nameOrder != 0 ? nameOrder : a.userId.compareTo(b.userId);
  }

  Widget _sectionHeader(String title, String count, {bool showAdd = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showAdd && canManage) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Add member',
                    onPressed: _memberActionInProgress ? null : _addMembers,
                    iconSize: 26,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.transparent,
                      fixedSize: const Size(40, 40),
                      padding: const EdgeInsets.all(7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personCard(_MemberEntry person, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: MemberCard(
        canManage: canManage,
        isManager: _managerUserIds.contains(person.userId),
        isCurrentUser: person.userId == widget.userId,
        teamMemberId: person.teamMemberId,
        onManage: _openAdmin,
        onRemove: !_memberActionInProgress ? () => _removeMember(person) : null,
        isRemoving:
            _isSubmittingRemoval && _removingMemberId == person.teamMemberId,
        name: person.name,
        email: person.email,
        avatarColor: _avatarColors[index % _avatarColors.length],
      ),
    );
  }

  Widget _emptySection(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleManagers = _managers
        .where((manager) => manager.name.toLowerCase().contains(_query))
        .toList();
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
                  hintText: 'Search managers, members...',
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
            Expanded(
              child: _isLoading || _errorMessage != null
                  ? Center(
                      child: Text(
                        _isLoading ? 'Loading members...' : _errorMessage!,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        _sectionHeader(
                          'Managers',
                          '${visibleManagers.length} managers',
                        ),
                        if (visibleManagers.isEmpty)
                          _emptySection(
                            _managers.isEmpty
                                ? 'No managers in this organisation.'
                                : 'No managers match your search.',
                          ),
                        for (final manager in visibleManagers)
                          _personCard(manager, _managers.indexOf(manager)),
                        _sectionHeader(
                          'Team Members',
                          '${visibleMembers.length} results',
                          showAdd: true,
                        ),
                        if (visibleMembers.isEmpty)
                          _emptySection(
                            members.isEmpty
                                ? 'No members in this team yet.'
                                : 'No members match your search.',
                          ),
                        for (final member in visibleMembers)
                          _personCard(member, members.indexOf(member)),
                      ],
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    color: Colors.blue,
                  ),
                  label: const Text(
                    'Organization',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
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
                  color: Colors.grey,
                ),
                label: const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
    required this.canManage,
    this.isCurrentUser = false,
    this.onRemove,
    this.isRemoving = false,
  });

  final int? teamMemberId;
  final ValueChanged<int> onManage;
  final String name;
  final String email;
  final Color avatarColor;
  final bool isManager;
  final bool canManage;
  final bool isCurrentUser;
  final VoidCallback? onRemove;
  final bool isRemoving;

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
    const avatarSize = 48.0;
    const badgeHeight = 20.0;
    const badgeOverlap = avatarSize / 6;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: avatarSize,
            height: isManager
                ? avatarSize + badgeHeight - badgeOverlap
                : avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarSize / 2,
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
                if (isManager)
                  Positioned(
                    top: avatarSize - badgeOverlap,
                    left: -6,
                    right: -6,
                    height: badgeHeight,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: isCurrentUser ? 1 : null,
                        overflow: isCurrentUser ? TextOverflow.ellipsis : null,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
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
          if (teamMemberId != null) const SizedBox(width: 8),
          if (canManage && teamMemberId != null)
            IconButton(
              tooltip: 'Remove member',
              onPressed: onRemove,
              iconSize: 26,
              style: IconButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.transparent,
                fixedSize: const Size(40, 40),
                padding: const EdgeInsets.all(7),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: isRemoving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                        semanticsLabel: 'Removing member',
                      ),
                    )
                  : const Icon(Icons.remove_circle_outline),
            ),
          if (teamMemberId != null)
            TextButton(
              onPressed: canManage ? () => onManage(teamMemberId!) : null,
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
