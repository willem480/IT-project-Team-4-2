import 'package:flutter/material.dart';

import 'Profile.dart';
import 'Members.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({
    super.key,
    required this.organisationId,
    required this.organisationName,
    required this.isManager,
  });

  final String organisationId;
  final String organisationName;
  // Inherited from the organisation that opened this page.
  final bool isManager;

  void _openMembers(BuildContext context, String teamId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MembersPage(teamId: teamId, isManager: isManager),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Your Teams',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '4 results',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _TeamCard(
                    isManager: isManager,
                    teamId: '$organisationId-product-design',
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: 'Product Design',
                    description: 'Design & research',
                    members: 12,
                    initials: 'PD',
                    avatarColor: Colors.pink,
                    onManage: () {},
                  ),
                  const SizedBox(height: 12),
                  _TeamCard(
                    isManager: isManager,
                    teamId: '$organisationId-engineering',
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: 'Engineering',
                    description: 'Platform & development',
                    members: 34,
                    initials: 'EN',
                    avatarColor: Colors.teal,
                    onManage: () {},
                  ),
                  const SizedBox(height: 12),
                  _TeamCard(
                    isManager: isManager,
                    teamId: '$organisationId-marketing',
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: 'Marketing',
                    description: 'Brand & growth',
                    members: 8,
                    initials: 'MK',
                    avatarColor: Colors.red,
                    onManage: () {},
                  ),
                  const SizedBox(height: 12),
                  _TeamCard(
                    isManager: isManager,
                    teamId: '$organisationId-customer-success',
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: 'Customer Success',
                    description: 'Support & experience',
                    members: 10,
                    initials: 'CS',
                    avatarColor: Colors.blue,
                    onManage: () {},
                  ),
                ],
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

  final String teamId;
  final bool isManager;
  final ValueChanged<String> onOpenMembers;
  final String initials;
  final String name;
  final String description;
  final int members;
  final Color avatarColor;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpenMembers(teamId),
      child: Container(
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
                GestureDetector(
                  // A disabled Manage button must not trigger the card's tap.
                  onTap: isManager ? null : () {},
                  excludeFromSemantics: true,
                  child: TextButton(
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
      ),
    );
  }
}
