import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Profile.dart';

class AdminSearchPage extends StatefulWidget {
  const AdminSearchPage({
    super.key,
    required this.userName,
    required this.actorUserId,
    required this.teamId,
  });

  final String userName;
  final int actorUserId;
  final int teamId;

  @override
  State<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {
  String _userName = '';

  String get _displayName => _userName.isEmpty ? 'Loading...' : _userName;

  Future<void> _fetchUserName() async {
    // Reuse the current user's name when a parent page has already loaded it.
    if (_userName.isNotEmpty) return;
    final userId = widget.actorUserId;
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
      if (!mounted || widget.actorUserId != userId || _userName.isNotEmpty) {
        return;
      }
      setState(() => _userName = name.isEmpty ? 'User' : name);
    } catch (error) {
      debugPrint('Failed to load greeting name for user $userId: $error');
      if (!mounted || widget.actorUserId != userId || _userName.isNotEmpty) {
        return;
      }
      setState(() => _userName = 'User');
    }
  }

  @override
  void initState() {
    super.initState();
    _userName = widget.userName.trim();
    _fetchUserName();
  }

  @override
  void didUpdateWidget(covariant AdminSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actorUserId != widget.actorUserId ||
        oldWidget.userName != widget.userName) {
      _userName = widget.userName.trim();
      _fetchUserName();
    }
    if (oldWidget.teamId != widget.teamId ||
        oldWidget.actorUserId != widget.actorUserId) {
      _addedUserIds.clear();
      _addingUserIds.clear();
      _searchUser(_searchQuery);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    super.dispose();
  }

  bool _isLoading = false;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _searchQuery = '';
  final Set<int> _addingUserIds = {};
  final Set<int> _addedUserIds = {};
  List<({int idUser, String name, String email})>? _users;
  String? _errorMessage;

  static const _avatarColors = [
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
  ];

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    // Invalidate earlier responses as soon as the input changes.
    _searchRequestId++;
    _searchQuery = query.trim();
    setState(() {
      _isLoading = _searchQuery.isNotEmpty;
      _users = null;
      _errorMessage = null;
    });
    if (_searchQuery.isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchUser(query);
    });
  }

  Future<void> _searchUser(String query) async {
    _searchDebounce?.cancel();
    final keyword = query.trim();
    _searchQuery = keyword;
    final requestId = ++_searchRequestId;

    setState(() {
      _isLoading = keyword.isNotEmpty;
      _users = null;
      _errorMessage = null;
    });
    if (keyword.isEmpty) return;

    try {
      final url = Uri.parse('http://127.0.0.1:8080/user/getUsersByEmail')
          .replace(queryParameters: {'keyword': keyword});
      final membersUrl = Uri.parse('http://127.0.0.1:8080/team/getTeamMembers')
          .replace(
            queryParameters: {
              'teamId': '${widget.teamId}',
              'viewerUserId': '${widget.actorUserId}',
            },
          );
      final responses = await Future.wait([
        http.post(url, headers: {'Content-Type': 'application/json'}),
        http.get(membersUrl),
      ]).timeout(const Duration(seconds: 30));
      if (!mounted || requestId != _searchRequestId) return;
      if (responses.any((response) => response.statusCode != 200)) {
        throw Exception('Failed to load users or team members');
      }

      final membersData = jsonDecode(responses[1].body);
      if (membersData is! Map<String, dynamic> ||
          membersData['members'] is! List) {
        throw const FormatException('Expected a list of team members');
      }
      final memberIds = (membersData['members'] as List).map((member) {
        if (member is! Map<String, dynamic> || member['userId'] is! int) {
          throw const FormatException('Invalid team member response');
        }
        return member['userId'] as int;
      }).toSet()..addAll(_addedUserIds);

      final decoded = jsonDecode(responses[0].body);
      if (decoded is! List) {
        throw const FormatException('Expected a list of users');
      }
      final search = keyword.toLowerCase();
      final users = decoded
          .map((user) {
            if (user is! Map<String, dynamic> ||
                user['idUser'] is! int ||
                user['name'] is! String ||
                user['email'] is! String) {
              throw const FormatException('Invalid user response');
            }
            return (
              idUser: user['idUser'] as int,
              name: user['name'] as String,
              email: user['email'] as String,
            );
          })
          .where(
            (user) =>
                !memberIds.contains(user.idUser) &&
                (user.name.toLowerCase().contains(search) ||
                    user.email.toLowerCase().contains(search)),
          )
          .toList();
      // Keep the backend's name-first order among matching non-members.
      setState(() => _users = users);
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _errorMessage =
            'Failed to load users or team members. Please try again.';
      });
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addMember(
    ({int idUser, String name, String email}) user,
  ) async {
    if (_addingUserIds.contains(user.idUser) ||
        _addedUserIds.contains(user.idUser)) {
      return;
    }
    final teamId = widget.teamId;
    final actorUserId = widget.actorUserId;

    setState(() => _addingUserIds.add(user.idUser));
    try {
      final url = Uri.parse('http://127.0.0.1:8080/team/addTeamMember');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': actorUserId,
              'teamId': teamId,
              'userId': user.idUser,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 201) {
        throw Exception('Failed to add user');
      }
      if (!mounted ||
          widget.teamId != teamId ||
          widget.actorUserId != actorUserId) {
        return;
      }
      setState(() {
        _addedUserIds.add(user.idUser);
        _users?.removeWhere((candidate) => candidate.idUser == user.idUser);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User added to team.')));
    } catch (_) {
      if (!mounted ||
          widget.teamId != teamId ||
          widget.actorUserId != actorUserId) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add user. Please try again.')),
      );
    } finally {
      if (mounted &&
          widget.teamId == teamId &&
          widget.actorUserId == actorUserId) {
        setState(() => _addingUserIds.remove(user.idUser));
      }
    }
  }

  Widget _buildUserCard(
    ({int idUser, String name, String email}) user,
    int index,
  ) {
    final name = user.name.trim();
    final isAdding = _addingUserIds.contains(user.idUser);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _avatarColors[index % _avatarColors.length],
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
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
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isAdding ? null : () => _addMember(user),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF065F46),
              backgroundColor: const Color(0xFFD1FAE5),
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: isAdding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BackButton(
                    color: Colors.black,
                    onPressed: () => Navigator.pop(context),
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
                        builder: (context) =>
                            Profile(userId: widget.actorUserId),
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
                'Search User',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _searchUser,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_errorMessage != null || _users?.isEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    _errorMessage ?? 'No users found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              else if (_users != null) ...[
                const SizedBox(height: 16),
                for (var index = 0; index < _users!.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _buildUserCard(_users![index], index),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
