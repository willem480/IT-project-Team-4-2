import 'package:flutter/material.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/models/ticket_comment.dart';
import 'dart:convert';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/models/ticket_comment.dart';



class FindAJobDetailUser extends StatefulWidget {
  final String title;
  final String company;
  final String price;
  final String description;
  final int ticketId;
  final String date;
  

  const FindAJobDetailUser({
    super.key,
    required this.title,
    required this.company,
    required this.price,
    required this.description,
    required this.ticketId,
    required this.date,
    });

  @override
  State<FindAJobDetailUser> createState() => _FindAJobDetailUserPage();
  
}

class _FindAJobDetailUserPage extends State<FindAJobDetailUser> {
  bool is_Detail_Tab = true;

  List<ticketComment> commentList = [];
  TextEditingController commentController = TextEditingController();

//Getting comment
  Future<void> fetchComment() async{
    final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/ticketComment/getTicketComments");

    try{
      final response = await http.post(url, 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ticketIdticket":widget.ticketId,
        }));
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
    }
    catch(e){
      print("fail to get a comment");
    }
  }

  Future<void> postNewComment()async{
    if(commentController.text.trim().isEmpty) return; //if it is empty then no send
    final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/ticketComment/postComment");
    try{
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ticketIdticket":widget.ticketId,
          "userIduser": 1,
          "content": commentController.text,
        })
      );

      if (response.statusCode == 200){
        print("success");
        commentController.clear();
        fetchComment();
      }
    }
    catch(e){
      print("fail to post a comment");
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
        
                          Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)), 
                          const SizedBox(height: 12),
                          Text(widget.company,style: TextStyle(fontSize: 18),),
                          Text("Posted on: ${widget.date}", style: TextStyle(fontSize: 16)),
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
        padding: EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: 200,
          height: 56,
          child: FloatingActionButton(
          onPressed: () async{
            final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/ticketAssignment/delegateJobIndividual");
            
            try{
              final response = await http.post(
                url,
                headers:{"Content-Type": "application/json"},
                body: jsonEncode({
                  "ticketId": widget.ticketId,
                  "assigneeId": 1, 
                  "teamId": null
                }));
                if (response.statusCode == 200){
                  print("job has been accepted successfully");
                  Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Find a job')), 
                    (Route<dynamic> route) => false);
                }
                else{print("fail accept");}

            }
            catch(e){
              print("network request error");
            }
          },
          backgroundColor: Colors.lightGreen,
          shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Text('Accept', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
          )
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
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(widget.description, style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        // Placeholder for Map Integration

      ],
    );
  }


  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            child: const Text("Post comment", style: TextStyle(color: Colors.white)),
          )
        ),
        const SizedBox(height: 20),
        commentList.isEmpty ? 
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No comment yet", style: TextStyle(color: Colors.grey)),
           ) 
          ////////////////////////////////////////////////////////////
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
                          Text('User ID: ${comment.userIduser}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${comment.date.year}-${comment.date.month}-${comment.date.day}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(comment.content, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),

              
            ),
            /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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