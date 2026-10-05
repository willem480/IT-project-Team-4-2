import 'package:flutter/material.dart';

import 'Profile.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key, required this.teamId, required this.isManager});

  final String teamId;
  // Passed through TeamsPage from the owning organisation.
  final bool isManager;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  // Each organisation's mock teams have distinct IDs, matching TeamsPage.
  static const _mockRosters = {
    'product-design': [
      'Sarah Chen',
      'James Davis',
      'Ava Singh',
      'Emily Wong',
      'Ben Walker',
      'Clara Kim',
      'Daniel Park',
    ],
    'engineering': ['James Davis', 'Ava Singh', 'Daniel Park'],
    'marketing': ['Emily Wong', 'Ben Walker', 'Clara Kim'],
    'customer-success': ['Sarah Chen', 'Clara Kim'],
  };

  static final _membersByTeam = {
    for (final organisationId in ['org-1', 'org-2', 'org-3'])
      for (final roster in _mockRosters.entries)
        '$organisationId-${roster.key}': roster.value,
  };

  static const _avatarColors = {
    'Sarah Chen': Color(0xFFEC4899),
    'James Davis': Color(0xFF10B981),
    'Ava Singh': Color(0xFF8B5CF6),
    'Emily Wong': Color(0xFFF59E0B),
    'Ben Walker': Color(0xFFEF4444),
    'Clara Kim': Color(0xFF3B82F6),
    'Daniel Park': Color(0xFF10B981),
  };

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = _membersByTeam[widget.teamId] ?? const <String>[];
    final visibleMembers = members
        .where((name) => name.toLowerCase().contains(_query))
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
              child: visibleMembers.isEmpty
                  ? Center(
                      child: Text(
                        members.isEmpty
                            ? 'No members in this team yet.'
                            : 'No members match your search.',
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
                        isManager: widget.isManager,
                        name: visibleMembers[index],
                        avatarColor:
                            _avatarColors[visibleMembers[index]] ??
                            const Color(0xFF10B981),
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
                  // Pop this page and its owning TeamsPage back to Organisation.
                  var poppedRoutes = 0;
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst || poppedRoutes++ == 2,
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
    required this.name,
    required this.avatarColor,
    required this.isManager,
  });

  final String name;
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
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isManager ? () {} : null,
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
