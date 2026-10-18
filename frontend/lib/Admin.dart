import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Profile.dart';
import 'adminSearch.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.userId,
    this.organisationId,
    this.teamId,
    this.teamMemberId,
    this.userName = 'Alan',
  });

  final int userId;
  final int? organisationId;
  // Null when managing an organisation without a selected team.
  final int? teamId;
  final int? teamMemberId;
  final String userName;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isDeleting = false;
  bool _isAddingTeam = false;
  bool _isGeneratingReport = false;
  Map<String, dynamic>? _report;

  void _goBack(BuildContext context) {
    Navigator.maybePop(context);
  }

  void _createUser(BuildContext context) {
    final teamId = widget.teamId;
    if (teamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a team before adding a user.'),
        ),
      );
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminSearchPage(
          userName: widget.userName,
          actorUserId: widget.userId,
          teamId: teamId,
        ),
      ),
    );
  }

  Future<void> _addTeam() async {
    if (_isAddingTeam) return;
    final organisationId = widget.organisationId;
    if (organisationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add team: organisation is missing.'),
        ),
      );
      return;
    }

    setState(() => _isAddingTeam = true);
    try {
      final formKey = GlobalKey<FormState>();
      var teamName = '';
      var submitted = false;
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          void submit() {
            if (submitted || !formKey.currentState!.validate()) return;
            formKey.currentState!.save();
            submitted = true;
            Navigator.pop(dialogContext, teamName);
          }

          return AlertDialog(
            title: const Text('Add Team'),
            content: Form(
              key: formKey,
              child: TextFormField(
                autofocus: true,
                maxLength: 200,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Team name'),
                validator: (value) {
                  final trimmedName = value?.trim() ?? '';
                  if (trimmedName.isEmpty) return 'Please enter a team name.';
                  if (trimmedName.length > 200) {
                    return 'Team name must be 200 characters or fewer.';
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
              FilledButton(onPressed: submit, child: const Text('Add')),
            ],
          );
        },
      );
      if (name == null || !mounted) return;

      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8080/organization/addTeam'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': widget.userId,
              'organizationId': organisationId,
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 201
                  ? 'Team added successfully.'
                  : _addTeamErrorMessage(response),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add team. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isAddingTeam = false);
    }
  }

  String _addTeamErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      }
    } on FormatException {
      // Use a readable fallback when the server does not return JSON.
    }
    switch (response.statusCode) {
      case 400:
        return 'Check the team name. It may already exist in this organisation.';
      case 403:
        return 'Only an organisation manager can add teams.';
      case 404:
        return 'This organisation no longer exists.';
      default:
        return 'Unable to add team (HTTP ${response.statusCode}). Please try again.';
    }
  }

  Future<void> _deleteUser() async {
    if (_isDeleting) return;
    final teamId = widget.teamId;
    final teamMemberId = widget.teamMemberId;
    if (teamId == null || teamMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete user: team or member is missing.'),
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Remove this user from the team?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final url = Uri.parse('http://127.0.0.1:8080/team/removeTeamMember')
          .replace(
            queryParameters: {
              'actorUserId': '${widget.userId}',
              'teamId': '$teamId',
              'teamMemberId': '$teamMemberId',
            },
          );
      final response = await http
          .delete(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      final succeeded = response.statusCode >= 200 && response.statusCode < 300;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              succeeded
                  ? 'User removed from the team successfully.'
                  : _deleteErrorMessage(response),
            ),
          ),
        );
      if (succeeded) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete user. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _deleteErrorMessage(http.Response response) {
    final body = response.body.trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      } else if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
    } on FormatException {
      if (body.isNotEmpty && !body.startsWith('<')) return body;
    }
    return 'Unable to delete user (HTTP ${response.statusCode}). Please try again.';
  }

  void _reportMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _reportErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      } else if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
    } on FormatException {
      // Fall back to the HTTP status for non-JSON responses.
    }
    return 'Unable to load report data (HTTP ${response.statusCode}). Please try again.';
  }

  Future<Map<String, dynamic>> _loadReportData(
    String path,
    Map<String, String> parameters, {
    bool generate = false,
  }) async {
    final url = Uri.parse('http://127.0.0.1:8080$path')
        .replace(queryParameters: parameters);
    final response = await (generate ? http.post(url) : http.get(url)).timeout(
      const Duration(seconds: 30),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(_reportErrorMessage(response));
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('The server returned invalid report data.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The server returned invalid report data.');
    }
    return decoded;
  }

  Future<Map<String, String>?> _memberReportParameters() async {
    final teamIds = <int>[];
    if (widget.teamId != null) {
      teamIds.add(widget.teamId!);
    } else {
      final organisationId = widget.organisationId;
      if (organisationId == null) {
        throw const FormatException(
          'Unable to find this member: organisation is missing.',
        );
      }
      final data = await _loadReportData('/organization/getOrganizationTeams', {
        'organizationId': '$organisationId',
        'viewerUserId': '${widget.userId}',
      });
      if (!mounted) return null;
      final teams = data['teams'];
      if (teams is! List) {
        throw const FormatException(
          'The server returned an invalid team list.',
        );
      }
      for (final team in teams) {
        if (team is Map<String, dynamic> && team['teamId'] is int) {
          teamIds.add(team['teamId'] as int);
        }
      }
    }

    for (final teamId in teamIds) {
      final data = await _loadReportData('/team/getTeamMembers', {
        'teamId': '$teamId',
        'viewerUserId': '${widget.userId}',
      });
      if (!mounted) return null;
      final members = data['members'];
      if (members is! List) {
        throw const FormatException(
          'The server returned an invalid member list.',
        );
      }
      for (final member in members) {
        if (member is Map<String, dynamic> &&
            member['teamMemberId'] == widget.teamMemberId &&
            member['userId'] is int) {
          return {'userId': '${member['userId']}', 'teamId': '$teamId'};
        }
      }
    }
    throw const FormatException(
      'This member could not be found. Please refresh the member list.',
    );
  }

  Future<void> _openReporting() async {
    if (_isGeneratingReport) return;
    setState(() => _isGeneratingReport = true);
    try {
      final String path;
      final Map<String, String> parameters;
      if (widget.teamMemberId != null) {
        path = '/memberReport/generateTeamMemberReport';
        final memberParameters = await _memberReportParameters();
        if (!mounted || memberParameters == null) return;
        parameters = memberParameters;
      } else if (widget.teamId != null) {
        path = '/teamReport/generateTeamReport';
        parameters = {'teamId': '${widget.teamId}'};
      } else {
        if (widget.organisationId == null) {
          throw const FormatException(
            'Unable to generate report: organisation is missing.',
          );
        }
        path = '/organizationReport/generateOrganizationReport';
        parameters = {'organizationId': '${widget.organisationId}'};
      }

      final report = await _loadReportData(path, parameters, generate: true);
      if (!mounted) return;
      if (report['title'] is! String || report['body'] is! String) {
        throw const FormatException('The server returned an invalid report.');
      }
      setState(() => _report = report);
      _reportMessage('Report generated. Select View Report to read it.');
    } on FormatException catch (error) {
      if (mounted) _reportMessage(error.message);
    } catch (_) {
      if (mounted) {
        _reportMessage('Unable to generate report. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  void _viewReport() {
    final report = _report;
    if (report == null) {
      _reportMessage('Generate a report using Reporting first.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(report['title'] as String),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in report.entries)
                  if (entry.key != 'title' && entry.key != 'body')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(
                        '${entry.key}: ${entry.value ?? '-'}',
                      ),
                    ),
                const Divider(),
                SelectableText(report['body'] as String),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userName.trim().isEmpty
        ? 'User'
        : widget.userName.trim();
    final isMemberManagement = widget.teamMemberId != null;
    final isTeamManagement =
        widget.teamId != null && widget.teamMemberId == null;
    final isOrganisationManagement =
        widget.teamId == null && widget.teamMemberId == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        // Allow the entire page to scroll in short windows or with large text.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BackButton(
                    color: Colors.black,
                    onPressed: () => _goBack(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning,',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Open profile',
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => Profile(userId: widget.userId),
                      ),
                    ),
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Text(
                        displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a manager action for organizations or teams',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 36),
              if (isOrganisationManagement) ...[
                _AdminActionCard(
                  icon: Icons.group_add_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  title: _isAddingTeam ? 'Adding Team...' : 'Add Team',
                  description: 'Create a new team in this organisation.',
                  onTap: _isAddingTeam ? null : _addTeam,
                ),
                const SizedBox(height: 30),
              ],
              if (isTeamManagement)
                _AdminActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  title: 'Create User',
                  description: 'Create a new user account.',
                  onTap: () => _createUser(context),
                ),
              if (isMemberManagement)
                _AdminActionCard(
                  icon: Icons.person_remove_outlined,
                  iconColor: const Color(0xFFDC2626),
                  iconBackgroundColor: const Color(0xFFFEF2F2),
                  title: 'Delete User',
                  description: 'Remove or deactivate a user.',
                  onTap: _isDeleting ? null : _deleteUser,
                ),
              if (!isOrganisationManagement) const SizedBox(height: 30),
              _AdminActionCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBackgroundColor: const Color(0xFFF0FDF4),
                title: _isGeneratingReport
                    ? 'Generating Report...'
                    : 'Reporting',
                description: 'Generate a performance report.',
                onTap: _isGeneratingReport ? null : _openReporting,
              ),
              const SizedBox(height: 30),
              _AdminActionCard(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBackgroundColor: const Color(0xFFEFF6FF),
                title: 'View Report',
                description: 'Read the latest report generated on this page.',
                onTap: _viewReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
