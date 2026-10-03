
import 'package:ticketing_app/FindAJobDetailUser.dart';
import 'package:ticketing_app/Profile.dart';
import 'package:ticketing_app/SignIn.dart';
import 'AcceptJob.dart';
import 'PostJob.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/models/user_profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color(0xFFF9FAFB)),
      ),
      home: const SignInPage(title: 'Find a job'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TicketModel> openTickets = [];
  String userName = 'Loading...';
  void fetchOpenTickets() async {
      
      final url = Uri.parse('http://127.0.0.1:4523/m1/8806835-8598944-default/ticket/getOpenTickets');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({}), 
        );

        if (response.statusCode == 200) {
          
          List<TicketModel> parsedTickets = ticketFromJson(response.body);
          
          
          setState(() {
            
            openTickets = parsedTickets;

          });
          print("✅ 首页工单获取成功，共 ${openTickets.length} 条");
        }
      } catch (e) {
        print("💥 首页工单获取失败: $e");
      }
    }

    void fetchUserData() async{
      final url = Uri.parse('http://127.0.0.1:4523/m1/8806835-8598944-default/profilePage/getUser');

      //Post
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
      
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        UserProfile myUser = UserProfile.fromJson(jsonData);
        setState(() {
          userName = myUser.name ?? 'User';
        });
      }

    }
    void initState(){
      super.initState();
      fetchOpenTickets();
      fetchUserData();
    }

  @override
  Widget build(BuildContext context) {
    

 
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

        actions:[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                print('profile open');
                Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()),);

              },
              child: CircleAvatar(
                radius: 18.0,
                backgroundColor: Colors.blue,
                child: Text('Alan'),
              ),

            )

          )
        ]
        
      ),
      //body
      body: SafeArea(
       
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //left align

            children: [
              //fixed area, this is upper area excluding 
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Good morning, Alan', style: TextStyle(fontSize: 20)), 
              ),

              //Search area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    //hint area
                    hintText: 'Search tickets, assignees, or locations...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), 

                    prefixIcon: const Icon(Icons.search, color: Colors.grey),

                    //filled background color
                    filled: true,
                    fillColor: Colors.white,

                    //search frame by default
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0), 
      
                    ),

                    //color after i click it
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(color: Colors.blue, width: 1.0),
                    ),

                    //up vertical padding
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),

                  ),
                ),
              ),

              Padding(
                padding:  EdgeInsets.all(16.0),
                child: Row(// from left to right
                  children: [
                    PopupMenuButton<String>(
                      onSelected:  (String value){
                        print("User selected: $value");
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'up',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 16),
                              SizedBox(width: 8),
                              Text('Pay: Low to High'),
                            ]
                          )
                        ),
                        const PopupMenuItem<String>(
                          value: 'down',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 16),
                              SizedBox(width: 8),
                              Text('Pay: High to Low'),
                            ]
                          )
                        )
                      ],

                      //visual button
                      
                    ),
                    
                  ]
                )
              ),

              //scrol area
              Expanded(
                child: SingleChildScrollView(
                  //sizebox to stretch width
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment:CrossAxisAlignment.center,
                      children: openTickets.isEmpty 
                      ? [ const Padding(padding: EdgeInsets.all(20), child:Text("No Jobs yet"))]
                      : openTickets.map((ticket) {
                        return _buildJobCard(
                          context,
                          ticket.title ?? "No title",
                          ticket.location ?? ticket.posterName ?? "Unknown Location",
                          ticket.pay?.toString() ?? '0'
                      );
                    }).toList(),
                  ),
                  //jobs
                ),
              ),
              ),
            ],
          ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => PostJob()),);},
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        tooltip: 'Post a Job',
        child: const Icon(Icons.add, color:  Colors.white),
      ),

      //lock at center
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      //bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () {}, 
              icon: Icon(Icons.search, color: Colors.black,), 
              label: Text('Find a Job', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
  
            const SizedBox(width: 60),
            TextButton.icon(
              onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => AcceptJobPage()),);}, 
              icon: Icon(Icons.check_circle_outlined, color: Colors.black,), 
              label: Text('Accept a Job', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ),


    );
  }

  Widget _buildJobCard(BuildContext context, String title, String companyName, String price){
      return InkWell(
        onTap: (){
          print('tap job ticket in find job page');
          Navigator.push(context, MaterialPageRoute(builder: (context) => FindAJobDetailUser(title: title, company: companyName, price: price,)),);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 500,
          height: 250,
          margin: const EdgeInsets.all(10),
          padding: EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ]
          ),           
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 80),
                // alignment: Alignment.topLeft,
              Text(
                companyName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              
              SizedBox(height: 5),  

              Text(
                '\$$price',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              //more item
            ],
          )
        )
      );
  }
}
