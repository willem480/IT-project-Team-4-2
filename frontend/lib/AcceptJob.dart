import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/models/ticket_model.dart';

import 'AcceptedJobDetail.dart';
import 'PostJob.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

// Keep the existing entry point so callers do not need routing changes.
// ignore: camel_case_types
class Acceptjob extends AcceptJobPage {
  const Acceptjob({super.key, required super.userId, super.userName});
}

class AcceptJobPage extends StatefulWidget {
  const AcceptJobPage({super.key, required this.userId, this.userName = ''});

  // Match the current user used by main.dart/Profile.dart until callers pass
  // the actor ID, as they already do for OrganisationPage and TeamsPage.
  final int userId;
  final String userName;

  @override
  State<AcceptJobPage> createState() => _AcceptJobPageState();
}

class _AcceptJobPageState extends State<AcceptJobPage> {
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

  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName.trim();
    _fetchUserName();
    _fetchAcceptedJobs();
  }

  @override
  void didUpdateWidget(covariant AcceptJobPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userName != widget.userName) {
      _userName = widget.userName.trim();
      _fetchUserName();
    }
    if (oldWidget.userId != widget.userId) {
      _fetchAcceptedJobs();
    }
  }

  Future<void> _fetchAcceptedJobs() async {
    final userId = widget.userId;
    setState(() {
      _isLoading = true;
      _error = null;
      _tickets = [];
    });
    final url = Uri.parse(
      'http://127.0.0.1:8080/ticketAssignment/getAcceptedJobsWithFilter',
    ).replace(queryParameters: {'assigneeID': '$userId'});
    http.Response? response;

    try {
      response = await http
          .post(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Accepted jobs request failed');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Expected an array of tickets');
      }
      final tickets = decoded
          .map<TicketModel>(
            (item) => TicketModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted || widget.userId != userId) return;
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load accepted jobs for user $userId: $error');
      if (response != null) {
        debugPrint('HTTP status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || widget.userId != userId) return;
      setState(() {
        _error = 'Unable to load accepted jobs. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAcceptedJob(TicketModel ticket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AcceptedJobDetail(ticket: ticket, userId: widget.userId)),
    );
    if (!mounted || changed != true) return;
    await _fetchAcceptedJobs();
  }

  Widget _buildJobsArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: _muted)),
      );
    }
    if (_tickets.isEmpty) {
      return const Center(child: Text('No accepted jobs'));
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _tickets.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openAcceptedJob(_tickets[index]),
          borderRadius: BorderRadius.circular(16),
          child: JobCard(job: _tickets[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _tickets
        .where((ticket) => _normalizeStatus(ticket.status) == 'OPEN')
        .length;
    final inProgressCount = _tickets
        .where((ticket) => _normalizeStatus(ticket.status) == 'INPROGRESS')
        .length;
    final closedCount = _tickets
        .where((ticket) => _normalizeStatus(ticket.status) == 'CLOSED')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preserve the header's natural height, but allow it to scroll
                // in short windows or when the keyboard reduces available space.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.75,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Good morning,',
                                style: TextStyle(color: _muted, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _displayName,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SearchField(),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: 'Open',
                                  count: '$openCount',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: 'In Progress',
                                  count: '$inProgressCount',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: 'Closed',
                                  count: '$closedCount',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [const _FilterButton(label: 'Time')],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Assigned to you',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${_tickets.length} results',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildJobsArea()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostJob(currentUserId:  widget.userId,)),
          );
        },
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        tooltip: 'Post a Job',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.search),
                label: const Text(
                  'Find a Job',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 60),
            Flexible(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outlined),
                label: const Text(
                  'Accepted Job',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Normalize only for comparisons and colors; display the backend value verbatim.
String _normalizeStatus(String? status) =>
    (status ?? '').toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');

Color _statusColor(String? status) => switch (_normalizeStatus(status)) {
  'OPEN' => const Color(0xFF10B981),
  'INPROGRESS' => const Color(0xFFF59E0B),
  _ => Colors.grey,
};

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final TicketModel job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${job.title ?? ''} - ${job.location ?? ''}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(job.status),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        job.status ?? '',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 13,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(
                  Icons.business_outlined,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.organizationName ?? '',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          if (job.idTicket != null) ...[
            const SizedBox(height: 10),
            Text(
              'Ticket #${job.idTicket}',
              style: const TextStyle(color: _muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: _ink, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search tickets, assignees, or locations...',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({required this.label, required this.count});

  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: _muted),
        ],
      ),
    );
  }
}
