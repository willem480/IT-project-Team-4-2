import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Profile.dart';
import 'Members.dart';
import 'Teams.dart';
import 'models/organisation_model.dart';

class OrganisationPage extends StatefulWidget {
  const OrganisationPage({super.key, required this.userId});

  final int userId;

  @override
  State<OrganisationPage> createState() => _OrganisationPageState();
}

class _OrganisationPageState extends State<OrganisationPage> {
  List<OrganisationModel> organisations = [];
  static const _avatarColors = [Colors.pink, Colors.teal, Colors.red];

  String _query = '';

  @override
  void initState() {
    super.initState();
    fetchOrganisations();
  }

  void fetchOrganisations() async {
    final url = Uri.parse(
      'http://127.0.0.1:4523/m1/8806835-8598944-default/organization/getOrganizations?viewerUserId=${widget.userId}',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final parsedOrganisations = organisationFromJson(response.body);
        if (!mounted) return;
        setState(() {
          organisations = parsedOrganisations;
        });
        debugPrint('Organisations loaded: ${organisations.length}');
      } else {
        debugPrint('Failed to load organisations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load organisations: $e');
    }
  }

  void _openTeams(
    BuildContext context,
    int organisationId,
    String organisationName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TeamsPage(
          userId: widget.userId,
          organizationId: organisationId,
          organisationName: organisationName,
        ),
      ),
    );
  }

  void _openMembers(BuildContext context, OrganisationModel organisation) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MembersPage(
          organisationId: organisation.organizationId,
          userId: widget.userId,
          isManager: organisation.canManage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrganisations = organisations
        .where(
          (organisation) => organisation.name.toLowerCase().contains(_query),
        )
        .toList();

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
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Organizations',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${visibleOrganisations.length} results',
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
                itemCount: visibleOrganisations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final organisation = visibleOrganisations[index];
                  return OrganizationCard(
                    isManager: organisation.canManage,
                    organizationId: organisation.organizationId,
                    name: organisation.name,
                    members: organisation.memberCount,
                    avatarColor:
                        _avatarColors[organisations.indexOf(organisation) %
                            _avatarColors.length],
                    onManage: () {},
                    onOpenMembers: () => _openMembers(context, organisation),
                    onOpenTeams: (id, name) => _openTeams(context, id, name),
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
    required this.members,
    required this.avatarColor,
    required this.onManage,
    required this.onOpenTeams,
    required this.onOpenMembers,
    required this.isManager,
  });

  final int organizationId;
  final bool isManager;
  final String name;
  final int members;
  final Color avatarColor;
  final VoidCallback onManage;
  final VoidCallback onOpenMembers;
  final void Function(int organisationId, String organisationName) onOpenTeams;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenMembers,
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
                      // Preserve the subtitle line's spacing without a mock link.
                      const Text(
                        '',
                        style: TextStyle(
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
      ),
    );
  }
}
