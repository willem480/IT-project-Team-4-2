import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/models/ticket_comment.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'config.dart';
import 'Profile.dart';

class AcceptedJobDetail extends StatefulWidget {
  final int userId;
  const AcceptedJobDetail({
    super.key,
    required this.ticket,
    required this.userId,
  });

  final TicketModel ticket;

  @override
  State<AcceptedJobDetail> createState() => _AcceptedJobDetailState();
}

class _AcceptedJobDetailState extends State<AcceptedJobDetail> {
  bool isDetailTab = true;
  bool _isCompleting = false;
  bool _isDeallocating = false;

  bool get _isBusy => _isCompleting || _isDeallocating;
  List<ticketComment> commentList = [];
  final TextEditingController commentController = TextEditingController();

  bool get _isClosed =>
      (widget.ticket.status ?? '').toUpperCase().replaceAll(
        RegExp(r'[\s_-]+'),
        '',
      ) ==
      'CLOSED';

  Future<void> _deleteComment(int commentId) async {
    final url = Uri.parse(ApiConfig.deleteComment(widget.userId, commentId));

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        fetchComment();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete, status: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      print(" Delete comment error: $e");
    }
  }

  Future<void> fetchComment() async {
    if (widget.ticket.idTicket == null) return;
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/ticketComment/getTicketComments?ticketId=${widget.ticket.idTicket!}&operatorId=${widget.userId}",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);
        List<ticketComment> tempList = [];

        if (decodedData is List) {
          tempList = decodedData
              .map((model) => ticketComment.fromJson(model))
              .toList();
        } else if (decodedData is Map<String, dynamic>) {
          tempList.add(ticketComment.fromJson(decodedData));
        }
        if (!mounted) return;
        setState(() {
          commentList = tempList;
        });
      }
    } catch (e) {
      print("fail to get a comment: $e");
    }
  }

  Future<void> postNewComment() async {
    if (widget.ticket.idTicket == null || commentController.text.trim().isEmpty) {
      return;
    }

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/ticketComment/postComment?userId=${widget.userId}&ticketId=${widget.ticket.idTicket!}&comment=${commentController.text}",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        commentController.clear();
        fetchComment();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment sent successfully！")),
        );
      }
    } catch (e) {
      print("comment send error: $e");
    }
  }

  Future<void> _completeTicket() async {
    final ticketId = widget.ticket.idTicket;
    if (_isBusy || _isClosed || ticketId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          'Are you sure you want to mark this ticket as completed? This can not be undo and will close ticket',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _isBusy || _isClosed) return;
    setState(() => _isCompleting = true);

    // The backend mapping contains a literal space. Uri encodes the path safely.
    final url = Uri.parse(ApiConfig.completeTicket(ticketId));
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Complete ticket request failed');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to complete this job. Please try again.'),
        ),
      );
      setState(() => _isCompleting = false);
    }
  }

  Future<void> _deallocateTicket() async {
    final ticketId = widget.ticket.idTicket;
    if (_isBusy || _isClosed || ticketId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('Are you sure to deallocate this ticket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('yes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _isBusy) return;
    setState(() => _isDeallocating = true);

    final url =
        Uri.parse(ApiConfig.deallocateTicket(ticketId, widget.userId));
    try {
      final response = await http
          .post(url)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Deallocate ticket request failed');
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to deallocate this ticket. Please try again.'),
        ),
      );
      setState(() => _isDeallocating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchComment();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Job detail page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(100, 100, 100, 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //intro
                  Container(
                    height: 300,
                    width: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.ticket.title ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.ticket.organizationName ?? '',
                          style: TextStyle(fontSize: 18),
                        ),
                        if (widget.ticket.datePosted != null)
                          Text(
                            "Posted on: ${widget.ticket.datePosted.toString().length >= 10 ? widget.ticket.datePosted.toString().substring(0, 10) : widget.ticket.datePosted}",
                            style: TextStyle(fontSize: 16),
                          ),
                        const Spacer(),
                        if (widget.ticket.pay != null)
                          Text(
                            '\$ ${widget.ticket.pay}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  //button
                  Row(
                    children: [
                      _buildTabButton('details', isDetailTab, () {
                        setState(() => isDetailTab = true);
                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('comment', !isDetailTab, () {
                        setState(() => isDetailTab = false);
                      }),
                    ],
                  ),
                  SizedBox(height: 16),

                  isDetailTab
                      ? _buildDetailsSection(context)
                      : _buildCommentsSection(),
                ],
              ),
            ),
          ),

          Text('', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 412),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: _isClosed ? 'Completed' : 'Mark as Complete',
                  color: Colors.lightGreen,
                  isLoading: _isCompleting,
                  onPressed: _completeTicket,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Deallocate',
                  color: Colors.red,
                  isLoading: _isDeallocating,
                  onPressed: _deallocateTicket,
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      height: 56,
      child: FloatingActionButton(
        heroTag: label,
        onPressed: _isBusy || _isClosed || widget.ticket.idTicket == null
            ? null
            : onPressed,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Keep the description layout consistent with FindAJobDetailUser.
  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          widget.ticket.description ?? '',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        commentList.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    "No comments yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Column(
                children: commentList.map((comment) {
                  bool isMe = comment.ownedByCurUser;
                  String initial = comment.userName.isNotEmpty
                      ? comment.userName.substring(0, 1).toUpperCase()
                      : 'U';
                  String dateStr = comment.date.toString();
                  String displayDate = dateStr.length >= 10
                      ? dateStr.substring(0, 10)
                      : dateStr;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Profile(userId: comment.posterId),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade300,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 4.0,
                                  left: 4.0,
                                  right: 4.0,
                                ),
                                child: Text(
                                  '${comment.userName} (ID: ${comment.posterId}) • $displayDate',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                              Builder(
                                builder: (BuildContext bubbleContext) {
                                  return GestureDetector(
                                    onDoubleTap: () async {
                                      if (!isMe) return;

                                      final RenderBox button =
                                          bubbleContext.findRenderObject()
                                              as RenderBox;
                                      final RenderBox overlay =
                                          Navigator.of(context).overlay!.context
                                                  .findRenderObject()
                                              as RenderBox;

                                      final RelativeRect position =
                                          RelativeRect.fromRect(
                                            Rect.fromPoints(
                                              button.localToGlobal(
                                                button.size.bottomLeft(
                                                  Offset.zero,
                                                ),
                                                ancestor: overlay,
                                              ),
                                              button.localToGlobal(
                                                button.size.bottomRight(
                                                  Offset.zero,
                                                ),
                                                ancestor: overlay,
                                              ),
                                            ),
                                            Offset.zero & overlay.size,
                                          );

                                      final String? choice =
                                          await showMenu<String>(
                                            context: context,
                                            position: position,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            items: const [
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Delete Comment',
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );

                                      if (choice == 'delete' && mounted) {
                                        _deleteComment(comment.idticketComment);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.blueAccent
                                            : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isMe
                                              ? const Radius.circular(16)
                                              : const Radius.circular(4),
                                          bottomRight: isMe
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                        border: isMe
                                            ? null
                                            : Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                      ),
                                      child: Text(
                                        comment.content,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        if (isMe) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                onSubmitted: (value) {
                  postNewComment();
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: postNewComment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method for the pill-shaped toggle buttons
  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade800 : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
