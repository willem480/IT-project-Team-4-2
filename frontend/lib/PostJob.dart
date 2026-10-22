import 'package:flutter/material.dart';
import 'package:ticketing_app/SuccessPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';


class PostJob extends StatefulWidget {
  final int currentUserId;
  const PostJob({
    super.key,
    required this.currentUserId});
  // This widget is the root of your application.
  @override
  State<PostJob> createState() => _PostJobPageState();
}


class _PostJobPageState extends State<PostJob> {
  String? selectedCompany;
  String? description = "No Description";
  String userName= "Loading";
  String userEmail = "";

  final TextEditingController titleController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController payController = TextEditingController();
  final TextEditingController assigndateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> fetchUserData() async {
    final url = Uri.parse(ApiConfig.getUser(widget.currentUserId));
    final response = await http.post(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        userName = jsonData['name'] ?? 'User';
      });
    }
  }

  @override
  void initState(){
    super.initState();
    fetchUserData();
  }


  @override
  void dispose(){
    titleController.dispose();
    addressController.dispose();
    payController.dispose();
    assigndateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
  Future<void> submitTicketData() async {


    if (payController.text.trim().isEmpty || int.tryParse(payController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Money can't be empty and it has to be a valid number！"), backgroundColor: Colors.red),
      );
      return;
    }

    if (titleController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete this ticket！"), backgroundColor: Colors.red),
      );
      return;
    }

    final url = Uri.parse(ApiConfig.createTicket);
    Map<String, dynamic> requestData = {
      'posterId': widget.currentUserId,
      "title": titleController.text,
      "location": addressController.text, 
      "pay": int.tryParse(payController.text),
      "company": selectedCompany ?? "Unknown",
      "description": descriptionController.text,
      "dateCompleted": assigndateController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData), 
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("ticket created successfully！");
   
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) =>  SuccessPage(currentUserId: widget.currentUserId,)),
        );
      } else {
        print("submit error ${response.statusCode}");
        print("feedback detail from backend : ${response.body}");
      }
    } catch (e) {
      print("network request error: $e");
    }


  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Hello, $userName', style: TextStyle(color:Colors.black)),
      ),
      body: SafeArea(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Post a job', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 45),
            

            //name
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Job title',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black, width: 1.0)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0)
                ),
              ),
            ),
            SizedBox(height: 32.0),


            //Address
              const Text(
              'Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
          

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                hintText: 'Write your address including postcode',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black, width: 1.0)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0)
                ),
              ),
            ),

            SizedBox(height: 32.0),
            

            //Amount of money
    
            const Text(
              'Amount of Money',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            
  
            TextField(
              controller: payController,
              decoration: InputDecoration(
                hintText: 'Fill your expect money',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black, width: 1.0)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0)
                ),
              ),
            ),

            SizedBox(height: 32.0),

            
            //description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Write your description to the ticket',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black, width: 1.0)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0)
                ),
              ),
            ),

            SizedBox(height: 100.0),

          ],
 
          
        ),
        )
      ),


      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: 200,
          height: 56,
        
          child: FloatingActionButton(
            onPressed: () {submitTicketData();},
            backgroundColor: Colors.blue,
            shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            tooltip: 'Submit',
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
          ),
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );  
  }
}