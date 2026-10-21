import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/models/ticket_comment.dart';
import 'package:ticketing_app/models/ticket_model.dart';

class AcceptedJobDetail extends StatefulWidget {
  final int userId;
  const AcceptedJobDetail({super.key, required this.ticket, required this.userId});

  final TicketModel ticket;

  @override
  State<AcceptedJobDetail> createState() => _AcceptedJobDetailState();
}

class _AcceptedJobDetailState extends State<AcceptedJobDetail> {
  bool isDetailTab = true;
  bool _isCompleting = false;
  List<ticketComment> commentList = [];
  final TextEditingController commentController = TextEditingController();

  bool get _isClosed =>
      (widget.ticket.status ?? '').toUpperCase().replaceAll(
        RegExp(r'[\s_-]+'),
        '',
      ) ==
      'CLOSED';

  Future<void> fetchComment() async {
    if (widget.ticket.idTicket == null) return;
    final url = Uri.parse(
      'http://127.0.0.1:8080/ticketComment/getTicketComments',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ticketIdticket': widget.ticket.idTicket}),
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<ticketComment> comments = [];
        if (decodedData is List) {
          comments = decodedData
              .map((model) => ticketComment.fromJson(model))
              .toList();
        } else if (decodedData is Map<String, dynamic>) {
          comments.add(ticketComment.fromJson(decodedData));
        }
        if (!mounted) return;
        setState(() => commentList = comments);
      }
    } catch (_) {
      print('fail to get a comment');
    }
  }

  Future<void> postNewComment() async {
    if (widget.ticket.idTicket == null ||
        commentController.text.trim().isEmpty) {
      return;
    }
    final url = Uri.parse(
      'http://127.0.0.1:8080/ticketComment/postComment',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ticketIdticket': widget.ticket.idTicket,
          'userIduser': widget.userId,
          'content': commentController.text,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        commentController.clear();
        await fetchComment();
      }
    } catch (_) {
      print('fail to post a comment');
    }
  }

  Future<void> _completeTicket() async {
    final ticketId = widget.ticket.idTicket;
    if (_isCompleting || _isClosed || ticketId == null) return;
    setState(() => _isCompleting = true);

    // The backend mapping contains a literal space. Uri encodes the path safely.
    final url = Uri.parse('http://127.0.0.1:8080/')
        .replace(
          path: '/ticket/complete ticket',
          queryParameters: {'ticketId': '$ticketId'},
        );
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
              padding: const EdgeInsets.all(100),
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
                            "Posted on: ${widget.ticket.datePosted.
                            toString().length >= 10 ?widget.ticket.datePosted.
                            toString().substring(0,10) : widget.ticket.datePosted}",
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
        padding: EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: 200,
          height: 56,
          child: FloatingActionButton(
            onPressed:
                _isCompleting || _isClosed || widget.ticket.idTicket == null
                ? null
                : _completeTicket,
            backgroundColor: Colors.lightGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: _isCompleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isClosed ? 'Completed' : 'Mark as Complete',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: postNewComment,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              "Post comment",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        commentList.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No comment yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: commentList.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User ID: ${comment.posterId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${comment.date.year}-${comment.date.month}-${comment.date.day}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
