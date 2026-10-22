import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MemberSearchDialog extends StatefulWidget {
  const MemberSearchDialog({
    super.key,
    required this.actorUserId,
    required this.teamId,
    required this.onMemberAdded,
  });

  final int actorUserId;
  final int teamId;
  final Future<void> Function() onMemberAdded;

  @override
  State<MemberSearchDialog> createState() => _MemberSearchDialogState();
}

class _MemberSearchDialogState extends State<MemberSearchDialog> {
  bool _isLoading = false;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _searchQuery = '';
  final Set<int> _addingUserIds = {};
  final Set<int> _addedUserIds = {};
  final Set<int> _teamMemberUserIds = {};
  List<({int idUser, String name, String email})>? _users;
  String? _errorMessage;
  String? _additionMessage;
  bool _additionFailed = false;

  static const _avatarColors = [
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
  ];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    super.dispose();
  }

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

      final membersData = jsonDecode(utf8.decode(responses[1].bodyBytes));
      if (membersData is! Map<String, dynamic> ||
          membersData['members'] is! List ||
          membersData['teamId'] != widget.teamId ||
          membersData['canManage'] != true) {
        throw const FormatException('Expected a list of team members');
      }
      final memberIds = (membersData['members'] as List).map((member) {
        if (member is! Map<String, dynamic> || member['userId'] is! int) {
          throw const FormatException('Invalid team member response');
        }
        return member['userId'] as int;
      }).toSet()..addAll(_addedUserIds);

      final decoded = jsonDecode(utf8.decode(responses[0].bodyBytes));
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
                user.name.toLowerCase().contains(search) ||
                user.email.toLowerCase().contains(search),
          )
          .toList();
      // Keep the backend's name-first order and mark existing members.
      setState(() {
        _users = users;
        _teamMemberUserIds
          ..clear()
          ..addAll(memberIds);
      });
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
    if (_addingUserIds.isNotEmpty || _teamMemberUserIds.contains(user.idUser)) {
      return;
    }
    setState(() {
      _addingUserIds.add(user.idUser);
      _additionMessage = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8080/team/addTeamMember'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actorUserId': widget.actorUserId,
              'teamId': widget.teamId,
              'userId': user.idUser,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode != 201) {
        throw FormatException(_addError(response));
      }
      setState(() {
        _addedUserIds.add(user.idUser);
        _teamMemberUserIds.add(user.idUser);
        _additionMessage = '${user.name} added to the team.';
        _additionFailed = false;
      });
      await widget.onMemberAdded();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _additionMessage = error is FormatException
            ? error.message
            : 'Unable to add member. Please try again.';
        _additionFailed = true;
      });
    } finally {
      if (mounted) setState(() => _addingUserIds.remove(user.idUser));
    }
  }

  String _addError(http.Response response) {
    if (response.statusCode == 403) {
      return 'Only an organisation manager can add team members.';
    }
    if (response.statusCode == 404) {
      return 'The team or user no longer exists.';
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'detail', 'error']) {
          final message = decoded[key];
          if (message is String && message.trim().isNotEmpty) return message;
        }
      }
    } on FormatException {
      // Fall back to the HTTP status for non-JSON responses.
    }
    return 'Unable to add member (HTTP ${response.statusCode}). Please try again.';
  }

  Widget _buildUserCard(
    ({int idUser, String name, String email}) user,
    int index,
  ) {
    final name = user.name.trim();
    final isAdding = _addingUserIds.contains(user.idUser);
    final isMember = _teamMemberUserIds.contains(user.idUser);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _avatarColors[index % _avatarColors.length],
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: isMember ? 'Already a team member' : 'Add to this team',
            child: TextButton(
              onPressed: _addingUserIds.isNotEmpty || isMember
                  ? null
                  : () => _addMember(user),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF065F46),
                backgroundColor: const Color(0xFFD1FAE5),
                disabledForegroundColor: const Color(0xFF6B7280),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
              ),
              child: isAdding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isMember ? 'Added' : 'Add'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _searchUser(_searchQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_users == null || _users!.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'Search for a user by name or email.'
              : 'No users found.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _users!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildUserCard(_users![index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdding = _addingUserIds.isNotEmpty;
    return PopScope(
      canPop: !isAdding,
      child: AlertDialog(
        title: const Text('Add team members'),
        content: SizedBox(
          width: 520,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                autofocus: true,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchUser,
                decoration: InputDecoration(
                  hintText: 'Search name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResults()),
              if (_additionMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _additionMessage!,
                  style: TextStyle(
                    color: _additionFailed
                        ? Colors.red
                        : const Color(0xFF065F46),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isAdding ? null : () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
