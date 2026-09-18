import 'package:flutter/material.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

// Keep the existing entry point so callers do not need routing changes.
// ignore: camel_case_types
class Acceptjob extends AcceptJobPage {
  const Acceptjob({super.key});
}

class AcceptJobPage extends StatefulWidget {
  const AcceptJobPage({super.key});

  @override
  State<AcceptJobPage> createState() => _AcceptJobPageState();
}

class _AcceptJobPageState extends State<AcceptJobPage> {
  String? _time;
  String? _distance;
  String? _priority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
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
                  const _SearchField(),
                  const SizedBox(height: 16),
                  const IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatusSummaryCard(label: 'Open', count: '12'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _StatusSummaryCard(
                            label: 'In Progress',
                            count: '7',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _StatusSummaryCard(
                            label: 'Completed',
                            count: '34',
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
                          'Less than 1 day',
                          '1 day',
                          '2 days',
                          '3+ days',
                        ],
                        onSelected: (value) => setState(() => _time = value),
                      ),
                      _FilterButton(
                        label: 'Distance',
                        value: _distance,
                        options: const [
                          'Less than 1 km',
                          '1–5 km',
                          '5–10 km',
                          '10+ km',
                        ],
                        onSelected: (value) =>
                            setState(() => _distance = value),
                      ),
                      _FilterButton(
                        label: 'Priority',
                        value: _priority,
                        options: const ['Urgent', 'Medium', 'Low'],
                        onSelected: (value) =>
                            setState(() => _priority = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
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
                        '3 results',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        for (final job in _jobs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: JobCard(job: job),
                          ),
                        // Empty UI placeholders, separate from the real jobs.
                        for (var i = 0; i < 2; i++)
                          Container(
                            height: 140,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _AcceptedJobBottomBar(),
    );
  }
}

class Job {
  const Job({
    required this.jobName,
    required this.position,
    required this.jobType,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
  });

  final String jobName;
  final String position;
  final String jobType;
  final String status;
  final String priority;
  final String dueDate;
  final String dueTime;
}

const _jobs = [
  Job(
    jobName: 'Emergency light fitting',
    position: 'Building C',
    jobType: 'The University of Melbourne',
    status: 'In Progress',
    priority: 'Urgent',
    dueDate: 'today',
    dueTime: '2:00 PM',
  ),
  Job(
    jobName: 'Network printer offline',
    position: 'Floor 2',
    jobType: 'Provision IT',
    status: 'Open',
    priority: 'Medium',
    dueDate: 'tomorrow',
    dueTime: '10:00 AM',
  ),
  Job(
    jobName: 'Door access request',
    position: 'Warehouse B',
    jobType: 'Microsoft',
    status: 'Open',
    priority: 'Low',
    dueDate: 'Fri',
    dueTime: '4:00 PM',
  ),
];

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
              _PriorityBadge(priority: job.priority),
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
                  job.jobType,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                        color: job.status == 'In Progress'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        job.status,
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

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (priority) {
      'Urgent' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'Medium' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      _ => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Local bottom bar; only Find a Job returns to the previous page.
class _AcceptedJobBottomBar extends StatelessWidget {
  const _AcceptedJobBottomBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _BottomBarItem(
                  label: 'Find a Job',
                  icon: Icons.search,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Semantics(
                  label: 'Post a Job',
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.add, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: _BottomBarItem(
                  label: 'Accepted Job',
                  icon: Icons.check_circle_outlined,
                  selected: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _ink : _muted;
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        selected: selected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD6D5D3) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
