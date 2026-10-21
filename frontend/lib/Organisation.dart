import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'Teams.dart';
import 'models/organisation_model.dart';

class OrganisationPage extends StatefulWidget {
  const OrganisationPage({super.key, required this.userId, this.userName = ''});

  final int userId;
  final String userName;

  @override
  State<OrganisationPage> createState() => _OrganisationPageState();
}

class _OrganisationPageState extends State<OrganisationPage> {
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

  List<OrganisationModel> organisations = [];
  static const _avatarColors = [Colors.pink, Colors.teal, Colors.red];

  String _query = '';
  bool _isCreating = false;
  bool _isSubmitting = false;
  int? _renamingOrganisationId;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName.trim();
    _fetchUserName();
    fetchOrganisations();
  }

  @override
  void didUpdateWidget(covariant OrganisationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userName != widget.userName) {
      _userName = widget.userName.trim();
      _fetchUserName();
    }
  }

  Future<void> fetchOrganisations() async {
    final url = Uri.parse(
      'http://127.0.0.1:8080/organization/getOrganizations?viewerUserId=${widget.userId}',
    );

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

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

  Future<String?> _showOrganisationNameDialog({String? initialName}) {
    final formKey = GlobalKey<FormState>();
    var organisationName = '';
    var submitted = false;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          if (submitted || !formKey.currentState!.validate()) return;
          formKey.currentState!.save();
          submitted = true;
          Navigator.pop(dialogContext, organisationName);
        }

        return AlertDialog(
          title: Text(
            initialName == null ? 'Create Organisation' : 'Rename Organisation',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: initialName,
              autofocus: true,
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Organisation name'),
              validator: (value) {
                final trimmedName = value?.trim() ?? '';
                if (trimmedName.isEmpty) {
                  return 'Please enter an organisation name.';
                }
                if (trimmedName.length > 200) {
                  return 'Name must be 200 characters or fewer.';
                }
                return null;
              },
              onSaved: (value) => organisationName = value!.trim(),
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
              child: Text(initialName == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrganisation() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      final name = await _showOrganisationNameDialog();
      if (name == null || !mounted) return;

      setState(() => _isSubmitting = true);
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8080/organization/createOrganization'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'actorUserId': widget.userId, 'name': name}),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 201) {
        final organisation = OrganisationModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        setState(() => organisations = [...organisations, organisation]);
        await fetchOrganisations();
        if (!mounted) return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 201
                  ? 'Organisation created successfully.'
                  : _organisationError(response, action: 'create'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to create organisation. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _renameOrganisation(OrganisationModel organisation) async {
    if (!organisation.canManage || _renamingOrganisationId != null) return;
    setState(() => _renamingOrganisationId = organisation.organizationId);
    try {
      final name = await _showOrganisationNameDialog(
        initialName: organisation.name,
      );
      if (!mounted || name == null || name == organisation.name) return;

      final response = await http
          .patch(
            Uri.parse('http://127.0.0.1:8080/organization/updateOrganization'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': widget.userId,
              'organizationId': organisation.organizationId,
              'name': name,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final updated = OrganisationModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        setState(() {
          organisations = organisations
              .map(
                (item) => item.organizationId == updated.organizationId
                    ? updated
                    : item,
              )
              .toList();
        });
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 200
                  ? 'Organisation renamed successfully.'
                  : _organisationError(response, action: 'rename'),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to rename organisation. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _renamingOrganisationId = null);
    }
  }

  String _organisationError(http.Response response, {required String action}) {
    if (response.statusCode == 403) {
      return 'Only an organisation manager can $action this organisation.';
    }
    if (response.statusCode == 404) {
      return 'The organisation no longer exists. Please refresh.';
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      }
    } on FormatException {
      // Fall back to a readable message for non-JSON responses.
    }
    if (response.statusCode == 400 || response.statusCode == 409) {
      return 'Check the organisation name. It may already exist.';
    }
    return 'Unable to $action organisation (HTTP ${response.statusCode}). Please try again.';
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
          userName: _userName,
          organizationId: organisationId,
          organisationName: organisationName,
        ),
      ),
    );
  }

  void _openAdmin(BuildContext context, OrganisationModel organisation) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminPage(
          userId: widget.userId,
          userName: _userName,
          organisationId: organisation.organizationId,
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
        title: Text(
          'Good morning, $_displayName',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Good morning, $_displayName',
                style: const TextStyle(fontSize: 20),
              ),
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
                itemCount: visibleOrganisations.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == visibleOrganisations.length) {
                    return Center(
                      child: IconButton.filledTonal(
                        tooltip: 'Create organisation',
                        onPressed: _isCreating ? null : _createOrganisation,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                      ),
                    );
                  }
                  final organisation = visibleOrganisations[index];
                  return OrganizationCard(
                    isManager: organisation.canManage,
                    organizationId: organisation.organizationId,
                    name: organisation.name,
                    members: organisation.memberCount,
                    avatarColor:
                        _avatarColors[organisations.indexOf(organisation) %
                            _avatarColors.length],
                    onManage: () => _openAdmin(context, organisation),
                    onRename: _renamingOrganisationId == null
                        ? () => _renameOrganisation(organisation)
                        : null,
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
                    builder: (context) => Profile(userId: widget.userId),
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
    required this.isManager,
    this.onRename,
  });

  final int organizationId;
  final bool isManager;
  final String name;
  final int members;
  final Color avatarColor;
  final VoidCallback onManage;
  final VoidCallback? onRename;
  final void Function(int organisationId, String organisationName) onOpenTeams;

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
                            tooltip: 'Rename organisation',
                            onPressed: onRename,
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Preserve the subtitle line's spacing without a mock link.
                    const Text(
                      '',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
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
    );
  }
}
