import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/models/ticket_model.dart';

import 'AcceptedJobDetail.dart';
import 'PostJob.dart';
import 'Profile.dart';
import 'SignIn.dart';
import 'main.dart' show MyHomePage;
import 'config.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

enum _JobSort { time, pay, status }

class _RelatedTeam {
  const _RelatedTeam({
    required this.id,
    required this.name,
    this.organizationName = '',
    this.canManage = false,
  });

  final int id;
  final String name;
  final String organizationName;
  final bool canManage;
}

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
              ApiConfig.getUser(userId)),
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _keyword = '';
  _JobSort? _sortBy;
  bool _isAscending = true;
  _RelatedTeam? _selectedTeam;
  final _relatedTeamsMenuController = MenuController();
  List<_RelatedTeam> _relatedTeams = [];
  bool _isLoadingTeams = false;
  String? _teamsError;
  int _jobsRequestId = 0;
  int _teamsRequestId = 0;

  // The backend exposes three independent queries, so selecting one replaces
  // the previous query rather than displaying conditions it cannot apply.
  void _toggleSort(_JobSort sortBy) {
    _searchController.clear();
    setState(() {
      _isAscending = _sortBy == sortBy ? !_isAscending : true;
      _sortBy = sortBy;
      _keyword = '';
      _selectedTeam = null;
    });
    _fetchAcceptedJobs();
  }

  String _sortLabel(_JobSort sortBy) {
    if (_sortBy != sortBy) {
      return switch (sortBy) {
        _JobSort.time => 'Time',
        _JobSort.pay => 'Pay',
        _JobSort.status => 'Status',
      };
    }
    return switch (sortBy) {
      _JobSort.time =>
        _isAscending ? 'Time: Oldest first' : 'Time: Newest first',
      _JobSort.pay => _isAscending ? 'Pay: Low to High' : 'Pay: High to Low',
      _JobSort.status =>
        _isAscending ? 'Status: In Progress first' : 'Status: Closed first',
    };
  }

  void _submitSearch(String value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _keyword = value.trim();
      _sortBy = null;
      _selectedTeam = null;
    });
    _fetchAcceptedJobs();
  }

  void _resetQuery() {
    _searchController.clear();
    _submitSearch('');
  }

  Future<dynamic> _getJson(String path, Map<String, String> parameters) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: parameters);

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Team lookup failed (${response.statusCode})');
    }
    return jsonDecode(response.body);
  }

  Future<List<_RelatedTeam>> _fetchMyTeams(int userId) async {
    final organizations = await _getJson('/organization/getOrganizations', {
      'viewerUserId': '$userId',
    }) as List;
    final organizationTeams = await Future.wait(
      organizations.map((organization) async {
        final data = await _getJson('/organization/getOrganizationTeams', {
          'organizationId': '${organization['organizationId']}',
          'viewerUserId': '$userId',
        }) as Map<String, dynamic>;
        return (data['teams'] as List)
            .map(
              (team) => _RelatedTeam(
                id: team['teamId'] as int,
                name: team['name'] as String,
                organizationName: organization['name'] as String,
                canManage: data['canManage'] == true,
              ),
            )
            .toList();
      }),
    );
    final teams = {
      for (final team in organizationTeams.expand((teams) => teams))
        team.id: team,
    }.values.toList();
    final myTeams = <_RelatedTeam>[];
    // Bound the number of membership lookups in flight for large team lists.
    for (var start = 0; start < teams.length; start += 6) {
      final members = await Future.wait(
        teams.skip(start).take(6).map((team) async {
          // Creating a team does not add its manager to the membership table.
          // Include managed teams as well as teams the current user has joined.
          if (team.canManage) return team;
          final data = await _getJson('/team/getTeamMembers', {
            'teamId': '${team.id}',
            'viewerUserId': '$userId',
          }) as Map<String, dynamic>;
          final belongsToTeam = (data['members'] as List).any(
            (member) => member['userId'] == userId,
          );
          return belongsToTeam ? team : null;
        }),
      );
      myTeams.addAll(members.whereType<_RelatedTeam>());
    }
    myTeams.sort((a, b) {
      final organizationOrder = a.organizationName.toLowerCase().compareTo(
        b.organizationName.toLowerCase(),
      );
      return organizationOrder != 0
          ? organizationOrder
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return myTeams;
  }

  void _openRelatedTeams() {
    if (_relatedTeamsMenuController.isOpen) {
      _relatedTeamsMenuController.close();
      return;
    }
    _relatedTeamsMenuController.open();
    _loadRelatedTeams();
  }

  Future<void> _loadRelatedTeams() async {
    if (_isLoadingTeams) return;
    final userId = widget.userId;
    final requestId = ++_teamsRequestId;
    setState(() {
      _isLoadingTeams = true;
      _teamsError = null;
      _relatedTeams = [];
    });
    try {
      final teams = await _fetchMyTeams(userId);
      if (!mounted || widget.userId != userId || requestId != _teamsRequestId) {
        return;
      }
      setState(() {
        _isLoadingTeams = false;
        _relatedTeams = teams;
      });
    } catch (error) {
      if (!mounted || widget.userId != userId || requestId != _teamsRequestId) {
        return;
      }
      setState(() {
        _isLoadingTeams = false;
        _teamsError = 'Unable to load teams. Retry';
      });
      debugPrint('Failed to load teams for user $userId: $error');
    }
  }

  void _selectRelatedTeam(_RelatedTeam team) {
    _searchController.clear();
    setState(() {
      _selectedTeam = team;
      _keyword = '';
      _sortBy = null;
    });
    _fetchAcceptedJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
      _relatedTeamsMenuController.close();
      _searchController.clear();
      _keyword = '';
      _sortBy = null;
      _selectedTeam = null;
      _relatedTeams = [];
      _isLoadingTeams = false;
      _teamsError = null;
      _teamsRequestId++;
      _fetchAcceptedJobs();
    }
  }

  Future<void> _fetchAcceptedJobs() async {
    final userId = widget.userId;
    final requestId = ++_jobsRequestId;
    setState(() {
      _isLoading = true;
      _error = null;
      _tickets = [];
    });
    var endpoint = 'getAcceptedJobsWithFilter';
    final parameters = {'assigneeID': '$userId'};
    if (_keyword.isNotEmpty) {
      endpoint = 'getAcceptedJobsKeyWord';
      parameters['keyword'] = _keyword;
    } else if (_selectedTeam != null) {
      endpoint = 'getAcceptedJobsRelatedTo';
      parameters['teamID'] = '${_selectedTeam!.id}';
    } else if (_sortBy != null) {
      parameters['filter'] =
          '${_sortBy!.name}${_isAscending ? 'Ascending' : 'Descending'}';
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/ticketAssignment/$endpoint');
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
            (item) =>
                TicketModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted || widget.userId != userId || requestId != _jobsRequestId) {
        return;
      }
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
      if (!mounted || widget.userId != userId || requestId != _jobsRequestId) {
        return;
      }
      setState(() {
        _error = 'Unable to load accepted jobs. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openAcceptedJob(TicketModel ticket) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AcceptedJobDetail(ticket: ticket, userId: widget.userId),
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _muted)),
            TextButton(
              onPressed: _fetchAcceptedJobs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) {
      return Center(
        child: Text(
          _selectedTeam == null
              ? 'No accepted jobs'
              : 'No accepted jobs for this team',
        ),
      );
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
    final inProgressCount = _tickets
        .where((ticket) => _normalizeStatus(ticket.status) == 'INPROGRESS')
        .length;
    final closedCount = _tickets
        .where((ticket) => _normalizeStatus(ticket.status) == 'CLOSED')
        .length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.black54),
          tooltip: 'Log out to Sign In',
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SignInPage(title: 'Find a job'),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'MYTI',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Profile(userId: widget.userId),
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  _displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Hello, $_displayName',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          tickets: _tickets,
                          onSelected: _openAcceptedJob,
                          onSubmitted: _submitSearch,
                          onCleared: _resetQuery,
                          onChanged: (value) {
                            if (value.isEmpty && _keyword.isNotEmpty) {
                              _submitSearch('');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _StatusSummaryCard(
                                  label: 'In Progress',
                                  count: '$inProgressCount',
                                ),
                              ),
                              const SizedBox(width: 12),
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
                          children: [
                            for (final sort in _JobSort.values)
                              _FilterButton(
                                label: _sortLabel(sort),
                                isActive: _sortBy == sort,
                                icon: _sortBy != sort
                                    ? Icons.unfold_more
                                    : _isAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                onPressed: () => _toggleSort(sort),
                              ),
                            MenuAnchor(
                              controller: _relatedTeamsMenuController,
                              alignmentOffset: const Offset(0, 4),
                              consumeOutsideTap: true,
                              style: const MenuStyle(
                                alignment: AlignmentDirectional.bottomStart,
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                                minimumSize: WidgetStatePropertyAll(
                                  Size(200, 0),
                                ),
                                maximumSize: WidgetStatePropertyAll(
                                  Size(320, 320),
                                ),
                              ),
                              menuChildren: [
                                if (_isLoadingTeams)
                                  const MenuItemButton(
                                    child: Text('Loading teams...'),
                                  )
                                else if (_teamsError != null)
                                  MenuItemButton(
                                    closeOnActivate: false,
                                    onPressed: _loadRelatedTeams,
                                    child: Text(_teamsError!),
                                  )
                                else if (_relatedTeams.isEmpty)
                                  const MenuItemButton(
                                    child: Text('No related teams'),
                                  )
                                else
                                  for (final team in _relatedTeams)
                                    MenuItemButton(
                                      onPressed: () => _selectRelatedTeam(team),
                                      trailingIcon: _selectedTeam?.id == team.id
                                          ? const Icon(Icons.check, size: 18)
                                          : null,
                                      child: Text(
                                        '${team.name} of ${team.organizationName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              ],
                              builder: (context, controller, child) =>
                                  _FilterButton(
                                    label: _selectedTeam == null
                                        ? 'Related to'
                                        : 'Related to: ${_selectedTeam!.name}',
                                    isActive: _selectedTeam != null,
                                    icon: Icons.keyboard_arrow_down,
                                    onPressed: _openRelatedTeams,
                                  ),
                            ),
                            if (_sortBy != null ||
                                _keyword.isNotEmpty ||
                                _selectedTeam != null)
                              TextButton(
                                onPressed: _resetQuery,
                                child: const Text('Reset'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _keyword.isNotEmpty
                                    ? 'Results for “$_keyword”'
                                    : _selectedTeam != null
                                    ? 'Related to ${_selectedTeam!.name}'
                                    : 'Assigned to you',
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
            MaterialPageRoute(
              builder: (context) => PostJob(currentUserId: widget.userId),
            ),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => MyHomePage(
                        title: 'Find a job',
                        currentUserId: widget.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 25, color: Colors.grey),
                label: const Text(
                  'Find a Job',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
            Flexible(
              child: Container(
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
                  onPressed: () {},
                  icon: const Icon(
                    Icons.check_circle_outlined,
                    size: 25,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    'Accepted Job',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeStatus(String? status) =>
    (status ?? '').toUpperCase().replaceAll(RegExp(r'[\s_-]+'), '');

String _formatStatus(String? status) => switch (_normalizeStatus(status)) {
  'CLOSED' => 'CLOSE',
  'INPROGRESS' => 'IN PROGRESS',
  _ => status ?? '',
};

Color _statusColor(String? status) => switch (_normalizeStatus(status)) {
  'OPEN' => const Color(0xFF10B981),
  'INPROGRESS' => const Color(0xFFF59E0B),
  'CLOSED' => Colors.red,
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
                  job.title ?? '',
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
                        _formatStatus(job.status),
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
            children: [
              const Icon(Icons.business, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.tickets,
    required this.onSelected,
    required this.onSubmitted,
    required this.onCleared,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<TicketModel> tickets;
  final ValueChanged<TicketModel> onSelected;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<TicketModel>(
        textEditingController: controller,
        focusNode: focusNode,
        displayStringForOption: (ticket) => ticket.title ?? '',
        optionsBuilder: (value) {
          if (value.text.trim().isEmpty) {
            return const Iterable<TicketModel>.empty();
          }
          final keyword = value.text.toLowerCase();
          return tickets.where(
            (ticket) => (ticket.title ?? '').toLowerCase().contains(keyword),
          );
        },
        onSelected: (ticket) {
          focusNode.unfocus();
          onSelected(ticket);
        },
        optionsViewBuilder: (context, selectOption, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final ticket = options.elementAt(index);
                    return ListTile(
                      selected:
                          AutocompleteHighlightedOption.of(context) == index,
                      title: Text(
                        ticket.title ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '\$${ticket.pay ?? 0} - ${ticket.location ?? ticket.posterName ?? ''}',
                        style: const TextStyle(color: _muted),
                      ),
                      onTap: () => selectOption(ticket),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        fieldViewBuilder:
            (context, fieldController, fieldFocusNode, onFieldSubmitted) =>
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) => TextField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      onFieldSubmitted();
                      onSubmitted(value);
                    },
                    onChanged: onChanged,
                    style: const TextStyle(color: _ink, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search ticket titles or descriptions...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                      prefixIcon: IconButton(
                        tooltip: 'Search accepted jobs',
                        onPressed: () => onSubmitted(controller.text),
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: onCleared,
                              icon: const Icon(Icons.close),
                            ),
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
                  ),
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
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isActive ? const Color(0xFFEFF6FF) : Colors.white,
        foregroundColor: isActive ? Colors.blue : _ink,
        side: BorderSide(color: isActive ? Colors.blue : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
