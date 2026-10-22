import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Organisation.dart';
import 'Profile.dart';
import 'Members.dart';
import 'models/Teams_model.dart';
import 'report.dart';

Future<List<({int userId, String name})>> fetchOrganisationManagers(
  int organisationId,
) async {
  final response = await http
      .get(
        Uri.parse(
          'http://127.0.0.1:8080/organization/getOrganizationManagers?organizationId=$organisationId',
        ),
        headers: {'Content-Type': 'application/json'},
      )
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw Exception('Manager request failed (${response.statusCode})');
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  final managers = data.map((item) {
    final manager = item as Map<String, dynamic>;
    final name = (manager['userName'] as String).trim();
    return (
      userId: manager['userId'] as int,
      name: name.isEmpty ? 'Manager' : name,
    );
  }).toList();
  return managers;
}

class TeamsPage extends StatefulWidget {
  const TeamsPage({
    super.key,
    required this.userId,
    this.userName = '',
    required this.organizationId,
    required this.organisationName,
  });

  final int userId;
  final String userName;
  final int organizationId;
  final String organisationName;

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<Team> teams = [];
  Map<int, bool> _teamMembership = {};
  bool canManage = false;
  List<({int userId, String name})> _managers = [];
  String? _managerError;
  static const _avatarColors = [
    Colors.pink,
    Colors.teal,
    Colors.red,
    Colors.blue,
  ];

  String _query = '';
  int? _renamingTeamId;
  bool _isAddingTeam = false;
  bool _isSubmittingTeam = false;
  int? _removingTeamId;
  bool _isSubmittingRemoval = false;

  bool get _teamActionInProgress =>
      _isAddingTeam || _removingTeamId != null || _renamingTeamId != null;

  @override
  void initState() {
    super.initState();
    organisationGreeting.load(userId: widget.userId, userName: widget.userName);
    fetchTeams();
    _fetchManagers();
  }

  @override
  void didUpdateWidget(covariant TeamsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userName != widget.userName) {
      organisationGreeting.load(
        userId: widget.userId,
        userName: widget.userName,
      );
    }
  }

  Future<void> fetchTeams() async {
    final url = Uri.parse(
      'http://127.0.0.1:8080/organization/getOrganizationTeams?organizationId=${widget.organizationId}&viewerUserId=${widget.userId}',
    );

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final parsedResponse = TeamsResponse.fromJson(data);
        final membership = {
          for (final team in data['teams'] as List<dynamic>)
            team['teamId'] as int:
                (team['teamMember'] ?? team['isTeamMember']) == true,
        };
        if (!mounted) return;
        setState(() {
          teams = parsedResponse.teams;
          _teamMembership = membership;
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

  Future<void> _fetchManagers() async {
    try {
      final managers = await fetchOrganisationManagers(widget.organizationId);
      if (!mounted) return;
      setState(() {
        _managers = managers;
        _managerError = managers.isEmpty ? 'No managers' : null;
      });
    } catch (error) {
      debugPrint('Failed to load managers: $error');
      if (!mounted) return;
      setState(() => _managerError = 'Managers unavailable');
    }
  }

  Future<String?> _showTeamNameDialog({String? initialName}) {
    final formKey = GlobalKey<FormState>();
    var teamName = '';
    var submitted = false;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          if (submitted || !formKey.currentState!.validate()) return;
          formKey.currentState!.save();
          submitted = true;
          Navigator.pop(dialogContext, teamName);
        }

        return AlertDialog(
          title: Text(initialName == null ? 'Add Team' : 'Rename Team'),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: initialName,
              autofocus: true,
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Team name'),
              validator: (value) {
                final trimmedName = value?.trim() ?? '';
                if (trimmedName.isEmpty) {
                  return 'Please enter a team name.';
                }
                if (trimmedName.length > 200) {
                  return 'Name must be 200 characters or fewer.';
                }
                return null;
              },
              onSaved: (value) => teamName = value!.trim(),
              onFieldSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submit,
              child: Text(initialName == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTeam() async {
    if (!canManage || _teamActionInProgress) return;
    setState(() => _isAddingTeam = true);
    try {
      final name = await _showTeamNameDialog();
      if (name == null || !mounted) return;

      setState(() => _isSubmittingTeam = true);
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8080/organization/addTeam'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': widget.userId,
              'organizationId': widget.organizationId,
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 201) {
        final team = Team.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
        setState(() => teams = [...teams, team]);
        await fetchTeams();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 201
                  ? 'Team added successfully.'
                  : _teamError(response, action: 'add'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to add team. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTeam = false;
          _isSubmittingTeam = false;
        });
      }
    }
  }

  Future<void> _removeTeam(Team team) async {
    if (!canManage || _teamActionInProgress) return;
    setState(() => _removingTeamId = team.teamId);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove this team?'),
          content: Text(
            'Are you sure you want to remove "${team.name}"? '
            'User accounts will be kept. This action cannot be undone.',
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
      final response = await http
          .delete(
            Uri.parse('http://127.0.0.1:8080/organization/removeTeam').replace(
              queryParameters: {
                'actorUserId': '${widget.userId}',
                'organizationId': '${widget.organizationId}',
                'teamId': '${team.teamId}',
              },
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      final succeeded = response.statusCode >= 200 && response.statusCode < 300;
      if (succeeded) {
        setState(() {
          teams.removeWhere((item) => item.teamId == team.teamId);
          _teamMembership.remove(team.teamId);
        });
        await fetchTeams();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              succeeded
                  ? 'Team removed successfully.'
                  : _teamError(response, action: 'remove'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to remove team. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _removingTeamId = null;
          _isSubmittingRemoval = false;
        });
      }
    }
  }

  Future<void> _renameTeam(Team team) async {
    if (!canManage || _teamActionInProgress) return;
    setState(() => _renamingTeamId = team.teamId);
    try {
      final name = await _showTeamNameDialog(initialName: team.name);
      if (!mounted || name == null || name == team.name) return;

      final response = await http
          .patch(
            Uri.parse('http://127.0.0.1:8080/team/updateTeam'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': widget.userId,
              'teamId': team.teamId,
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final updated = Team.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
        setState(() {
          teams = teams
              .map((item) => item.teamId == updated.teamId ? updated : item)
              .toList();
        });
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? 'Team renamed successfully.'
                  : _teamError(response, action: 'rename'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to rename team. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _renamingTeamId = null);
    }
  }

  String _teamError(http.Response response, {required String action}) {
    if (response.statusCode == 403) {
      return 'Only an organisation manager can $action this team.';
    }
    if (response.statusCode == 404) {
      return action == 'rename'
          ? 'The team no longer exists. Please refresh.'
          : 'The organisation or team no longer exists. Please refresh.';
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      }
    } on FormatException {
      // Fall back to a readable message for non-JSON responses.
    }
    if (action != 'remove' &&
        (response.statusCode == 400 || response.statusCode == 409)) {
      return 'Check the team name. It may already exist in this organisation.';
    }
    return 'Unable to $action team (HTTP ${response.statusCode}). Please try again.';
  }

  void _openMembers(BuildContext context, int teamId) {
    if (!canManage && _teamMembership[teamId] != true) return;
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

  @override
  Widget build(BuildContext context) {
    final visibleTeams = teams
        .where((team) => team.name.toLowerCase().contains(_query))
        .toList();
    visibleTeams.sort((a, b) {
      if (!canManage) {
        final aIsMember = _teamMembership[a.teamId] ?? false;
        final bIsMember = _teamMembership[b.teamId] ?? false;
        if (aIsMember != bIsMember) return aIsMember ? -1 : 1;
      }
      final nameOrder = a.name.trim().toLowerCase().compareTo(
        b.name.trim().toLowerCase(),
      );
      if (nameOrder != 0) return nameOrder;
      final caseOrder = a.name.compareTo(b.name);
      return caseOrder != 0 ? caseOrder : a.teamId.compareTo(b.teamId);
    });

    return Scaffold(
      appBar: organisationGreeting.appBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Expanded(
                    child: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Teams',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Add team',
                            onPressed: _teamActionInProgress ? null : _addTeam,
                            iconSize: 26,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.blue,
                              backgroundColor: Colors.transparent,
                              fixedSize: const Size(40, 40),
                              padding: const EdgeInsets.all(7),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: _isSubmittingTeam
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                      semanticsLabel: 'Adding team',
                                    ),
                                  )
                                : const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ],
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
                    isTeamMember: _teamMembership[team.teamId] ?? false,
                    teamId: team.teamId,
                    onOpenMembers: (id) => _openMembers(context, id),
                    name: team.name,
                    managers: _managers,
                    managerError: _managerError,
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
                    onReport: () {
                      if (!canManage) return;
                      openReport(
                        this.context,
                        userId: widget.userId,
                        teamId: team.teamId,
                      );
                    },
                    onRemove: !_teamActionInProgress
                        ? () => _removeTeam(team)
                        : null,
                    isRemoving:
                        _isSubmittingRemoval && _removingTeamId == team.teamId,
                    onRename: !_teamActionInProgress
                        ? () => _renameTeam(team)
                        : null,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onPressed: () => Navigator.maybePop(context),
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
            const SizedBox(width: 60),
            TextButton.icon(
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
    required this.managers,
    required this.managerError,
    required this.members,
    required this.avatarColor,
    required this.onReport,
    required this.isManager,
    required this.isTeamMember,
    this.onRename,
    this.onRemove,
    this.isRemoving = false,
  });

  final int teamId;
  final bool isManager;
  final bool isTeamMember;
  final ValueChanged<int> onOpenMembers;
  final String initials;
  final String name;
  final List<({int userId, String name})> managers;
  final String? managerError;
  final int members;
  final Color avatarColor;
  final VoidCallback onReport;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;
  final bool isRemoving;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isManager || isTeamMember ? () => onOpenMembers(teamId) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isManager)
                              IconButton(
                                tooltip: 'Rename team',
                                onPressed: onRename,
                                icon: const Icon(Icons.edit, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ManagerPreview(
                          managers: managers,
                          managerError: managerError,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isManager)
                    IconButton(
                      tooltip: 'Remove team',
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
                                semanticsLabel: 'Removing team',
                              ),
                            )
                          : const Icon(Icons.remove_circle_outline),
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
                  if (!isManager && !isTeamMember) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'You are not in this team.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isManager ? null : () {},
                    excludeFromSemantics: true,
                    child: TextButton(
                      onPressed: isManager ? onReport : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1D4ED8),
                        backgroundColor: const Color(0xFFDBEAFE),
                        disabledForegroundColor: const Color(0xFF9CA3AF),
                        disabledBackgroundColor: const Color(0xFFF3F4F6),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Report',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManagerPreview extends StatelessWidget {
  const ManagerPreview({
    super.key,
    this.managers = const [],
    this.managerError,
  });

  final List<({int userId, String name})> managers;
  final String? managerError;

  @override
  Widget build(BuildContext context) {
    if (managers.isEmpty) {
      return SizedBox(
        height: 20,
        child: Text(
          managerError ?? '',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      );
    }
    final preview = managers.take(3).toList();
    final names = preview.map((manager) => manager.name).join(', ');
    return Row(
      children: [
        SizedBox(
          width: 20 + (preview.length - 1) * 14.0,
          height: 20,
          child: Stack(
            children: [
              for (var index = 0; index < preview.length; index++)
                Positioned(
                  left: index * 14.0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 9,
                      // Keep each random colour stable across card rebuilds.
                      backgroundColor: Colors
                          .primaries[Random(preview[index].userId)
                              .nextInt(Colors.primaries.length)]
                          .shade600,
                      child: Text(
                        preview[index].name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            managers.length > 3 ? '$names...' : names,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
