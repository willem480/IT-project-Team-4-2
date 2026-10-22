import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final _activeReports = Expando<bool>('activeReports');

/// Generates and displays an organisation, team, or member report.
///
/// Supply [organisationId] for an organisation report, [teamId] for a team
/// report, or [teamMemberId] with a team/organisation for a member report.
/// [teamMemberId] is the membership ID; it is resolved to the user ID expected
/// by the report API. Concurrent calls from the same page context are ignored.
Future<void> openReport(
  BuildContext context, {
  required int userId,
  int? organisationId,
  int? teamId,
  int? teamMemberId,
}) async {
  if (!context.mounted || _activeReports[context] == true) return;
  _activeReports[context] = true;
  try {
    await _ReportFlow(
      context: context,
      userId: userId,
      organisationId: organisationId,
      teamId: teamId,
      teamMemberId: teamMemberId,
    ).run();
  } finally {
    _activeReports[context] = null;
  }
}

class _ReportFlow {
  const _ReportFlow({
    required this.context,
    required this.userId,
    this.organisationId,
    this.teamId,
    this.teamMemberId,
  });

  final BuildContext context;
  final int userId;
  final int? organisationId;
  final int? teamId;
  final int? teamMemberId;

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
    if (teamId != null) {
      teamIds.add(teamId!);
    } else {
      final organisationId = this.organisationId;
      if (organisationId == null) {
        throw const FormatException(
          'Unable to find this member: organisation is missing.',
        );
      }
      final data = await _loadReportData('/organization/getOrganizationTeams', {
        'organizationId': '$organisationId',
        'viewerUserId': '$userId',
      });
      if (!context.mounted) return null;
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
        'viewerUserId': '$userId',
      });
      if (!context.mounted) return null;
      final members = data['members'];
      if (members is! List) {
        throw const FormatException(
          'The server returned an invalid member list.',
        );
      }
      for (final member in members) {
        if (member is Map<String, dynamic> &&
            member['teamMemberId'] == teamMemberId &&
            member['userId'] is int) {
          // Despite its name, the report API expects a user ID here.
          return {'teamMemberId': '${member['userId']}', 'teamId': '$teamId'};
        }
      }
    }
    throw const FormatException(
      'This member could not be found. Please refresh the member list.',
    );
  }

  Future<void> run() async {
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
      if (!context.mounted || emailCopy == null) return;

      final String path;
      final Map<String, String> parameters;
      if (teamMemberId != null) {
        path = '/memberReport/generateTeamMemberReport';
        final memberParameters = await _memberReportParameters();
        if (!context.mounted || memberParameters == null) return;
        parameters = memberParameters;
      } else if (teamId != null) {
        path = '/teamReport/generateTeamReport';
        parameters = {'teamId': '$teamId'};
      } else {
        if (organisationId == null) {
          throw const FormatException(
            'Unable to generate report: organisation is missing.',
          );
        }
        path = '/organizationReport/generateOrganizationReport';
        parameters = {'organizationId': '$organisationId'};
      }

      parameters.addAll({'managerId': '$userId', 'emailCopy': '$emailCopy'});
      final report = await _loadReportData(path, parameters, generate: true);
      if (!context.mounted) return;
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
        if (!context.mounted) return;
      }
      await _viewReport(report);
    } on FormatException catch (error) {
      if (context.mounted) _reportMessage(error.message);
    } catch (_) {
      if (context.mounted) {
        _reportMessage('Unable to generate report. Please try again.');
      }
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
}
