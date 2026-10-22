import 'package:flutter/material.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/models/ticket_comment.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/OrganizationSelection.dart';
import 'package:ticketing_app/Profile.dart';
import 'package:ticketing_app/TeamSelectionForTeamDelegatePage.dart';


class FindAJobDetailUser extends StatefulWidget {
  final String title;
  final String company;
  final String price;
  final String description;
  final int ticketId;
  final String date;
  final int currentUserId;
  final bool isManager;
  final int? managerOrgId;
  

  const FindAJobDetailUser({
    super.key,
    required this.title,
    required this.company,
    required this.price,
    required this.description,
    required this.ticketId,
    required this.date,
    required this.currentUserId,
    required this.isManager,
    required this.managerOrgId,
    });

  @override
  State<FindAJobDetailUser> createState() => _FindAJobDetailUserPage();
  
}

class _FindAJobDetailUserPage extends State<FindAJobDetailUser> {
  bool is_Detail_Tab = true;
  List<ticketComment> commentList = [];
  TextEditingController commentController = TextEditingController();

  Future<void> _deleteComment(int commentId) async {

    final url = Uri.parse("http://127.0.0.1:8080/ticketComment/deleteComment?operatorId=${widget.currentUserId}&ticketCommentId=$commentId");

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {

        fetchComment();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comment deleted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete, status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print(" Delete comment error: $e");
    }
  }
  Future<void> fetchComment() async {
    final url = Uri.parse("http://127.0.0.1:8080/ticketComment/getTicketComments?ticketId=${widget.ticketId}&operatorId=${widget.currentUserId}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}), //
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
      print("fail to get a comment: $e");
    }
  }

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
          const SnackBar(content: Text("Comment sent successfully！")),
        );
      }
    } catch (e) {
      print("comment send error: $e");
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
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(

        title: Text('Job detail page', style: TextStyle(fontWeight: FontWeight.bold),),

      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24 ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //intro
                  Container(
                    height: 250,
                    width: double.infinity,
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
        
                          Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)), 
                          const SizedBox(height: 12),
                          Text(widget.company,style: TextStyle(fontSize: 18),),
                          Text("Posted on: ${widget.date.length >= 10 ? widget.date.substring(0,10) : widget.date}", style: TextStyle(fontSize: 16)),
                          const Spacer(), 
                          Text('\$ ${widget.price}', style: const TextStyle(fontWeight:FontWeight.bold, fontSize: 30)),
                        
                            
                          
                          
                        ],
                    )
                  ),
                  const SizedBox(height:20),

                  //button
                  Row(
                    children: [
                      _buildTabButton('details', is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = true);

                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('comment', !is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = false);
                      })
                    ],
                  ),
                  SizedBox(height: 16),

                  is_Detail_Tab ? _buildDetailsSection(context) : _buildCommentsSection(), 


                  

                ],
              ),


          )),
          
          Text(
            '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(
                width: widget.isManager ? 160 : 200,
                height: 56,
                child: FloatingActionButton(
                  heroTag: "btn_accept", //
                  onPressed: () async {

                    final url = Uri.parse("http://127.0.0.1:8080/ticketAssignment/delegateJobIndividual?ticketId=${widget.ticketId}&assigneeId=${widget.currentUserId}");

                    try {
                      final response = await http.post(
                        url,
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({}),
                      );


                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("job accept！")),
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Find a job', currentUserId: widget.currentUserId)),
                              (Route<dynamic> route) => false,
                        );
                      }
                    } catch (e) {
                      print("network job error: $e");
                    }
                  },
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                )
            ),

            if (widget.isManager) ...[
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                height: 56,
                child: Builder(
                    builder: (BuildContext buttonContext) {
                      return FloatingActionButton(
                        heroTag: "btn_delegate",
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        child: const Text('Delegate', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                          final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;


                          final RelativeRect position = RelativeRect.fromRect(
                            Rect.fromPoints(
                              button.localToGlobal(const Offset(0, -100), ancestor: overlay),
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
                                value: 'individual',
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text('Delegate to Individual', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'team',
                                child: Row(
                                  children: [
                                    Icon(Icons.group, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Delegate to Team', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          );

                          if (choice == 'individual') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrganizationSelectionPage(
                                  ticketId: widget.ticketId,
                                  currentUserId: widget.currentUserId,
                                  isForTeamDelegate: false, //personalseletion line
                                ),
                              ),
                            );
                          } else if (choice == 'team') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrganizationSelectionPage(
                                  ticketId: widget.ticketId,
                                  currentUserId: widget.currentUserId,
                                  isForTeamDelegate: true, // teamselection line
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }
                ),
              ),
            ],


          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }

  // The Details View (Description + Map)
  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
        const SizedBox(height: 8),
        Text(widget.description, style: TextStyle(fontSize: 20, color: Colors.black54)),
        const SizedBox(height: 20),
        // Placeholder for Map Integration

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
          child: Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey))),
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

                                //if user right click delete
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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