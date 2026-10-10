import 'package:flutter/material.dart';

import 'PostJob.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

// Keep the existing entry point so callers do not need routing changes.
// ignore: camel_case_types
class Acceptjob extends AcceptJobPage {
  const Acceptjob({super.key, super.jobs});
}

class AcceptJobPage extends StatefulWidget {
  const AcceptJobPage({super.key, this.jobs});

  /// Omit for development samples; pass an empty list to display no jobs.
  final List<Job>? jobs;

  @override
  State<AcceptJobPage> createState() => _AcceptJobPageState();
}

class _AcceptJobPageState extends State<AcceptJobPage> {
  String _query = '';
  String? _time;

  bool _matchesTime(Job job, DateTime now) {
    final remaining = job.dueAt.difference(now);
    // Time options are rolling 24-hour ranges; overdue jobs remain in All times.
    return switch (_time) {
      'Less than 1 day' =>
        !remaining.isNegative && remaining < const Duration(days: 1),
      '1 day' =>
        remaining >= const Duration(days: 1) &&
            remaining < const Duration(days: 2),
      '2 days' =>
        remaining >= const Duration(days: 2) &&
            remaining < const Duration(days: 3),
      '3+ days' => remaining >= const Duration(days: 3),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.jobs ?? sampleJobs;
    final now = DateTime.now();
    final visibleJobs = jobs
        .where(
          (job) =>
              job.jobName.toLowerCase().contains(_query) ||
              job.position.toLowerCase().contains(_query) ||
              job.organization.toLowerCase().contains(_query),
        )
        .where((job) => _matchesTime(job, now))
        .toList();
    // Summaries describe all assigned jobs, independent of search and filters.
    final openCount = jobs.where((job) => job.status == JobStatus.open).length;
    final inProgressCount = jobs
        .where((job) => job.status == JobStatus.inProgress)
        .length;
    final closedCount = jobs
        .where((job) => job.status == JobStatus.closed)
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
                        const Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning,',
                                style: TextStyle(color: _muted, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Alan',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SearchField(
                          onChanged: (value) => setState(
                            () => _query = value.trim().toLowerCase(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: JobStatus.open.displayText,
                                  count: '$openCount',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: JobStatus.inProgress.displayText,
                                  count: '$inProgressCount',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: JobStatus.closed.displayText,
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
                          children: [
                            _FilterButton(
                              label: 'Time',
                              value: _time,
                              options: const [
                                'All times',
                                'Less than 1 day',
                                '1 day',
                                '2 days',
                                '3+ days',
                              ],
                              onSelected: (value) => setState(
                                () =>
                                    _time = value == 'All times' ? null : value,
                              ),
                            ),
                          ],
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
                              '${visibleJobs.length} results',
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
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: visibleJobs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(job: visibleJobs[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostJob()),
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
                  'Accept a Job',
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

enum JobStatus { open, inProgress, closed }

extension on JobStatus {
  String get displayText => switch (this) {
    JobStatus.open => 'Open',
    JobStatus.inProgress => 'In Progress',
    JobStatus.closed => 'Closed',
  };

  Color get color => switch (this) {
    JobStatus.open => const Color(0xFF10B981),
    JobStatus.inProgress => const Color(0xFFF59E0B),
    JobStatus.closed => Colors.grey,
  };
}

class Job {
  const Job({
    required this.jobName,
    required this.position,
    required this.organization,
    required this.status,
    required this.dueAt,
  });

  final String jobName;
  final String position;
  final String organization;
  final JobStatus status;
  final DateTime dueAt;

  String get dueDate {
    final localDue = dueAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(localDue.year, localDue.month, localDue.day);
    if (dueDay == today) return 'today';
    if (dueDay == DateTime(now.year, now.month, now.day + 1)) {
      return 'tomorrow';
    }
    return const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][localDue.weekday - 1];
  }

  String get dueTime {
    final localDue = dueAt.toLocal();
    final hour = localDue.hour % 12 == 0 ? 12 : localDue.hour % 12;
    final minute = localDue.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${localDue.hour < 12 ? 'AM' : 'PM'}';
  }
}

// Development data only. Callers can replace it with AcceptJobPage(jobs: jobsFromApi).
final List<Job> sampleJobs = _createSampleJobs();

List<Job> _createSampleJobs() {
  final now = DateTime.now();
  final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
  final friday = DateTime(now.year, now.month, now.day + daysUntilFriday, 16);
  return List<Job>.unmodifiable([
    Job(
      jobName: 'Emergency light fitting',
      position: 'Building C',
      organization: 'The University of Melbourne',
      status: JobStatus.inProgress,
      dueAt: DateTime(now.year, now.month, now.day, 14),
    ),
    Job(
      jobName: 'Network printer offline',
      position: 'Floor 2',
      organization: 'Provision IT',
      status: JobStatus.open,
      dueAt: DateTime(now.year, now.month, now.day + 1, 10),
    ),
    Job(
      jobName: 'Door access request',
      position: 'Warehouse B',
      organization: 'Microsoft',
      status: JobStatus.open,
      dueAt: friday.isAfter(now)
          ? friday
          : DateTime(now.year, now.month, now.day + 7, 16),
    ),
  ]);
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final Job job;

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
                  '${job.jobName} - ${job.position}',
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
                        color: job.status.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        job.status.displayText,
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
                  job.organization,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Due ${job.dueDate} · ${job.dueTime}',
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
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
  const _FilterButton({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter by $label',
      initialValue: value,
      onSelected: onSelected,
      color: Colors.white,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        for (final option in options)
          CheckedPopupMenuItem(
            value: option,
            checked: option == value,
            child: Text(option),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: value == null ? _border : const Color(0xFF93C5FD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value == null ? label : '$label: $value',
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
      ),
    );
  }
}
