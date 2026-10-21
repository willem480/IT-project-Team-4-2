import 'package:flutter/material.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/models/ticket_comment.dart';
import 'dart:convert';
import 'package:ticketing_app/Profile.dart';
import 'package:http/http.dart' as http;

class PostAJobDetailUser extends StatefulWidget {
  final String title;
  final String company;
  final String price;
  final String description;
  final int ticketId;
  final String date;
  final int currentUserId;
  final bool isReadOnly;
  const PostAJobDetailUser({
    super.key,
    required this.title,
    required this.company,
    required this.price,
    required this.description,
    required this.ticketId,
    required this.date,
    required this.currentUserId,
    this.isReadOnly = false,
  });

  @override
  State<PostAJobDetailUser> createState() => _PostAJobDetailUserPage();
}

class _PostAJobDetailUserPage extends State<PostAJobDetailUser> {
  bool is_Detail_Tab = true;

  List<ticketComment> commentList = [];
  TextEditingController commentController = TextEditingController();

  // 获取评论
  Future<void> fetchComment() async {
    final url = Uri.parse("http://127.0.0.1:8080/ticketComment/getTicketComments?ticketId=${widget.ticketId}&operatorId=${widget.currentUserId}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if(response.statusCode == 200){
        var decodedData= json.decode(response.body);
        List<ticketComment> tempList = [];

        if(decodedData is List){
          tempList = decodedData.map((model) => ticketComment.fromJson(model)).toList();
        }
        else if (decodedData is Map<String, dynamic>){
          tempList.add(ticketComment.fromJson(decodedData));
        }
        setState(() {
          commentList = tempList;
        });
      }
    } catch(e) {
      print("💥 fail to get a comment: $e");
    }
  }

  // 发送评论
  Future<void> postNewComment() async {
    if (commentController.text.trim().isEmpty) return;

    final url = Uri.parse("http://127.0.0.1:8080/ticketComment/postComment?userId=${widget.currentUserId}&ticketId=${widget.ticketId}&comment=${commentController.text}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        commentController.clear();
        fetchComment();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Comment sent successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send, status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("💥 发送评论异常: $e");
    }
  }

  // 删除评论
  Future<void> _deleteComment(int commentId) async {
    final url = Uri.parse("http://127.0.0.1:8080/ticketComment/deleteComment?operatorId=${widget.currentUserId}&ticketCommentId=$commentId");

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        fetchComment(); // 删除成功后刷新列表
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Comment deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to delete, status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("💥 Delete comment error: $e");
    }
  }

  @override
  void initState(){
    super.initState();
    fetchComment();
  }

  @override
  void dispose(){
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Job detail page', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部工单卡片
                    Container(
                        height: 300,
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                            const SizedBox(height: 12),
                            Text(widget.company, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 16),
                            Text("Posted on: ${widget.date}", style: const TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text('\$ ${widget.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Colors.green)),
                          ],
                        )
                    ),
                    const SizedBox(height: 20),

                    // 按钮区
                    Row(
                      children: [
                        _buildTabButton('Details', is_Detail_Tab, (){
                          setState(() => is_Detail_Tab = true);
                        }),
                        const SizedBox(width: 12),
                        _buildTabButton('Comments', !is_Detail_Tab, (){
                          setState(() => is_Detail_Tab = false);
                        })
                      ],
                    ),
                    const SizedBox(height: 16),

                    is_Detail_Tab ? _buildDetailsSection() : _buildCommentsSection(),
                  ],
                ),
              )),
        ],
      ),

      floatingActionButton: widget.isReadOnly ? null : Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
            width: 200,
            height: 56,
            child: FloatingActionButton(
              onPressed: () async {
                final url = Uri.parse("http://127.0.0.1:8080/ticket/complete ticket?ticketId=${widget.ticketId}");
                try{
                  final response = await http.get(url);
                  if (response.statusCode == 200){
                    print("job has been completed successfully");
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Find a job', currentUserId: widget.currentUserId)),
                            (Route<dynamic> route) => false
                    );
                  } else {
                    print("fail complet");
                  }
                } catch(e){
                  print("network request error");
                }
              },
              backgroundColor: Colors.lightGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: const Text('Completed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            )
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(widget.description, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 80), // 留出底部按钮的空间
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),

        commentList.isEmpty
            ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: Text("No comments yet. Start the conversation!", style: TextStyle(color: Colors.grey))),
        )
            : Column(
          children: commentList.map((comment) {
            bool isMe = comment.ownedByCurUser;
            String initial = comment.userName.isNotEmpty ? comment.userName.substring(0, 1).toUpperCase() : 'U';
            String dateStr = comment.date.toString();
            String displayDate = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[

                    GestureDetector(
                      onTap: () {

                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Profile(userId: comment.posterId))
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(initial, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, left: 4.0, right: 4.0),
                          child: Text(
                            '${comment.userName} (ID: ${comment.posterId}) • $displayDate',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),


                        Builder(
                          builder: (BuildContext bubbleContext) {
                            return GestureDetector(
                              onDoubleTap: () async {
                                if (!isMe) return;

                                final RenderBox button = bubbleContext.findRenderObject() as RenderBox;
                                final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );

                                final String? choice = await showMenu<String>(
                                  context: context,
                                  position: position,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  items: const [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.redAccent),
                                          SizedBox(width: 8),
                                          Text('Delete Comment', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                if (choice == 'delete') {
                                  _deleteComment(comment.idticketComment);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blueAccent : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                  border: isMe ? null : Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  comment.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? Colors.white : Colors.black87,
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
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
      if(!widget.isReadOnly)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
        const SizedBox(height: 80), //
      ],
    );
  }

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