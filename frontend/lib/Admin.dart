import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.userId,
    this.organisationId,
    this.teamId,
    this.teamMemberId,
  });

  final int userId;
  final int? organisationId;
  // Null when managing an organisation without a selected team.
  final int? teamId;
  final int? teamMemberId;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isGeneratingReport = false;

  void _goBack(BuildContext context) {
    Navigator.maybePop(context);
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
          return {'teamMemberId': '${member['userId']}', 'teamId': '$teamId'};
        }
      }
    }
    throw const FormatException(
      'This member could not be found. Please refresh the member list.',
    );
  }

  Future<void> _openReport() async {
    if (_isGeneratingReport) return;
    setState(() => _isGeneratingReport = true);
    try {
      final emailCopy = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Do you want an email copy?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (!mounted || emailCopy == null) return;

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

      parameters.addAll({
        'managerId': '${widget.userId}',
        'emailCopy': '$emailCopy',
      });
      final report = await _loadReportData(path, parameters, generate: true);
      if (!mounted) return;
      if (report['title'] is! String || report['body'] is! String) {
        throw const FormatException('The server returned an invalid report.');
      }
      if (emailCopy) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Email sent successfully'),
            content: const Text(
              'A copy of the report has been sent to your email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
      await _viewReport(report);
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

  String _formatReportDateTime(String text) {
    return text.replaceAllMapped(
      RegExp(r'(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})(?:\.\d+)?'),
      (match) => '${match[1]} ${match[2]}',
    );
  }

  Future<void> _viewReport(Map<String, dynamic> report) async {
    var isConfirmingClose = false;

    Future<void> closeReport(BuildContext dialogContext) async {
      if (isConfirmingClose) return;
      isConfirmingClose = true;
      final discard = await showDialog<bool>(
        context: dialogContext,
        builder: (confirmationContext) => AlertDialog(
          title: const Text('Close report?'),
          content: const Text(
            'Closing this window will permanently delete this report. '
            'Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmationContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(confirmationContext, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      isConfirmingClose = false;
      if (discard == true && dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) closeReport(dialogContext);
        },
        child: AlertDialog(
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
                          _formatReportDateTime(
                            '${entry.key}: ${entry.value ?? '-'}',
                          ),
                        ),
                      ),
                  const Divider(),
                  SelectableText(
                    _formatReportDateTime(report['body'] as String),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => closeReport(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(leading: BackButton(onPressed: () => _goBack(context))),
      body: SafeArea(
        // Allow the entire page to scroll in short windows or with large text.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select a manager action',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 36),
              _AdminActionCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBackgroundColor: const Color(0xFFF0FDF4),
                title: _isGeneratingReport ? 'Generating Report...' : 'Report',
                description: 'Generate a performance report.',
                onTap: _isGeneratingReport ? null : _openReport,
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
