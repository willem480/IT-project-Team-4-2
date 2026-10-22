import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Admin.dart';
import 'Profile.dart';
import 'Teams.dart';
import 'models/organisation_model.dart';

// Shared greeting data and UI for organisation, team and member pages.
final organisationGreeting = OrganisationGreeting();

class OrganisationGreeting extends ValueNotifier<String> {
  OrganisationGreeting() : super('Loading...');

  static const prefix = 'Hello!';
  static const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  int? _userId;
  int _revision = 0;
  Future<void>? _loading;

  Future<void> load({required int userId, String userName = ''}) {
    if (_userId != userId) {
      _userId = userId;
      _revision++;
      _loading = null;
      value = 'Loading...';
    }

    final name = userName.trim();
    if (name.isNotEmpty) {
      // A supplied name takes priority over an earlier in-flight request.
      _revision++;
      _loading = null;
      value = name;
      return Future<void>.value();
    }
    if (value != 'Loading...') return Future<void>.value();
    return _loading ??= _fetchUserName(userId, _revision);
  }

  Future<void> _fetchUserName(int userId, int revision) async {
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
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final name = (data['name'] as String?)?.trim() ?? '';
      if (_revision != revision) return;
      value = name.isEmpty ? 'User' : name;
    } catch (error) {
      debugPrint('Failed to load greeting name for user $userId: $error');
      if (_revision != revision) return;
      value = 'User';
    } finally {
      if (_revision == revision) _loading = null;
    }
  }

  AppBar appBar({VoidCallback? onBack, List<Widget>? actions}) {
    return AppBar(
      leading: BackButton(onPressed: onBack),
      title: ValueListenableBuilder<String>(
        valueListenable: this,
        builder: (context, userName, child) =>
            Text('$prefix $userName', style: style),
      ),
      actions: actions,
    );
  }
}

class OrganisationPage extends StatefulWidget {
  const OrganisationPage({super.key, required this.userId, this.userName = ''});

  final int userId;
  final String userName;

  @override
  State<OrganisationPage> createState() => _OrganisationPageState();
}

class _OrganisationPageState extends State<OrganisationPage> {
  List<OrganisationModel> organisations = [];
  final _managersByOrganisation = <int, List<({int userId, String name})>>{};
  final _managerErrors = <int, String>{};
  static const _avatarColors = [Colors.pink, Colors.teal, Colors.red];

  String _query = '';
  bool _isCreating = false;
  bool _isSubmitting = false;
  int? _removingOrganisationId;

  bool get _isRemoving => _removingOrganisationId != null;
  bool _isSubmittingRemoval = false;
  int? _renamingOrganisationId;

  @override
  void initState() {
    super.initState();
    organisationGreeting.load(userId: widget.userId, userName: widget.userName);
    fetchOrganisations();
  }

  @override
  void didUpdateWidget(covariant OrganisationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userName != widget.userName) {
      organisationGreeting.load(
        userId: widget.userId,
        userName: widget.userName,
      );
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
        for (final organisation in parsedOrganisations) {
          _fetchManagers(organisation.organizationId);
        }
        debugPrint('Organisations loaded: ${organisations.length}');
      } else {
        debugPrint('Failed to load organisations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load organisations: $e');
    }
  }

  Future<void> _fetchManagers(int organisationId) async {
    try {
      final managers = await fetchOrganisationManagers(organisationId);
      if (!mounted) return;
      setState(() {
        _managersByOrganisation[organisationId] = managers;
        _managerErrors.remove(organisationId);
        if (managers.isEmpty) _managerErrors[organisationId] = 'No managers';
      });
    } catch (error) {
      debugPrint(
        'Failed to load managers for organisation $organisationId: $error',
      );
      if (!mounted) return;
      setState(() {
        _managersByOrganisation.remove(organisationId);
        _managerErrors[organisationId] = 'Managers unavailable';
      });
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
    if (_isCreating || _isRemoving) return;
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

  Future<void> _removeOrganisation(OrganisationModel selected) async {
    if (!selected.canManage ||
        _isRemoving ||
        _isCreating ||
        _renamingOrganisationId != null) {
      return;
    }
    setState(() => _removingOrganisationId = selected.organizationId);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove this organisation?'),
          content: Text(
            'Are you sure you want to remove "${selected.name}"? '
            'This will also remove its teams, memberships and manager roles. '
            'This action cannot be undone.',
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
            Uri.parse('http://127.0.0.1:8080/organization/removeOrganization')
                .replace(
                  queryParameters: {
                    'actorUserId': '${widget.userId}',
                    'organizationId': '${selected.organizationId}',
                  },
                ),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;

      final succeeded = response.statusCode >= 200 && response.statusCode < 300;
      if (succeeded) {
        setState(() {
          organisations.removeWhere(
            (organisation) =>
                organisation.organizationId == selected.organizationId,
          );
          _managersByOrganisation.remove(selected.organizationId);
          _managerErrors.remove(selected.organizationId);
        });
        await fetchOrganisations();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              succeeded
                  ? 'Organisation removed successfully.'
                  : _organisationError(response, action: 'remove'),
            ),
          ),
        );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to remove organisation. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _removingOrganisationId = null;
          _isSubmittingRemoval = false;
        });
      }
    }
  }

  Future<void> _renameOrganisation(OrganisationModel organisation) async {
    if (!organisation.canManage ||
        _renamingOrganisationId != null ||
        _isRemoving) {
      return;
    }
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
    if (action != 'remove' &&
        (response.statusCode == 400 || response.statusCode == 409)) {
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
          organizationId: organisationId,
          organisationName: organisationName,
        ),
      ),
    );
  }

  Future<void> _openAdmin(
    BuildContext context,
    OrganisationModel organisation,
  ) async {
    if (!organisation.canManage) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminPage(
          userId: widget.userId,
          organisationId: organisation.organizationId,
        ),
      ),
    );
    if (mounted) await _fetchManagers(organisation.organizationId);
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrganisations = organisations
        .where(
          (organisation) => organisation.name.toLowerCase().contains(_query),
        )
        .toList();
    visibleOrganisations.sort((a, b) {
      final nameOrder = a.name.trim().toLowerCase().compareTo(
        b.name.trim().toLowerCase(),
      );
      if (nameOrder != 0) return nameOrder;
      final caseOrder = a.name.compareTo(b.name);
      return caseOrder != 0
          ? caseOrder
          : a.organizationId.compareTo(b.organizationId);
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
                  Expanded(
                    child: Row(
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
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Create organisation',
                          onPressed: _isCreating || _isRemoving
                              ? null
                              : _createOrganisation,
                          iconSize: 26,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.blue,
                            backgroundColor: Colors.transparent,
                            fixedSize: const Size(40, 40),
                            padding: const EdgeInsets.all(7),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline),
                        ),
                      ],
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
                    managers:
                        _managersByOrganisation[organisation.organizationId] ??
                        const [],
                    managerError: _managerErrors[organisation.organizationId],
                    avatarColor:
                        _avatarColors[organisations.indexOf(organisation) %
                            _avatarColors.length],
                    onManage: () => _openAdmin(context, organisation),
                    onRemove:
                        !_isRemoving &&
                            !_isCreating &&
                            _renamingOrganisationId == null
                        ? () => _removeOrganisation(organisation)
                        : null,
                    isRemoving:
                        _isSubmittingRemoval &&
                        _removingOrganisationId == organisation.organizationId,
                    onRename: _renamingOrganisationId == null && !_isRemoving
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
                onPressed: () {},
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
    this.onRemove,
    this.isRemoving = false,
    this.managers = const [],
    this.managerError,
  });

  final int organizationId;
  final bool isManager;
  final String name;
  final int members;
  final List<({int userId, String name})> managers;
  final String? managerError;
  final Color avatarColor;
  final VoidCallback onManage;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;
  final bool isRemoving;
  final void Function(int organisationId, String organisationName) onOpenTeams;

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
        onTap: () => onOpenTeams(organizationId, name),
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
                      tooltip: 'Remove organisation',
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
                                semanticsLabel: 'Removing organisation',
                              ),
                            )
                          : const Icon(Icons.remove_circle_outline),
                    ),
                  GestureDetector(
                    // Consume taps across the disabled button's entire bounds.
                    behavior: HitTestBehavior.opaque,
                    onTap: isManager ? null : () {},
                    excludeFromSemantics: true,
                    child: TextButton(
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isManager ? null : () {},
                    excludeFromSemantics: true,
                    child: TextButton(
                      onPressed: isManager ? () {} : null,
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
