import 'package:flutter/material.dart';

import 'Profile.dart';
import 'Teams.dart';

class OrganisationPage extends StatelessWidget {
  const OrganisationPage({super.key});

  void _openTeams(
    BuildContext context,
    String organisationId,
    String organisationName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TeamsPage(
          organisationId: organisationId,
          organisationName: organisationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'Good morning, Alan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Good morning, Alan', style: TextStyle(fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search organizations...',
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
                      'Organizations',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '3 results',
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
                  OrganizationCard(
                    organizationId: 'org-1',
                    name: 'Org Sample 1',
                    link: 'org1.com',
                    members: 24,
                    avatarColor: Colors.pink,
                    onManage: () {},
                    onOpenTeams: (id, name) => _openTeams(context, id, name),
                  ),
                  const SizedBox(height: 12),
                  OrganizationCard(
                    organizationId: 'org-2',
                    name: 'Org Sample 2',
                    link: 'org2.com',
                    members: 16,
                    avatarColor: Colors.teal,
                    onManage: () {},
                    onOpenTeams: (id, name) => _openTeams(context, id, name),
                  ),
                  const SizedBox(height: 12),
                  OrganizationCard(
                    organizationId: 'org-3',
                    name: 'Org Sample 3',
                    link: 'org3.com',
                    members: 32,
                    avatarColor: Colors.red,
                    onManage: () {},
                    onOpenTeams: (id, name) => _openTeams(context, id, name),
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
              onPressed: () {},
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const Profile(),
                  ),
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

class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    super.key,
    required this.organizationId,
    required this.name,
    required this.link,
    required this.members,
    required this.avatarColor,
    required this.onManage,
    required this.onOpenTeams,
  });

  final String organizationId;
  final String name;
  final String link;
  final int members;
  final Color avatarColor;
  final VoidCallback onManage;
  final void Function(String organisationId, String organisationName)
  onOpenTeams;

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
                  name.isEmpty ? '' : name.substring(0, 1).toUpperCase(),
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
                      link,
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
                onPressed: onManage,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  backgroundColor: const Color(0xFFF3F4F6),
                  overlayColor: Colors.blue,
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
                  onTap: () => onOpenTeams(organizationId, name),
                  radius: 20,
                  child: Tooltip(
                    message: 'View teams in $name',
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
